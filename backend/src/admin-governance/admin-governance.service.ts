import { BadRequestException, Injectable } from '@nestjs/common';
import type { CommercialSetting, Customer, User } from '@prisma/client';
import type { ShieldPrincipal } from '../auth/auth.types';
import { getAppEnv } from '../config/app-env';
import { PlatformPrintService } from '../platform-capabilities/platform-print.service';
import { PlatformRealtimeService } from '../platform-capabilities/platform-realtime.service';
import { PlatformReportService } from '../platform-capabilities/platform-report.service';
import { PricingService } from '../pricing/pricing.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { TimelineService } from '../timeline/timeline.service';
import { WalletService } from '../wallet/wallet.service';

export type AdminGovernanceWorkspaceQuery = {
  search?: string | null;
  status?: string | null;
  tab?: string | null;
  page: number;
  pageSize: number;
};

export type AdminGovernanceSettingsMutation = {
  valueType: string;
  valueText?: string | null;
  valueNumber?: number | null;
  valueBoolean?: boolean | null;
  status: string;
};

type WorkspaceMetric = {
  label: string;
  value: string;
  note: string;
};

type WorkspacePanel = {
  title: string;
  subtitle: string;
  type: 'list' | 'details' | 'table';
  items?: Array<Record<string, string>>;
  details?: Array<Record<string, string>>;
  columns?: Array<Record<string, string>>;
  rows?: Array<Record<string, string>>;
  emptyState?: {
    title: string;
    description: string;
    actionLabel: string;
  };
};

@Injectable()
export class AdminGovernanceService {
  private readonly env = getAppEnv();

  constructor(
    private readonly prisma: PrismaService,
    private readonly pricingService: PricingService,
    private readonly platformPrintService: PlatformPrintService,
    private readonly platformRealtimeService: PlatformRealtimeService,
    private readonly platformReportService: PlatformReportService,
    private readonly timelineService: TimelineService,
    private readonly redisService: RedisService,
    private readonly walletService: WalletService,
  ) {}

  async getSettingsWorkspace(
    query: AdminGovernanceWorkspaceQuery,
    principal?: ShieldPrincipal,
  ) {
    const search = query.search?.toLowerCase() ?? '';
    const status = query.status?.trim().toUpperCase();
    const [settings, sessions, loginHistory, pushTokens] = await Promise.all([
      this.prisma.commercialSetting.findMany({
        where: {
          ...(status != null && status.length > 0 ? { status } : {}),
          ...(search.length > 0
            ? {
                OR: [
                  { code: { contains: search, mode: 'insensitive' } },
                  { valueText: { contains: search, mode: 'insensitive' } },
                ],
              }
            : {}),
        },
        orderBy: [{ updatedAt: 'desc' }, { code: 'asc' }],
        take: Math.min(query.pageSize, 50),
        skip: (query.page - 1) * query.pageSize,
      }),
      this.prisma.authSession.findMany({
        orderBy: [{ revokedAt: 'asc' }, { lastSeenAt: 'desc' }],
        take: 8,
        include: {
          authDevice: {
            select: {
              deviceName: true,
              platform: true,
              browser: true,
              isTrusted: true,
            },
          },
        },
      }),
      this.prisma.loginHistory.findMany({
        orderBy: { createdAt: 'desc' },
        take: 8,
      }),
      this.prisma.devicePushToken.findMany({
        orderBy: { updatedAt: 'desc' },
        take: 8,
      }),
    ]);

    const activeSessions = sessions.filter(
      (session) => session.revokedAt == null,
    );
    const supportedAreas = [
      ...this.buildSettingsCategoryBuckets(settings),
      {
        title: 'Sessions & security',
        subtitle: `${activeSessions.length} live sessions and ${loginHistory.length} recent auth events`,
        meta: 'Backed by auth_sessions and login_history',
        status: 'Live',
      },
      {
        title: 'Push delivery',
        subtitle: `${pushTokens.filter((token) => token.isActive).length} active tokens across registered devices`,
        meta: 'Backed by device_push_tokens',
        status: 'Live',
      },
      {
        title: 'Branding, storage, and third-party integrations',
        subtitle: 'No dedicated governance table exists for these domains yet',
        meta: 'Unavailable until backend contracts are introduced',
        status: 'Unavailable',
      },
    ];

    return this.buildWorkspacePayload(
      'settings',
      {
        eyebrow: 'Admin / Backend settings',
        title: 'Settings',
        description:
          'Commercial configuration is live from the backend, while unsupported setting domains render explicit unavailable states until their contracts exist.',
        primaryActionLabel:
          settings.length > 0
            ? 'Review commercial rules'
            : 'Seed commercial settings',
        secondaryActionLabel: 'Inspect session policy',
      },
      {
        searchHint: 'Search setting codes, values, and configuration domains',
        tabs: ['Commercial', 'Security', 'Delivery', 'Unavailable'],
        filters: ['ACTIVE', 'INACTIVE', 'Live', 'Unavailable'],
      },
      [
        this.metric(
          'Stored settings',
          settings.length,
          'commercial_settings rows',
        ),
        this.metric(
          'Active sessions',
          activeSessions.length,
          'Current internal auth sessions',
        ),
        this.metric(
          'Push devices',
          pushTokens.filter((token) => token.isActive).length,
          'Active device tokens',
        ),
      ],
      {
        left: {
          title: 'Configuration areas',
          subtitle: 'Only backend-owned domains appear as live.',
          type: 'list',
          items: supportedAreas,
        },
        center: {
          title: 'Live settings records',
          subtitle: 'Editable values from commercial_settings.',
          type: 'table',
          columns: [
            { key: 'code', label: 'Code' },
            { key: 'value', label: 'Value' },
            { key: 'type', label: 'Type' },
            { key: 'status', label: 'Status' },
            { key: 'updatedAt', label: 'Updated' },
          ],
          rows: settings.map((setting) => ({
            code: setting.code,
            value: this.describeCommercialSetting(setting),
            type: setting.valueType ?? 'UNKNOWN',
            status: setting.status ?? 'ACTIVE',
            updatedAt: this.formatDateTime(setting.updatedAt),
          })),
          emptyState: {
            title: 'No backend settings matched this filter',
            description:
              'The settings workspace is live, but the requested search and status combination returned no commercial settings rows.',
            actionLabel: 'Adjust the search or seed commercial settings.',
          },
        },
        right: {
          title: 'Security and delivery context',
          subtitle:
            'Auth session and device posture around the settings surface.',
          type: 'details',
          details: [
            {
              label: 'Latest login',
              value:
                loginHistory.length > 0
                  ? this.formatDateTime(loginHistory[0].createdAt)
                  : 'No login history recorded',
            },
            {
              label: 'Revoked sessions',
              value: `${sessions.filter((session) => session.revokedAt != null).length}`,
            },
            {
              label: 'Trusted devices',
              value: `${sessions.filter((session) => session.authDevice?.isTrusted === true).length}`,
            },
            {
              label: 'Workspace permission',
              value: 'settings.view',
            },
            {
              label: 'Last operator',
              value: principal?.email?.trim().length
                ? principal.email.trim()
                : principal?.userId?.trim() || 'Unknown operator',
            },
          ],
        },
      },
    );
  }

  async updateSetting(
    code: string,
    mutation: AdminGovernanceSettingsMutation,
    principal?: ShieldPrincipal,
  ) {
    const normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.length === 0) {
      throw new BadRequestException('Setting code is required.');
    }
    this.validateSettingMutation(mutation);

    const previous = await this.prisma.commercialSetting.findUnique({
      where: { code: normalizedCode },
    });
    const updated = await this.pricingService.upsertCommercialSetting({
      code: normalizedCode,
      value_type: mutation.valueType.trim().toUpperCase(),
      value_text: mutation.valueText ?? null,
      value_number: mutation.valueNumber ?? null,
      value_boolean: mutation.valueBoolean ?? null,
      status: mutation.status.trim().toUpperCase(),
    });

    await this.timelineService.recordAuditLog({
      userId: principal?.userId?.trim()
        ? BigInt(principal.userId.trim())
        : undefined,
      action: 'ADMIN_SETTING_UPDATED',
      entityType: 'commercial_settings',
      entityId: updated.id,
      oldData: previous ?? undefined,
      newData: updated,
    });

    return {
      code: updated.code,
      value: this.describeCommercialSetting(updated),
      valueType: updated.valueType,
      status: updated.status,
      updatedAt: updated.updatedAt.toISOString(),
    };
  }

  async getPlatformWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const [
      database,
      redis,
      sessionCount,
      auditCount,
      pricingAuditCount,
      notifications,
    ] = await Promise.all([
      this.getDatabaseHealth(),
      this.redisService.ping(),
      this.prisma.authSession.count({ where: { revokedAt: null } }),
      this.prisma.auditLog.count(),
      this.prisma.pricingRuleAudit.count(),
      this.prisma.notification.count(),
    ]);

    const reports = this.platformReportService.listMetadata('provider');
    const printTemplates = this.platformPrintService.listTemplates();
    const realtime = {
      endpoint: '/platform/realtime/stream',
      workspace: 'provider',
    };
    const capabilityRows = this.filterRowsBySearch(
      reports.reports.map((report) => ({
        scope: report.workspace?.toString() ?? 'shared',
        capability:
          report.title?.toString() ?? report.id?.toString() ?? 'Report',
        status: 'Configured',
        format: Array.isArray(report.availableFormats)
          ? report.availableFormats.join(', ')
          : 'PDF',
      })),
      query.search,
    );

    return this.buildWorkspacePayload(
      'platform',
      {
        eyebrow: 'Admin / Runtime health',
        title: 'Platform',
        description:
          'This workspace exposes live backend health, integration readiness, and shared engine surfaces instead of fake percentages.',
        primaryActionLabel: 'Inspect report engine',
        secondaryActionLabel: 'Review integrations',
      },
      {
        searchHint:
          'Search platform capabilities, integrations, and engine surfaces',
        tabs: ['Runtime', 'Reports', 'Print', 'Realtime'],
        filters: ['Healthy', 'Configured', 'Unavailable'],
      },
      [
        this.metric(
          'Open sessions',
          sessionCount,
          'Current active auth sessions',
        ),
        this.metric('Audit rows', auditCount, 'Stored audit_logs rows'),
        this.metric('Notifications', notifications, 'Stored notification rows'),
        this.metric(
          'Print templates',
          printTemplates.length,
          'Shared print registry',
        ),
      ],
      {
        left: {
          title: 'Runtime health',
          subtitle: 'Direct checks against the live backend services.',
          type: 'details',
          details: [
            { label: 'API environment', value: this.env.nodeEnv },
            { label: 'Database', value: database.message },
            { label: 'Redis', value: redis.message },
            {
              label: 'Realtime stream',
              value: '${realtime.workspace} via ${realtime.endpoint}',
            },
            { label: 'Pricing audits', value: `${pricingAuditCount}` },
          ],
        },
        center: {
          title: 'Shared platform surfaces',
          subtitle:
            'Report, print, and runtime capabilities registered in the backend.',
          type: 'table',
          columns: [
            { key: 'scope', label: 'Scope' },
            { key: 'capability', label: 'Capability' },
            { key: 'status', label: 'Status' },
            { key: 'format', label: 'Formats' },
          ],
          rows: capabilityRows,
          emptyState: {
            title: 'No platform capability matched this search',
            description:
              'The platform workspace is live, but the current search does not match any registered reports or platform capabilities.',
            actionLabel:
              'Clear the search to view the shared capability registry.',
          },
        },
        right: {
          title: 'Integration readiness',
          subtitle: 'Environment-backed service availability only.',
          type: 'list',
          items: this.buildIntegrationDetails(redis, notifications),
        },
      },
    );
  }

  async getDashboardWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const today = new Date();
    const startOfToday = new Date(today);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(today);
    endOfToday.setHours(23, 59, 59, 999);

    const [
      totalCustomers,
      activeCustomers,
      pendingApprovals,
      todaysAppointments,
      pendingDocuments,
      recentAuditLogs,
      recentNotifications,
      recentBusinesses,
    ] = await Promise.all([
      this.prisma.customer.count({ where: { deletedAt: null } }),
      this.prisma.customer.count({
        where: { deletedAt: null, status: 'ACTIVE' },
      }),
      this.prisma.customer.count({
        where: {
          deletedAt: null,
          status: { in: ['PENDING', 'INCOMPLETE', 'REJECTED'] },
        },
      }),
      this.prisma.appointment.count({
        where: {
          appointmentDate: { gte: startOfToday, lte: endOfToday },
        },
      }),
      this.prisma.document.count({
        where: {
          NOT: { status: { in: ['APPROVED', 'VALIDATED'] } },
        },
      }),
      this.prisma.auditLog.findMany({
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 8,
        include: {
          user: {
            select: {
              email: true,
              firstName: true,
              lastName: true,
            },
          },
        },
      }),
      this.prisma.notification.findMany({
        orderBy: [{ sentAt: 'desc' }, { id: 'desc' }],
        take: 8,
        include: {
          customer: {
            select: {
              customerCode: true,
              firstName: true,
              lastName: true,
            },
          },
        },
      }),
      this.prisma.business.findMany({
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        take: 8,
      }),
    ]);

    return this.buildWorkspacePayload(
      'dashboard',
      {
        eyebrow: 'Admin / Command center',
        title: 'Dashboard',
        description:
          'This dashboard is backend-owned and assembled from live operational records instead of static portal-section placeholders.',
        primaryActionLabel: 'Review approvals',
        secondaryActionLabel: 'Inspect activity',
      },
      {
        searchHint: 'Search alert labels, activity, and branch summaries',
        tabs: ['Overview', 'Alerts', 'Activity', 'Branches'],
        filters: ['Live', 'Review', 'Healthy'],
      },
      [
        this.metric('Customers', totalCustomers, 'Live customer rows'),
        this.metric('Active customers', activeCustomers, 'Currently ACTIVE'),
        this.metric('Pending approvals', pendingApprovals, 'Needs admin action'),
        this.metric('Today appointments', todaysAppointments, 'Scheduled today'),
      ],
      {
        left: {
          title: 'Operational alerts',
          subtitle: 'Priority workloads the admin team should triage first.',
          type: 'list',
          items: this.filterRowsBySearch(
            [
              {
                title: 'Pending approvals',
                subtitle: `${pendingApprovals} customer records are awaiting approval or completion.`,
                meta: 'customers + memberships onboarding',
                status: pendingApprovals > 0 ? 'Review' : 'Healthy',
              },
              {
                title: 'Pending documents',
                subtitle: `${pendingDocuments} uploaded documents still require validation.`,
                meta: 'documents + verification queues',
                status: pendingDocuments > 0 ? 'Review' : 'Healthy',
              },
              {
                title: 'Today workload',
                subtitle: `${todaysAppointments} appointments are scheduled for today.`,
                meta: 'appointments calendar',
                status: todaysAppointments > 0 ? 'Live' : 'Quiet',
              },
            ],
            query.search,
          ),
        },
        center: {
          title: 'Recent activity',
          subtitle: 'Latest audit evidence recorded by the backend.',
          type: 'table',
          columns: [
            { key: 'time', label: 'Time' },
            { key: 'action', label: 'Action' },
            { key: 'entity', label: 'Entity' },
            { key: 'actor', label: 'Actor' },
          ],
          rows: this.filterRowsBySearch(
            recentAuditLogs.map((log) => ({
              time: this.formatDateTime(log.createdAt),
              action: log.action ?? 'Unknown action',
              entity: log.entityType ?? 'Unknown entity',
              actor: this.resolveActorLabel(log.user),
            })),
            query.search,
          ),
          emptyState: {
            title: 'No activity matched this search',
            description:
              'The dashboard workspace is live, but the current search returned no recent audit activity.',
            actionLabel: 'Clear the search to review current audit evidence.',
          },
        },
        right: {
          title: 'Branch and delivery pulse',
          subtitle: 'Recent business entities and outbound notifications.',
          type: 'details',
          details: [
            {
              label: 'Businesses',
              value: `${recentBusinesses.length} recent entities in scope`,
            },
            {
              label: 'Latest business',
              value:
                recentBusinesses.length === 0
                  ? 'No business records available'
                  : recentBusinesses[0].name,
            },
            {
              label: 'Recent notifications',
              value: `${recentNotifications.length} delivery rows loaded`,
            },
            {
              label: 'Latest notification target',
              value:
                recentNotifications.length === 0
                  ? 'No notifications recorded'
                  : this.resolveCustomerLabel(recentNotifications[0].customer),
            },
          ],
        },
      },
    );
  }

  async getCustomersWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const today = new Date();
    const startOfToday = new Date(today);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(today);
    endOfToday.setHours(23, 59, 59, 999);
    const search = query.search?.trim();
    const status = query.status?.trim().toUpperCase();

    const [customers, totalCustomers, activeCustomers, pendingDocuments, todaysVisits] =
      await Promise.all([
        this.prisma.customer.findMany({
          where: {
            deletedAt: null,
            ...(status != null && status.length > 0 ? { status } : {}),
            ...(search == null || search.length === 0
              ? {}
              : {
                  OR: [
                    { firstName: { contains: search, mode: 'insensitive' } },
                    { lastName: { contains: search, mode: 'insensitive' } },
                    { customerCode: { contains: search, mode: 'insensitive' } },
                    { mobile: { contains: search } },
                  ],
                }),
          },
          include: {
            membership: {
              include: {
                membershipType: true,
              },
            },
            wallet: true,
            shieldCard: {
              include: {
                issuedBusiness: true,
              },
            },
          },
          orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
          take: Math.min(query.pageSize, 25),
          skip: (query.page - 1) * query.pageSize,
        }),
        this.prisma.customer.count({ where: { deletedAt: null } }),
        this.prisma.customer.count({
          where: { deletedAt: null, status: 'ACTIVE' },
        }),
        this.prisma.document.count({
          where: {
            customer: { deletedAt: null },
            NOT: { status: { in: ['APPROVED', 'VALIDATED'] } },
          },
        }),
        this.prisma.appointment.count({
          where: {
            appointmentDate: { gte: startOfToday, lte: endOfToday },
            customer: { deletedAt: null },
          },
        }),
      ]);

    const selectedCustomer = customers.length === 0 ? null : customers[0];
    const selectedCustomerId = selectedCustomer?.id;
    const [
      selectedTimeline,
      selectedDocuments,
      selectedAppointments,
      selectedTasks,
      selectedActivities,
      selectedPurchases,
      selectedReferralEvents,
      selectedWalletSummary,
    ] = selectedCustomerId == null
      ? [[], [], [], [], [], [], [], null]
      : await Promise.all([
          this.timelineService.getPatientTimeline(selectedCustomerId),
          this.prisma.document.findMany({
            where: { customerId: selectedCustomerId },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 12,
          }),
          this.prisma.appointment.findMany({
            where: { customerId: selectedCustomerId },
            include: { provider: true },
            orderBy: [{ appointmentDate: 'desc' }, { id: 'desc' }],
            take: 12,
          }),
          this.prisma.crmTask.findMany({
            where: { customerId: selectedCustomerId },
            orderBy: [{ dueDate: 'asc' }, { id: 'desc' }],
            take: 12,
          }),
          this.prisma.crmActivity.findMany({
            where: { customerId: selectedCustomerId },
            include: { createdByUser: true },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 12,
          }),
          this.prisma.purchase.findMany({
            where: { customerId: selectedCustomerId },
            include: { provider: true },
            orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
            take: 12,
          }),
          this.prisma.referralRewardEvent.findMany({
            where: {
              OR: [
                { referrerCustomerId: selectedCustomerId },
                { referredCustomerId: selectedCustomerId },
              ],
            },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 12,
          }),
          selectedCustomer!.wallet == null
            ? Promise.resolve(null)
            : this.walletService.getWalletSummary(selectedCustomer!.wallet!.id),
        ]);

    return this.buildWorkspacePayload(
      'customers',
      {
        eyebrow: 'Admin / Customer operations',
        title: 'Customers',
        description:
          'Customer identity, membership, wallet, visits, documents, CRM follow-up, and timeline data now flow through one backend workspace contract.',
        primaryActionLabel: 'Create customer',
        secondaryActionLabel: 'Review approvals',
      },
      {
        searchHint:
          'Search customers by name, customer code, or mobile number',
        tabs: [
          'Overview',
          'Timeline',
          'CRM',
          'Documents',
          'Visits',
          'Wallet',
          'Membership',
        ],
        filters: ['ACTIVE', 'PENDING', 'SUSPENDED', 'REJECTED'],
      },
      [
        this.metric('Customers', totalCustomers, 'Live customer rows'),
        this.metric('Active', activeCustomers, 'ACTIVE lifecycle state'),
        this.metric('Pending docs', pendingDocuments, 'Needs verification'),
        this.metric('Today visits', todaysVisits, 'Scheduled for today'),
      ],
      {
        left: {
          title: 'Customer list',
          subtitle: 'Search, status filtering, and latest lifecycle changes.',
          type: 'list',
          items: customers.map((customer) => {
            const membershipName =
              customer.membership?.membershipType?.name ??
              customer.membership?.membershipNumber ??
              'No membership';
            const branch = customer.shieldCard?.issuedBusiness?.name?.trim();
            return {
              title: this.resolveCustomerLabel(customer),
              subtitle: `${customer.customerCode?.trim().length ? customer.customerCode.trim() : 'No code'} • ${membershipName}`,
              meta: `${customer.mobile}${branch != null && branch.length > 0 ? ` • ${branch}` : ''}`,
              status: customer.status ?? 'PENDING',
            };
          }),
          emptyState: {
            title: 'No customers matched this query',
            description:
              'The customer workspace is live, but the current search and status filter returned no customer rows.',
            actionLabel: 'Clear filters or create a new customer record.',
          },
        },
        center: {
          title: 'Selected customer workspace',
          subtitle:
            selectedCustomer == null
              ? 'Select a customer from the live list to inspect identity, wallet, CRM, and documents.'
              : 'Backend-owned summary for ${this.resolveCustomerLabel(selectedCustomer)}.',
          type: 'details',
          details:
            selectedCustomer == null
              ? []
              : [
                  {
                    label: 'Customer',
                    value: this.resolveCustomerLabel(selectedCustomer),
                  },
                  {
                    label: 'Code',
                    value: selectedCustomer.customerCode ?? 'Unavailable',
                  },
                  {
                    label: 'Mobile',
                    value: selectedCustomer.mobile,
                  },
                  {
                    label: 'Membership',
                    value:
                      selectedCustomer.membership?.membershipType?.name ??
                      selectedCustomer.membership?.membershipNumber ??
                      'No active membership',
                  },
                  {
                    label: 'Wallet',
                    value:
                      selectedWalletSummary == null
                        ? 'Wallet unavailable'
                        : 'Cash ₹${Number(selectedWalletSummary.cashWallet.available ?? 0).toFixed(2)} • Rewards ${selectedWalletSummary.rewardPoints.available ?? 0}',
                  },
                  {
                    label: 'Documents',
                    value: `${selectedDocuments.length} recent rows`,
                  },
                  {
                    label: 'Appointments',
                    value: `${selectedAppointments.length} recent rows`,
                  },
                  {
                    label: 'CRM tasks',
                    value: `${selectedTasks.length} open and recent rows`,
                  },
                  {
                    label: 'Activities',
                    value: `${selectedActivities.length} CRM activity rows`,
                  },
                  {
                    label: 'Purchases',
                    value: `${selectedPurchases.length} medicine or billing rows`,
                  },
                  {
                    label: 'Referral events',
                    value: `${selectedReferralEvents.length} related reward rows`,
                  },
                ],
          emptyState: {
            title: 'No customer selected',
            description:
              'The customers workspace needs at least one live customer record before the master-detail surface can render a selected customer.',
            actionLabel: 'Create a customer or clear restrictive filters.',
          },
        },
        right: {
          title: 'Customer timeline',
          subtitle:
            selectedCustomer == null
              ? 'Live timeline rows appear after a customer is selected.'
              : 'Timeline events from the shared timeline service.',
          type: 'table',
          columns: [
            { key: 'time', label: 'Time' },
            { key: 'event', label: 'Event' },
            { key: 'status', label: 'Status' },
          ],
          rows: (selectedTimeline as Array<Record<string, unknown>>)
            .slice(0, 12)
            .map((event) => ({
              time: `${event['timestamp'] ?? ''}`,
              event: `${event['displayTitle'] ?? 'Timeline event'}`,
              status: `${event['status'] ?? 'RECORDED'}`,
            })),
          emptyState: {
            title: 'No timeline events available',
            description:
              'The selected customer does not yet have timeline evidence recorded through the shared timeline service.',
            actionLabel: 'Open a customer with visits, documents, or wallet history.',
          },
        },
      },
    );
  }

  async getAuditWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const search = query.search?.trim();
    const entityFilter = query.status?.trim();
    const [auditLogs, totalCount, recentCount, loginHistory] =
      await Promise.all([
        this.prisma.auditLog.findMany({
          where: {
            ...(search != null && search.length > 0
              ? {
                  OR: [
                    { action: { contains: search, mode: 'insensitive' } },
                    { entityType: { contains: search, mode: 'insensitive' } },
                    {
                      user: {
                        email: { contains: search, mode: 'insensitive' },
                      },
                    },
                  ],
                }
              : {}),
            ...(entityFilter != null && entityFilter.length > 0
              ? {
                  entityType: {
                    equals: entityFilter,
                    mode: 'insensitive',
                  },
                }
              : {}),
          },
          include: {
            user: {
              select: {
                email: true,
                firstName: true,
                lastName: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: Math.min(query.pageSize, 50),
          skip: (query.page - 1) * query.pageSize,
        }),
        this.prisma.auditLog.count(),
        this.prisma.auditLog.count({
          where: {
            createdAt: {
              gte: new Date(Date.now() - 24 * 60 * 60 * 1000),
            },
          },
        }),
        this.prisma.loginHistory.findMany({
          orderBy: { createdAt: 'desc' },
          take: 8,
        }),
      ]);

    const entityTypes = new Set(
      auditLogs.map((log) => (log.entityType ?? '').trim()).filter(Boolean),
    );

    return this.buildWorkspacePayload(
      'audit',
      {
        eyebrow: 'Admin / Audit evidence',
        title: 'Audit Logs',
        description:
          'This workspace is backed by audit_logs and login_history, with search and filter support against real recorded actions only.',
        primaryActionLabel: 'Export current view',
        secondaryActionLabel: 'Inspect auth events',
      },
      {
        searchHint: 'Search actions, entities, and actors',
        tabs: ['Actions', 'Auth events', 'Recent'],
        filters: [
          'commercial_settings',
          'notifications',
          'appointments',
          'auth',
        ],
      },
      [
        this.metric('Total rows', totalCount, 'Stored audit_logs records'),
        this.metric(
          'Last 24h',
          recentCount,
          'Audit events recorded in the last day',
        ),
        this.metric(
          'Entity types',
          entityTypes.size,
          'Distinct entities in current result',
        ),
      ],
      {
        left: {
          title: 'Audit coverage',
          subtitle: 'Current result composition from recorded rows.',
          type: 'details',
          details: [
            { label: 'Current page', value: `${query.page}` },
            { label: 'Page size', value: `${query.pageSize}` },
            {
              label: 'Current entity filter',
              value: entityFilter?.length ? entityFilter : 'All entities',
            },
            {
              label: 'Search',
              value: search?.length ? search : 'No search applied',
            },
          ],
        },
        center: {
          title: 'Recorded actions',
          subtitle: 'Rows directly from audit_logs.',
          type: 'table',
          columns: [
            { key: 'timestamp', label: 'Timestamp' },
            { key: 'action', label: 'Action' },
            { key: 'entity', label: 'Entity' },
            { key: 'actor', label: 'Actor' },
            { key: 'entityId', label: 'Entity ID' },
          ],
          rows: auditLogs.map((log) => ({
            timestamp: this.formatDateTime(log.createdAt),
            action: log.action ?? 'Unknown action',
            entity: log.entityType ?? 'Unknown entity',
            actor: this.resolveActorLabel(log.user),
            entityId: log.entityId?.toString() ?? 'N/A',
          })),
          emptyState: {
            title: 'No audit rows matched this query',
            description:
              'The audit module is live, but this search or entity filter did not match any recorded audit events.',
            actionLabel:
              'Clear the filters or trigger actions that emit audit events.',
          },
        },
        right: {
          title: 'Recent authentication events',
          subtitle: 'Live login_history evidence beside action logs.',
          type: 'list',
          items: loginHistory.map((entry) => ({
            title: entry.ownerType,
            subtitle: entry.status,
            meta: this.formatDateTime(entry.createdAt),
            status: entry.loginMethod ?? 'UNKNOWN',
          })),
        },
      },
    );
  }

  async getNotificationsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const search = query.search?.trim();
    const status = query.status?.trim().toUpperCase();
    const [notifications, notificationCount, unreadCount, deviceTokens] =
      await Promise.all([
        this.prisma.notification.findMany({
          where: {
            ...(search != null && search.length > 0
              ? {
                  OR: [
                    { title: { contains: search, mode: 'insensitive' } },
                    { message: { contains: search, mode: 'insensitive' } },
                  ],
                }
              : {}),
            ...(status != null && status.length > 0 ? { status } : {}),
          },
          include: {
            customer: {
              select: {
                customerCode: true,
                firstName: true,
                lastName: true,
              },
            },
          },
          orderBy: { sentAt: 'desc' },
          take: Math.min(query.pageSize, 50),
          skip: (query.page - 1) * query.pageSize,
        }),
        this.prisma.notification.count(),
        this.prisma.notification.count({
          where: {
            status: { not: 'READ' },
          },
        }),
        this.prisma.devicePushToken.findMany({
          orderBy: { updatedAt: 'desc' },
          take: 50,
        }),
      ]);

    const platformCounts = new Map<string, number>();
    for (const token of deviceTokens) {
      const platform =
        token.platform.trim().length > 0 ? token.platform.trim() : 'UNKNOWN';
      platformCounts.set(platform, (platformCounts.get(platform) ?? 0) + 1);
    }

    return this.buildWorkspacePayload(
      'notifications',
      {
        eyebrow: 'Admin / Notification operations',
        title: 'Notifications',
        description:
          'This workspace is backend-driven from notifications and device_push_tokens, while unsupported template and campaign domains render explicit unavailable states.',
        primaryActionLabel: 'Send in-app alert',
        secondaryActionLabel: 'Review delivery devices',
      },
      {
        searchHint: 'Search titles, messages, and notification status',
        tabs: ['Inbox', 'Devices', 'Unavailable templates'],
        filters: ['UNREAD', 'READ', 'IN_APP'],
      },
      [
        this.metric(
          'Stored notifications',
          notificationCount,
          'Rows in notifications',
        ),
        this.metric(
          'Unread',
          unreadCount,
          'Notifications not yet marked as READ',
        ),
        this.metric(
          'Active devices',
          deviceTokens.filter((token) => token.isActive).length,
          'Active push targets',
        ),
      ],
      {
        left: {
          title: 'Channel and queue posture',
          subtitle: 'Only backend-backed delivery evidence is shown as live.',
          type: 'list',
          items: [
            {
              title: 'In-app notifications',
              subtitle: `${notificationCount} stored messages`,
              meta: 'Backed by notifications',
              status: 'Live',
            },
            {
              title: 'Push device registry',
              subtitle: `${deviceTokens.filter((token) => token.isActive).length} active delivery targets`,
              meta: 'Backed by device_push_tokens',
              status: 'Live',
            },
            {
              title: 'Templates, campaigns, and retries',
              subtitle: 'No dedicated notification governance tables exist yet',
              meta: 'Unavailable until backend contracts are introduced',
              status: 'Unavailable',
            },
          ],
        },
        center: {
          title: 'Stored notifications',
          subtitle: 'Live rows from notifications.',
          type: 'table',
          columns: [
            { key: 'sentAt', label: 'Sent' },
            { key: 'customer', label: 'Customer' },
            { key: 'title', label: 'Title' },
            { key: 'channel', label: 'Channel' },
            { key: 'status', label: 'Status' },
          ],
          rows: notifications.map((notification) => ({
            sentAt: this.formatDateTime(notification.sentAt),
            customer: this.resolveCustomerLabel(notification.customer),
            title: notification.title ?? 'Notification',
            channel: notification.channel ?? 'IN_APP',
            status: notification.status ?? 'UNREAD',
          })),
          emptyState: {
            title: 'No notifications matched this filter',
            description:
              'The notifications workspace is live, but the current search or status filter returned no notification rows.',
            actionLabel: 'Clear the search or adjust the status filter.',
          },
        },
        right: {
          title: 'Registered delivery devices',
          subtitle:
            'Live push-device evidence grouped from device_push_tokens.',
          type: 'list',
          items: Array.from(platformCounts.entries()).map(
            ([platform, count]) => ({
              title: platform,
              subtitle: `${count} registered tokens`,
              meta: 'Platform device registry',
              status: 'Live',
            }),
          ),
          emptyState: {
            title: 'No device tokens registered',
            description:
              'Push delivery infrastructure is present, but no active device tokens are stored in the backend.',
            actionLabel:
              'Register mobile or web devices to populate live delivery targets.',
          },
        },
      },
    );
  }

  private buildWorkspacePayload(
    workspaceId: string,
    header: Record<string, string>,
    toolbar: Record<string, unknown>,
    metrics: WorkspaceMetric[],
    panels: Record<string, WorkspacePanel>,
  ) {
    const defaultViewId = panels.center?.type === 'table' ? 'table' : 'detail';
    return {
      workspaceId,
      generatedAt: new Date().toISOString(),
      header,
      toolbar,
      schema: {
        defaultViewId,
        views: [
          {
            id: defaultViewId,
            type: panels.center?.type === 'table' ? 'table' : 'detail',
            title: header.title ?? workspaceId,
          },
        ],
      },
      metrics: metrics.map((metric) => ({
        label: metric.label,
        value: metric.value,
        note: metric.note,
      })),
      panels: Object.fromEntries(
        Object.entries(panels).map(([key, panel]) => [
          key,
          {
            title: panel.title,
            subtitle: panel.subtitle,
            type: panel.type,
            ...(panel.items != null ? { items: panel.items } : {}),
            ...(panel.details != null ? { details: panel.details } : {}),
            ...(panel.columns != null ? { columns: panel.columns } : {}),
            ...(panel.rows != null ? { rows: panel.rows } : {}),
            ...(panel.emptyState != null
              ? { emptyState: panel.emptyState }
              : {}),
          },
        ]),
      ),
    };
  }

  private metric(label: string, value: number, note: string): WorkspaceMetric {
    return {
      label,
      value: `${value}`,
      note,
    };
  }

  private buildSettingsCategoryBuckets(settings: CommercialSetting[]) {
    const buckets = new Map<string, number>([
      ['Commercial preload and benefits', 0],
      ['Reward and redemption rules', 0],
      ['General commercial toggles', 0],
    ]);

    for (const setting of settings) {
      const code = setting.code.trim().toUpperCase();
      if (code.includes('PRELOAD') || code.includes('BENEFIT')) {
        buckets.set(
          'Commercial preload and benefits',
          (buckets.get('Commercial preload and benefits') ?? 0) + 1,
        );
      } else if (code.includes('REWARD') || code.includes('REDEMPTION')) {
        buckets.set(
          'Reward and redemption rules',
          (buckets.get('Reward and redemption rules') ?? 0) + 1,
        );
      } else {
        buckets.set(
          'General commercial toggles',
          (buckets.get('General commercial toggles') ?? 0) + 1,
        );
      }
    }

    return Array.from(buckets.entries()).map(([title, count]) => ({
      title,
      subtitle: `${count} stored rows`,
      meta: 'Backed by commercial_settings',
      status: count > 0 ? 'Live' : 'Empty',
    }));
  }

  private describeCommercialSetting(setting: CommercialSetting) {
    switch ((setting.valueType ?? '').trim().toUpperCase()) {
      case 'BOOLEAN':
        return setting.valueBoolean == null
          ? 'Unset'
          : setting.valueBoolean
            ? 'Enabled'
            : 'Disabled';
      case 'NUMBER':
        return setting.valueNumber?.toString() ?? 'Unset';
      default:
        return setting.valueText?.trim().length
          ? setting.valueText.trim()
          : 'Unset';
    }
  }

  private validateSettingMutation(mutation: AdminGovernanceSettingsMutation) {
    const type = mutation.valueType.trim().toUpperCase();
    if (!['TEXT', 'NUMBER', 'BOOLEAN'].includes(type)) {
      throw new BadRequestException(
        'value_type must be one of TEXT, NUMBER, or BOOLEAN.',
      );
    }
    if (type === 'NUMBER' && mutation.valueNumber == null) {
      throw new BadRequestException(
        'value_number is required when value_type is NUMBER.',
      );
    }
    if (type === 'BOOLEAN' && mutation.valueBoolean == null) {
      throw new BadRequestException(
        'value_boolean is required when value_type is BOOLEAN.',
      );
    }
    if (type === 'TEXT' && !mutation.valueText?.trim().length) {
      throw new BadRequestException(
        'value_text is required when value_type is TEXT.',
      );
    }
  }

  private async getDatabaseHealth() {
    try {
      await this.prisma.$queryRawUnsafe('SELECT 1');
      return {
        healthy: true,
        message: 'Healthy',
      };
    } catch (error) {
      return {
        healthy: false,
        message:
          error instanceof Error
            ? `Unavailable: ${error.message}`
            : 'Unavailable',
      };
    }
  }

  private buildIntegrationDetails(
    redis: { configured: boolean; healthy: boolean; message: string },
    notificationCount: number,
  ) {
    return [
      {
        title: 'Redis / Valkey',
        subtitle: redis.configured ? redis.message : 'REDIS_URL not configured',
        meta: `Healthy: ${redis.healthy}`,
        status: redis.healthy ? 'Healthy' : 'Unavailable',
      },
      {
        title: 'Cloudflare R2',
        subtitle:
          this.env.r2Bucket.trim().length > 0
            ? this.env.r2Bucket
            : 'Storage credentials missing',
        meta: 'Derived from backend environment',
        status:
          this.env.r2Bucket.trim().length > 0 ? 'Configured' : 'Unavailable',
      },
      {
        title: 'Firebase',
        subtitle:
          this.env.firebaseProjectId.trim().length > 0
            ? this.env.firebaseProjectId
            : 'Firebase project not configured',
        meta: `${notificationCount} stored notifications`,
        status:
          this.env.firebaseProjectId.trim().length > 0
            ? 'Configured'
            : 'Unavailable',
      },
      {
        title: 'SMTP delivery',
        subtitle:
          this.env.smtpHost.trim().length > 0
            ? this.env.smtpHost
            : 'SMTP host not configured',
        meta: 'Derived from backend environment',
        status:
          this.env.smtpHost.trim().length > 0 ? 'Configured' : 'Unavailable',
      },
      {
        title: 'OCR service',
        subtitle: this.env.ocrEnabled
          ? this.env.prescriptionAiUrl
          : 'OCR is disabled by configuration',
        meta: 'Derived from backend environment',
        status: this.env.ocrEnabled ? 'Configured' : 'Unavailable',
      },
    ];
  }

  private filterRowsBySearch(
    rows: Array<Record<string, string>>,
    search?: string | null,
  ) {
    const normalized = search?.trim().toLowerCase();
    if (!normalized) {
      return rows;
    }
    return rows.filter((row) =>
      Object.values(row).some((value) =>
        value.toLowerCase().includes(normalized),
      ),
    );
  }

  private resolveActorLabel(
    user: Pick<User, 'email' | 'firstName' | 'lastName'> | null | undefined,
  ) {
    if (user == null) {
      return 'System';
    }
    const name = [user.firstName, user.lastName]
      .filter((value): value is string => Boolean(value?.trim().length))
      .join(' ')
      .trim();
    if (name.length > 0 && user.email?.trim().length) {
      return `${name} (${user.email.trim()})`;
    }
    if (name.length > 0) {
      return name;
    }
    return user.email?.trim().length ? user.email.trim() : 'System';
  }

  private resolveCustomerLabel(
    customer:
      | Pick<Customer, 'customerCode' | 'firstName' | 'lastName'>
      | null
      | undefined,
  ) {
    if (customer == null) {
      return 'Unassigned';
    }
    const name = [customer.firstName, customer.lastName]
      .filter((value): value is string => Boolean(value?.trim().length))
      .join(' ')
      .trim();
    if (name.length > 0 && customer.customerCode?.trim().length) {
      return `${name} (${customer.customerCode.trim()})`;
    }
    if (name.length > 0) {
      return name;
    }
    return customer.customerCode?.trim().length
      ? customer.customerCode.trim()
      : 'Customer';
  }

  private formatDateTime(value?: Date | null) {
    return value == null ? 'N/A' : value.toISOString();
  }
}
