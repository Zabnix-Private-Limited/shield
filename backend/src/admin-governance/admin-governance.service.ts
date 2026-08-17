import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import type { CommercialSetting, Customer, User } from '@prisma/client';
import type { ShieldPrincipal } from '../auth/auth.types';
import { getAppEnv } from '../config/app-env';
import { CustomerService } from '../customer/customer.service';
import { NotificationService } from '../notification/notification.service';
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
  selectedId?: string | null;
  sortKey?: string | null;
  sortDirection?: 'asc' | 'desc' | null;
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
  selectionKey?: string;
  selectedId?: string;
  selectionEnabled?: boolean;
  sortKey?: string;
  sortDirection?: string;
  pagination?: {
    page: number;
    pageSize: number;
    totalRows: number;
  };
  emptyState?: {
    title: string;
    description: string;
    actionLabel: string;
  };
};

type WorkspaceActionDescriptor = {
  id: string;
  label: string;
  icon: string;
  color: string;
  category: 'primary' | 'secondary' | 'danger';
  permission: string;
  endpoint: string;
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE';
  requiresSelection?: boolean;
  allowBulk?: boolean;
  successMessage?: string;
  confirmation?: {
    title: string;
    body: string;
    confirmText: string;
  };
  dialog?: {
    type: 'FORM' | 'CONFIRM' | 'WIZARD';
    formId?: string;
  };
  refreshAfterSuccess: boolean;
};

type WorkspacePayloadOptions = {
  actions?: WorkspaceActionDescriptor[];
  bulkActions?: WorkspaceActionDescriptor[];
  permissions?: Record<string, boolean>;
  exports?: Array<Record<string, string>>;
  forms?: Array<Record<string, unknown>>;
  commands?: Array<Record<string, unknown>>;
};

@Injectable()
export class AdminGovernanceService {
  private readonly env = getAppEnv();

  constructor(
    private readonly prisma: PrismaService,
    private readonly pricingService: PricingService,
    private readonly customerService: CustomerService,
    private readonly notificationService: NotificationService,
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

  async getCustomerWorkspaceForm(
    formId: string,
    recordId?: string | null,
    principal?: ShieldPrincipal,
  ) {
    const normalizedFormId = formId.trim().toLowerCase();
    if (normalizedFormId !== 'edit') {
      throw new BadRequestException(`Unsupported customer workspace form "${formId}".`);
    }
    this.assertPrincipalPermission(principal, 'customers.update');
    if (!recordId?.trim().length) {
      throw new BadRequestException('record_id is required for customer edit forms.');
    }
    const customer = await this.customerService.findOne(BigInt(recordId.trim()));
    return {
      id: 'edit',
      entity: 'customer',
      title: `Edit ${this.resolveCustomerLabel(customer as any)}`,
      fields: [
        {
          key: 'first_name',
          type: 'text',
          label: 'First name',
          required: true,
          value: customer.firstName ?? '',
        },
        {
          key: 'last_name',
          type: 'text',
          label: 'Last name',
          required: false,
          value: customer.lastName ?? '',
        },
        {
          key: 'mobile',
          type: 'phone',
          label: 'Mobile',
          required: true,
          value: customer.mobile ?? '',
        },
        {
          key: 'email',
          type: 'email',
          label: 'Email',
          required: false,
          value: customer.email ?? '',
        },
        {
          key: 'gender',
          type: 'select',
          label: 'Gender',
          required: false,
          value: customer.gender ?? '',
          options: ['MALE', 'FEMALE', 'OTHER'],
        },
        {
          key: 'dob',
          type: 'date',
          label: 'Date of birth',
          required: false,
          value: customer.dob?.toISOString().split('T')[0] ?? '',
        },
        {
          key: 'address_line1',
          type: 'textarea',
          label: 'Address line 1',
          required: false,
          value: customer.addressLine1 ?? '',
        },
        {
          key: 'city',
          type: 'text',
          label: 'City',
          required: false,
          value: customer.city ?? '',
        },
        {
          key: 'district',
          type: 'text',
          label: 'District',
          required: false,
          value: customer.district ?? '',
        },
        {
          key: 'state',
          type: 'text',
          label: 'State',
          required: false,
          value: customer.state ?? '',
        },
        {
          key: 'pincode',
          type: 'text',
          label: 'Pincode',
          required: false,
          value: customer.pincode ?? '',
        },
        {
          key: 'blood_group',
          type: 'text',
          label: 'Blood group',
          required: false,
          value: customer.bloodGroup ?? '',
        },
      ],
    };
  }

  async executeCustomerWorkspaceAction(
    actionId: string,
    body: Record<string, unknown>,
    principal?: ShieldPrincipal,
  ) {
    const normalizedActionId = actionId.trim().toLowerCase();
    const recordId = this.requireRecordId(body.record_id);
    const userId = this.requirePrincipalUserId(principal);
    switch (normalizedActionId) {
      case 'edit': {
        this.assertPrincipalPermission(principal, 'customers.update');
        const before = await this.customerService.findOne(recordId);
        const updated = await this.customerService.update(recordId, body);
        await this.recordCustomerWorkspaceAudit({
          principal,
          action: 'ADMIN_CUSTOMER_UPDATED',
          entityId: recordId,
          oldData: before as any,
          newData: updated as any,
        });
        await this.notificationService.send({
          customerId: recordId,
          title: 'Profile updated',
          message: 'Your SHIELD customer profile was updated by an administrator.',
        });
        return {
          actionId: normalizedActionId,
          customerId: recordId.toString(),
          status: 'success',
        };
      }
      case 'suspend': {
        this.assertPrincipalPermission(principal, 'customers.approve');
        const before = await this.customerService.findOne(recordId);
        const updated = await this.customerService.suspend(recordId, userId);
        await this.recordCustomerWorkspaceAudit({
          principal,
          action: 'ADMIN_CUSTOMER_SUSPENDED',
          entityId: recordId,
          oldData: before as any,
          newData: updated as any,
        });
        await this.notificationService.send({
          customerId: recordId,
          title: 'Account suspended',
          message: 'Your SHIELD customer account has been suspended by an administrator.',
        });
        return {
          actionId: normalizedActionId,
          customerId: recordId.toString(),
          status: 'success',
        };
      }
      case 'activate': {
        this.assertPrincipalPermission(principal, 'customers.approve');
        const before = await this.customerService.findOne(recordId);
        const updated = await this.customerService.activate(recordId, userId);
        await this.recordCustomerWorkspaceAudit({
          principal,
          action: 'ADMIN_CUSTOMER_ACTIVATED',
          entityId: recordId,
          oldData: before as any,
          newData: updated as any,
        });
        await this.notificationService.send({
          customerId: recordId,
          title: 'Account activated',
          message: 'Your SHIELD customer account is active again.',
        });
        return {
          actionId: normalizedActionId,
          customerId: recordId.toString(),
          status: 'success',
        };
      }
      case 'delete': {
        this.assertPrincipalPermission(principal, 'customers.delete');
        const before = await this.customerService.findOne(recordId);
        const deleted = await this.customerService.softDelete(recordId, userId);
        await this.recordCustomerWorkspaceAudit({
          principal,
          action: 'ADMIN_CUSTOMER_DELETED',
          entityId: recordId,
          oldData: before as any,
          newData: deleted as any,
        });
        return {
          actionId: normalizedActionId,
          customerId: recordId.toString(),
          status: 'success',
        };
      }
      case 'generate-card': {
        this.assertPrincipalPermission(principal, 'customers.approve');
        const card = await this.customerService.generateCard(recordId, userId);
        await this.recordCustomerWorkspaceAudit({
          principal,
          action: 'ADMIN_CUSTOMER_CARD_GENERATED',
          entityId: recordId,
          newData: card as any,
        });
        await this.notificationService.send({
          customerId: recordId,
          title: 'SHIELD card ready',
          message: 'A SHIELD card was generated for your customer account.',
        });
        return {
          actionId: normalizedActionId,
          customerId: recordId.toString(),
          cardNumber: card.cardNumber,
          status: 'success',
        };
      }
      case 'print-profile': {
        this.assertPrincipalPermission(principal, 'customers.export');
        const customer = await this.customerService.findOne(recordId);
        const print = await this.platformPrintService.generate('PATIENT_SUMMARY', {
          patient: {
            patientId: customer.customerCode,
            name: this.resolveCustomerLabel(customer as any),
            mobile: customer.mobile,
            email: customer.email,
            gender: customer.gender,
            bloodGroup: customer.bloodGroup,
          },
        });
        return {
          actionId: normalizedActionId,
          customerId: recordId.toString(),
          ...print,
          status: 'success',
        };
      }
      default:
        throw new BadRequestException(
          `Unsupported customer workspace action "${actionId}".`,
        );
    }
  }

  async executeCustomerWorkspaceBulkAction(
    actionId: string,
    body: Record<string, unknown>,
    principal?: ShieldPrincipal,
  ) {
    const normalizedActionId = actionId.trim().toLowerCase();
    const recordIds = this.readRecordIds(body.record_ids);
    const userId = this.requirePrincipalUserId(principal);
    if (recordIds.length === 0) {
      throw new BadRequestException('record_ids must contain at least one customer id.');
    }
    switch (normalizedActionId) {
      case 'bulk-suspend':
        this.assertPrincipalPermission(principal, 'customers.approve');
        for (const recordId of recordIds) {
          await this.customerService.suspend(BigInt(recordId), userId);
        }
        return {
          actionId: normalizedActionId,
          recordIds,
          affected: recordIds.length,
          status: 'success',
        };
      case 'bulk-activate':
        this.assertPrincipalPermission(principal, 'customers.approve');
        for (const recordId of recordIds) {
          await this.customerService.activate(BigInt(recordId), userId);
        }
        return {
          actionId: normalizedActionId,
          recordIds,
          affected: recordIds.length,
          status: 'success',
        };
      case 'bulk-export-csv': {
        this.assertPrincipalPermission(principal, 'customers.export');
        const customers = await this.prisma.customer.findMany({
          where: { id: { in: recordIds.map((id) => BigInt(id)) } },
          orderBy: [{ updatedAt: 'desc' }],
        });
        const lines = [
          'Customer Code,First Name,Last Name,Mobile,Status',
          ...customers.map(
            (customer) =>
              [
                customer.customerCode ?? '',
                customer.firstName ?? '',
                customer.lastName ?? '',
                customer.mobile ?? '',
                customer.status ?? '',
              ]
                .map((value) => `"${`${value}`.replace(/"/g, '""')}"`)
                .join(','),
          ),
        ];
        return {
          actionId: normalizedActionId,
          fileName: 'customers-export.csv',
          mimeType: 'text/csv',
          contentBase64: Buffer.from(lines.join('\n'), 'utf8').toString('base64'),
          status: 'success',
        };
      }
      default:
        throw new BadRequestException(
          `Unsupported customer workspace bulk action "${actionId}".`,
        );
    }
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

  async getCustomersWorkspace(
    query: AdminGovernanceWorkspaceQuery,
    principal?: ShieldPrincipal,
  ) {
    const today = new Date();
    const startOfToday = new Date(today);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(today);
    endOfToday.setHours(23, 59, 59, 999);
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const search = query.search?.trim();
    const status = query.status?.trim().toUpperCase();
    const selectedTab = (query.tab?.trim().length ? query.tab!.trim() : 'Profile');
    const pageSize = Math.min(query.pageSize, 50);
    const page = query.page < 1 ? 1 : query.page;
    const customerWhere = {
      deletedAt: null,
      ...(status != null && status.length > 0 ? { status } : {}),
      ...(search == null || search.length === 0
        ? {}
        : {
            OR: [
              { firstName: { contains: search, mode: 'insensitive' as const } },
              { lastName: { contains: search, mode: 'insensitive' as const } },
              { customerCode: { contains: search, mode: 'insensitive' as const } },
              { mobile: { contains: search } },
              { email: { contains: search, mode: 'insensitive' as const } },
            ],
          }),
    };
    const orderBy = this.resolveCustomerWorkspaceOrderBy(query);

    const [
      totalCustomers,
      activeCustomers,
      inactiveCustomers,
      suspendedCustomers,
      newToday,
      newThisMonth,
      filteredCustomers,
      customers,
    ] = await Promise.all([
      this.prisma.customer.count({ where: { deletedAt: null } }),
      this.prisma.customer.count({
        where: { deletedAt: null, status: 'ACTIVE' },
      }),
      this.prisma.customer.count({
        where: { deletedAt: null, status: 'INACTIVE' },
      }),
      this.prisma.customer.count({
        where: { deletedAt: null, status: 'SUSPENDED' },
      }),
      this.prisma.customer.count({
        where: { deletedAt: null, createdAt: { gte: startOfToday, lte: endOfToday } },
      }),
      this.prisma.customer.count({
        where: { deletedAt: null, createdAt: { gte: startOfMonth } },
      }),
      this.prisma.customer.count({ where: customerWhere }),
      this.prisma.customer.findMany({
        where: customerWhere,
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
        orderBy: orderBy as any,
        take: pageSize,
        skip: (page - 1) * pageSize,
      }),
    ]);

    const selectedCustomerId = query.selectedId?.trim().length
      ? BigInt(query.selectedId.trim())
      : null;
    const selectedCustomer: any =
      selectedCustomerId == null
        ? null
        : await this.prisma.customer.findUnique({
            where: { id: selectedCustomerId },
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
          });

    const [
      selectedTimeline,
      selectedDocuments,
      selectedAppointments,
      selectedTasks,
      selectedActivities,
      selectedPurchases,
      selectedReferralEvents,
      selectedWalletSummary,
      selectedContacts,
      selectedConsultations,
      selectedLabReports,
      selectedPrescriptions,
      selectedDentalRecords,
      selectedStatusHistory,
      selectedAuditLogs,
      selectedLoginHistory,
    ] = selectedCustomer?.id == null
      ? [[], [], [], [], [], [], [], null, [], [], [], [], [], [], [], []]
      : await Promise.all([
          this.timelineService.getPatientTimeline(selectedCustomer.id),
          this.prisma.document.findMany({
            where: { customerId: selectedCustomer.id },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.appointment.findMany({
            where: { customerId: selectedCustomer.id },
            include: { provider: true },
            orderBy: [{ appointmentDate: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.crmTask.findMany({
            where: { customerId: selectedCustomer.id },
            include: {
              assignedToUser: {
                select: {
                  firstName: true,
                  lastName: true,
                  employeeCode: true,
                },
              },
            },
            orderBy: [{ dueDate: 'asc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.crmActivity.findMany({
            where: { customerId: selectedCustomer.id },
            include: { createdByUser: true },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.purchase.findMany({
            where: { customerId: selectedCustomer.id },
            include: { provider: true },
            orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.referralRewardEvent.findMany({
            where: {
              OR: [
                { referrerCustomerId: selectedCustomer.id },
                { referredCustomerId: selectedCustomer.id },
              ],
            },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          selectedCustomer.wallet == null
            ? Promise.resolve(null)
            : this.walletService.getWalletSummary(selectedCustomer.wallet.id),
          this.prisma.customerContact.findMany({
            where: { customerId: selectedCustomer.id },
            orderBy: [{ isPrimary: 'desc' }, { id: 'asc' }],
            take: 25,
          }),
          this.prisma.consultation.findMany({
            where: { customerId: selectedCustomer.id },
            include: { prescriptions: true },
            orderBy: [{ appointmentId: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.labReport.findMany({
            where: { customerId: selectedCustomer.id },
            include: { document: true },
            orderBy: [{ reportDate: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.prescription.findMany({
            where: { customerId: selectedCustomer.id },
            include: {
              consultation: {
                include: {
                  appointment: true,
                },
              },
            },
            orderBy: [{ issueDate: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.dentalRecord.findMany({
            where: { customerId: selectedCustomer.id },
            orderBy: [{ id: 'desc' }],
            take: 25,
          }),
          this.prisma.customerStatusHistory.findMany({
            where: { customerId: selectedCustomer.id },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.auditLog.findMany({
            where: {
              entityType: 'customers',
              entityId: selectedCustomer.id,
            },
            include: {
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  email: true,
                },
              },
            },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
          this.prisma.loginHistory.findMany({
            where: {
              ownerType: 'CUSTOMER',
              ownerId: selectedCustomer.id.toString(),
            },
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            take: 25,
          }),
        ]);

    const customerTableRows = (customers as any[]).map((customer: any) => ({
      id: customer.id.toString(),
      customer: this.resolveCustomerLabel(customer),
      membership:
        customer.membership?.membershipType?.name ??
        customer.membership?.membershipNumber ??
        'No membership',
      mobile: customer.mobile,
      status: customer.status ?? 'PENDING',
      joinedAt: this.formatDateTime(customer.createdAt),
      updatedAt: this.formatDateTime(customer.updatedAt),
    }));
    const rightPanel = this.buildCustomerWorkspaceRightPanel({
      tab: selectedTab,
      selectedCustomer,
      selectedTimeline: selectedTimeline as Array<Record<string, unknown>>,
      selectedDocuments,
      selectedAppointments,
      selectedTasks,
      selectedActivities,
      selectedPurchases,
      selectedReferralEvents,
      selectedWalletSummary,
      selectedContacts,
      selectedConsultations,
      selectedLabReports,
      selectedPrescriptions,
      selectedDentalRecords,
      selectedStatusHistory,
      selectedAuditLogs,
      selectedLoginHistory,
    });
    const customerPermissions = this.buildCustomerWorkspacePermissions(principal);
    const customerActions = this.buildCustomerWorkspaceActions(selectedCustomer);
    const customerBulkActions = this.buildCustomerWorkspaceBulkActions();

    return this.buildWorkspacePayload(
      'customers',
      {
        eyebrow: 'Admin / Customer operations',
        title: 'Customers',
        description:
          'Customer management is backend-owned end to end, including live counts, searchable customer lists, server pagination and sorting, and selected-customer detail workspaces.',
        primaryActionLabel: 'Export customers',
        secondaryActionLabel: 'Refresh customers',
      },
      {
        searchHint:
          'Search customers by name, customer code, mobile number, or email',
        tabs: [
          'Profile',
          'Wallet',
          'Membership',
          'Referrals',
          'Family',
          'Documents',
          'Medical Records',
          'Visits',
          'Timeline',
          'Activity Log',
          'Notes',
          'CRM',
          'Services Used',
          'Lab Reports',
          'Prescriptions',
        ],
        filters: ['ACTIVE', 'INACTIVE', 'SUSPENDED', 'PENDING', 'REJECTED'],
      },
      [
        this.metric('Customer count', totalCustomers, 'Live customer rows'),
        this.metric('Active members', activeCustomers, 'ACTIVE customers'),
        this.metric('Inactive', inactiveCustomers, 'INACTIVE customers'),
        this.metric('Suspended', suspendedCustomers, 'SUSPENDED customers'),
        this.metric('New today', newToday, 'Created since midnight'),
        this.metric('New this month', newThisMonth, 'Created this month'),
      ],
      {
        left: {
          title: 'Customer dashboard',
          subtitle: 'Selected customer summary and current data scope.',
          type: 'details',
          details:
            selectedCustomer == null
              ? []
              : [
                  {
                    label: 'Selected customer',
                    value: this.resolveCustomerLabel(selectedCustomer),
                  },
                  {
                    label: 'Current tab',
                    value: selectedTab,
                  },
                  {
                    label: 'Membership',
                    value:
                      selectedCustomer.membership?.membershipType?.name ??
                      selectedCustomer.membership?.membershipNumber ??
                      'No membership',
                  },
                  {
                    label: 'Wallet',
                    value:
                      selectedWalletSummary == null
                        ? 'Wallet unavailable'
                        : `Cash balance ₹${Number(selectedWalletSummary.cashWallet.available ?? 0).toFixed(2)} • Reward points ${selectedWalletSummary.rewardPoints.available ?? 0}`,
                  },
                  {
                    label: 'Card status',
                    value: selectedCustomer.shieldCard?.status ?? 'No card',
                  },
                  {
                    label: 'Data scope',
                    value:
                      `${filteredCustomers} matching customers • page ${page} of ${Math.max(1, Math.ceil(filteredCustomers / pageSize))}`,
                  },
                ],
          emptyState: {
            title: 'No customer selected',
            description:
              'Choose a customer from the live table to inspect profile, wallet, membership, referrals, documents, visits, and activity.',
            actionLabel: 'Adjust the current search or filters.',
          },
        },
        center: {
          title: 'Customer list',
          subtitle:
            '$filteredCustomers matching customers. Search, filters, sorting, pagination, and selection are all backend-backed.',
          type: 'table',
          columns: [
            { key: 'customer', label: 'Customer', sortKey: 'name' },
            { key: 'membership', label: 'Membership', sortKey: 'membership' },
            { key: 'mobile', label: 'Mobile', sortKey: 'mobile' },
            { key: 'status', label: 'Status', sortKey: 'status' },
            { key: 'joinedAt', label: 'Joined', sortKey: 'createdAt' },
            { key: 'updatedAt', label: 'Updated', sortKey: 'updatedAt' },
          ],
          rows: customerTableRows,
          selectionKey: 'id',
          selectedId: selectedCustomer?.id.toString(),
          selectionEnabled: true,
          sortKey: query.sortKey ?? 'updatedAt',
          sortDirection: query.sortDirection ?? 'desc',
          pagination: {
            page,
            pageSize,
            totalRows: filteredCustomers,
          },
          emptyState: {
            title: 'No customers matched this query',
            description:
              'The customer workspace is live, but the current search and status filter returned no customer rows.',
            actionLabel: 'Clear filters or refine the search.',
          },
        },
        right: rightPanel,
      },
      {
        actions: customerActions,
        bulkActions: customerBulkActions,
        permissions: customerPermissions,
        exports: [
          {
            id: 'customers-export-csv',
            label: 'CSV',
            format: 'CSV',
          },
        ],
        forms: [
          {
            id: 'edit',
            entity: 'customer',
          },
        ],
        commands: customerActions
          .map((action) => ({
            id: `customer.${action.id}`,
            permission: action.permission,
            inputSchema: {
              type: 'object',
              properties: action.requiresSelection
                ? {
                    record_id: { type: 'string' },
                  }
                : {},
            },
          })),
      },
    );
  }

  private resolveCustomerWorkspaceOrderBy(
    query: AdminGovernanceWorkspaceQuery,
  ): any[] {
    const direction = query.sortDirection === 'asc' ? 'asc' : 'desc';
    switch ((query.sortKey ?? '').trim()) {
      case 'name':
        return [{ firstName: direction }, { lastName: direction }, { id: 'desc' as const }];
      case 'mobile':
        return [{ mobile: direction }, { id: 'desc' as const }];
      case 'status':
        return [{ status: direction }, { updatedAt: 'desc' as const }];
      case 'createdAt':
        return [{ createdAt: direction }, { id: 'desc' as const }];
      case 'membership':
        return [
          { membership: { membershipNumber: direction } },
          { updatedAt: 'desc' as const },
        ];
      case 'updatedAt':
      default:
        return [{ updatedAt: direction }, { id: 'desc' as const }];
    }
  }

  private buildCustomerWorkspacePermissions(principal?: ShieldPrincipal) {
    return {
      canCreate: this.hasPrincipalPermission(principal, 'customers.create'),
      canDelete: this.hasPrincipalPermission(principal, 'customers.delete'),
      canSuspend: this.hasPrincipalPermission(principal, 'customers.approve'),
      canEdit: this.hasPrincipalPermission(principal, 'customers.update'),
      canAssign: false,
      canMerge: false,
      canExport: this.hasPrincipalPermission(principal, 'customers.export'),
      canPrint: this.hasPrincipalPermission(principal, 'customers.export'),
      canUpload: this.hasPrincipalPermission(principal, 'documents.create'),
    };
  }

  private buildCustomerWorkspaceActions(selectedCustomer: any): WorkspaceActionDescriptor[] {
    return [
      {
        id: 'edit',
        label: 'Edit customer',
        icon: 'edit',
        color: 'primary',
        category: 'primary',
        permission: 'customers.update',
        endpoint: '/admin/workspaces/customers/actions/edit',
        method: 'POST',
        requiresSelection: true,
        dialog: { type: 'FORM', formId: 'edit' },
        refreshAfterSuccess: true,
        successMessage: 'Customer updated successfully.',
      },
      {
        id: 'suspend',
        label: 'Suspend customer',
        icon: 'pause_circle',
        color: 'warning',
        category: 'secondary',
        permission: 'customers.approve',
        endpoint: '/admin/workspaces/customers/actions/suspend',
        method: 'POST',
        requiresSelection: true,
        confirmation: {
          title: 'Suspend customer',
          body: 'This will suspend the selected customer account and linked membership/card lifecycle.',
          confirmText: 'Suspend',
        },
        refreshAfterSuccess: true,
        successMessage: 'Customer suspended successfully.',
      },
      {
        id: 'activate',
        label: 'Activate customer',
        icon: 'check_circle',
        color: 'success',
        category: 'secondary',
        permission: 'customers.approve',
        endpoint: '/admin/workspaces/customers/actions/activate',
        method: 'POST',
        requiresSelection: true,
        refreshAfterSuccess: true,
        successMessage: 'Customer activated successfully.',
      },
      {
        id: 'delete',
        label: 'Delete customer',
        icon: 'delete_forever',
        color: 'danger',
        category: 'danger',
        permission: 'customers.delete',
        endpoint: '/admin/workspaces/customers/actions/delete',
        method: 'POST',
        requiresSelection: true,
        confirmation: {
          title: 'Delete customer',
          body: 'This performs a soft delete and removes the customer from active admin workspaces.',
          confirmText: 'Delete',
        },
        refreshAfterSuccess: true,
        successMessage: 'Customer deleted successfully.',
      },
      {
        id: 'generate-card',
        label: selectedCustomer?.shieldCard == null ? 'Generate card' : 'Replace card',
        icon: 'badge',
        color: 'primary',
        category: 'secondary',
        permission: 'customers.approve',
        endpoint: '/admin/workspaces/customers/actions/generate-card',
        method: 'POST',
        requiresSelection: true,
        refreshAfterSuccess: true,
        successMessage: 'Customer card generated successfully.',
      },
      {
        id: 'print-profile',
        label: 'Print profile',
        icon: 'print',
        color: 'secondary',
        category: 'secondary',
        permission: 'customers.export',
        endpoint: '/admin/workspaces/customers/actions/print-profile',
        method: 'POST',
        requiresSelection: true,
        refreshAfterSuccess: false,
      },
    ];
  }

  private buildCustomerWorkspaceBulkActions(): WorkspaceActionDescriptor[] {
    return [
      {
        id: 'bulk-suspend',
        label: 'Suspend selected',
        icon: 'pause_circle',
        color: 'warning',
        category: 'secondary',
        permission: 'customers.approve',
        endpoint: '/admin/workspaces/customers/bulk-actions/bulk-suspend',
        method: 'POST',
        allowBulk: true,
        refreshAfterSuccess: true,
      },
      {
        id: 'bulk-activate',
        label: 'Activate selected',
        icon: 'check_circle',
        color: 'success',
        category: 'secondary',
        permission: 'customers.approve',
        endpoint: '/admin/workspaces/customers/bulk-actions/bulk-activate',
        method: 'POST',
        allowBulk: true,
        refreshAfterSuccess: true,
      },
      {
        id: 'bulk-export-csv',
        label: 'Export selected CSV',
        icon: 'download',
        color: 'primary',
        category: 'secondary',
        permission: 'customers.export',
        endpoint: '/admin/workspaces/customers/bulk-actions/bulk-export-csv',
        method: 'POST',
        allowBulk: true,
        refreshAfterSuccess: false,
      },
    ];
  }

  private hasPrincipalPermission(
    principal: ShieldPrincipal | undefined,
    permission: string,
  ) {
    return Boolean(principal?.permissions.includes(permission));
  }

  private assertPrincipalPermission(
    principal: ShieldPrincipal | undefined,
    permission: string,
  ) {
    if (!this.hasPrincipalPermission(principal, permission)) {
      throw new ForbiddenException(`Missing required permission: ${permission}`);
    }
  }

  private requirePrincipalUserId(principal?: ShieldPrincipal) {
    if (!principal?.userId?.trim().length) {
      throw new ForbiddenException('Authenticated admin user required.');
    }
    return BigInt(principal.userId.trim());
  }

  private requireRecordId(value: unknown) {
    const normalized = `${value ?? ''}`.trim();
    if (!normalized.length) {
      throw new BadRequestException('record_id is required.');
    }
    return BigInt(normalized);
  }

  private readRecordIds(value: unknown) {
    return Array.isArray(value)
      ? value.map((item) => `${item ?? ''}`.trim()).filter((item) => item.length > 0)
      : [];
  }

  private async recordCustomerWorkspaceAudit(input: {
    principal?: ShieldPrincipal;
    action: string;
    entityId: bigint;
    oldData?: Record<string, unknown> | null;
    newData?: Record<string, unknown> | null;
  }) {
    await this.timelineService.recordAuditLog({
      userId: input.principal?.userId?.trim()
        ? BigInt(input.principal.userId.trim())
        : undefined,
      action: input.action,
      entityType: 'customers',
      entityId: input.entityId,
      oldData: input.oldData ?? undefined,
      newData: input.newData ?? undefined,
    });
  }

  private buildCustomerWorkspaceRightPanel(input: {
    tab: string;
    selectedCustomer: any;
    selectedTimeline: Array<Record<string, unknown>>;
    selectedDocuments: any[];
    selectedAppointments: any[];
    selectedTasks: any[];
    selectedActivities: any[];
    selectedPurchases: any[];
    selectedReferralEvents: any[];
    selectedWalletSummary: any;
    selectedContacts: any[];
    selectedConsultations: any[];
    selectedLabReports: any[];
    selectedPrescriptions: any[];
    selectedDentalRecords: any[];
    selectedStatusHistory: any[];
    selectedAuditLogs: any[];
    selectedLoginHistory: any[];
  }): WorkspacePanel {
    const {
      tab,
      selectedCustomer,
      selectedTimeline,
      selectedDocuments,
      selectedAppointments,
      selectedTasks,
      selectedActivities,
      selectedPurchases,
      selectedReferralEvents,
      selectedWalletSummary,
      selectedContacts,
      selectedConsultations,
      selectedLabReports,
      selectedPrescriptions,
      selectedDentalRecords,
      selectedStatusHistory,
      selectedAuditLogs,
      selectedLoginHistory,
    } = input;
    const customerLabel =
      selectedCustomer == null
        ? 'No customer selected'
        : this.resolveCustomerLabel(selectedCustomer);
    const emptyState = {
      title: 'No customer selected',
      description:
        'Select a customer from the live table to inspect detail tabs and related workflow data.',
      actionLabel: 'Choose a customer from the table.',
    };
    if (selectedCustomer == null) {
      return {
        title: tab,
        subtitle: 'Select a customer to load this workspace.',
        type: 'details',
        details: [],
        emptyState,
      };
    }

    switch (tab.trim().toLowerCase()) {
      case 'wallet':
        return {
          title: 'Wallet',
          subtitle: `Ledger summary for ${customerLabel}.`,
          type: 'details',
          details: [
            {
              label: 'Cash available',
              value:
                selectedWalletSummary == null
                  ? '0.00'
                  : this.formatMoneyValue(
                      Number(selectedWalletSummary.cashWallet.available ?? 0),
                    ),
            },
            {
              label: 'Cash spent',
              value:
                selectedWalletSummary == null
                  ? '0.00'
                  : this.formatMoneyValue(
                      Number(selectedWalletSummary.cashWallet.spent ?? 0),
                    ),
            },
            {
              label: 'Reward points',
              value:
                selectedWalletSummary == null
                  ? '0'
                  : `${selectedWalletSummary.rewardPoints.available ?? 0}`,
            },
            {
              label: 'Benefit applied',
              value:
                selectedWalletSummary == null
                  ? '0.00'
                  : this.formatMoneyValue(
                      Number(selectedWalletSummary.hiddenBenefits.applied ?? 0),
                    ),
            },
          ],
          emptyState: {
            title: 'Wallet data unavailable',
            description:
              'This customer does not yet have a wallet summary available through the ledger service.',
            actionLabel: 'Refresh after wallet activity is recorded.',
          },
        };
      case 'membership':
        return {
          title: 'Membership',
          subtitle: `Membership and lifecycle history for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'membership', label: 'Membership' },
            { key: 'number', label: 'Number' },
            { key: 'status', label: 'Status' },
            { key: 'expiry', label: 'Expiry' },
          ],
          rows: [
            {
              membership:
                selectedCustomer.membership?.membershipType?.name ?? 'No membership',
              number: selectedCustomer.membership?.membershipNumber ?? 'N/A',
              status: selectedCustomer.membership?.status ?? 'N/A',
              expiry: this.formatDateTime(selectedCustomer.membership?.expiryDate),
            },
            ...selectedStatusHistory.map((row) => ({
              membership: 'Status change',
              number: row.remarks?.toString().trim() || 'N/A',
              status: row.newStatus?.toString().trim() || 'UNKNOWN',
              expiry: this.formatDateTime(row.createdAt),
            })),
          ],
          emptyState: {
            title: 'No membership history',
            description:
              'No membership or customer lifecycle records were found for the selected customer.',
            actionLabel: 'Create or renew a membership to populate this view.',
          },
        };
      case 'referrals':
        return {
          title: 'Referrals',
          subtitle: `Referral tree events connected to ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'createdAt', label: 'Created' },
            { key: 'role', label: 'Role' },
            { key: 'status', label: 'Status' },
            { key: 'amount', label: 'Amount' },
          ],
          rows: selectedReferralEvents.map((event) => ({
            createdAt: this.formatDateTime(event.createdAt),
            role:
              event.referrerCustomerId === selectedCustomer.id
                ? 'Referrer'
                : 'Referred',
            status: event.status?.toString().trim() || 'UNKNOWN',
            amount: this.formatMoney(event.rewardAmount),
          })),
          emptyState: {
            title: 'No referral events',
            description:
              'This customer has no referral reward events recorded yet.',
            actionLabel: 'Create or qualify referrals to populate this tab.',
          },
        };
      case 'family':
        return {
          title: 'Family',
          subtitle: `Saved contact records for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'name', label: 'Name' },
            { key: 'relation', label: 'Relation' },
            { key: 'mobile', label: 'Mobile' },
            { key: 'primary', label: 'Primary' },
          ],
          rows: selectedContacts.map((contact) => ({
            name: [contact.firstName, contact.lastName]
                .filter(
                  (value: any) => (value ?? '').toString().trim().length > 0,
                )
                .join(' ')
                .trim(),
            relation: contact.relationship?.toString().trim() || 'N/A',
            mobile: contact.mobile?.toString().trim() || 'N/A',
            primary: contact.isPrimary == true ? 'Yes' : 'No',
          })),
          emptyState: {
            title: 'No family contacts',
            description:
              'This customer does not have any saved customer_contacts rows yet.',
            actionLabel: 'Add contact records to populate this tab.',
          },
        };
      case 'documents':
        return {
          title: 'Documents',
          subtitle: `Uploaded customer documents for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'fileName', label: 'File' },
            { key: 'status', label: 'Status' },
            { key: 'type', label: 'Type' },
            { key: 'uploadedAt', label: 'Uploaded' },
          ],
          rows: selectedDocuments.map((document) => ({
            fileName:
              document.fileName?.toString().trim() ||
              document.originalFileName?.toString().trim() ||
              'Document',
            status: document.status?.toString().trim() || 'UPLOADED',
            type: document.documentType?.toString().trim() || 'UNKNOWN',
            uploadedAt: this.formatDateTime(document.createdAt),
          })),
          emptyState: {
            title: 'No documents uploaded',
            description:
              'No customer documents were found for the selected customer.',
            actionLabel: 'Upload a document to populate this tab.',
          },
        };
      case 'medical records':
        return {
          title: 'Medical records',
          subtitle: `Clinical, dental, and consultation notes for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'category', label: 'Category' },
            { key: 'summary', label: 'Summary' },
            { key: 'status', label: 'Status' },
            { key: 'recordedAt', label: 'Recorded' },
          ],
          rows: [
            ...selectedConsultations.map((consultation) => ({
              category: 'Consultation',
              summary: consultation.diagnosis?.toString().trim() || 'Consultation note',
              status: consultation.status?.toString().trim() || 'RECORDED',
              recordedAt: this.formatDateTime(consultation.createdAt),
            })),
            ...selectedDentalRecords.map((record) => ({
              category: 'Dental',
              summary: record.chiefComplaint?.toString().trim() || 'Dental record',
              status: 'RECORDED',
              recordedAt: this.formatDateTime(record.createdAt),
            })),
          ],
          emptyState: {
            title: 'No medical records',
            description:
              'This customer has no consultation or dental records in the current backend scope.',
            actionLabel: 'Complete consultations or dental visits to populate this tab.',
          },
        };
      case 'visits':
        return {
          title: 'Visits',
          subtitle: `Appointments and visit status for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'date', label: 'Date' },
            { key: 'provider', label: 'Provider' },
            { key: 'service', label: 'Service' },
            { key: 'status', label: 'Status' },
          ],
          rows: selectedAppointments.map((appointment) => ({
            date: this.formatDateTime(appointment.appointmentDate),
            provider:
              appointment.provider?.displayName?.toString().trim() ||
              appointment.provider?.providerCode?.toString().trim() ||
              'Provider',
            service: appointment.appointmentType?.toString().trim() || 'Visit',
            status: appointment.status?.toString().trim() || 'SCHEDULED',
          })),
          emptyState: {
            title: 'No visits found',
            description:
              'The selected customer does not have any appointment rows yet.',
            actionLabel: 'Create or schedule a visit to populate this tab.',
          },
        };
      case 'timeline':
        return {
          title: 'Timeline',
          subtitle: `Cross-domain history from the shared timeline service for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'time', label: 'Time' },
            { key: 'event', label: 'Event' },
            { key: 'status', label: 'Status' },
          ],
          rows: selectedTimeline.slice(0, 25).map((event) => ({
            time: `${event['timestamp'] ?? ''}`,
            event: `${event['displayTitle'] ?? 'Timeline event'}`,
            status: `${event['status'] ?? 'RECORDED'}`,
          })),
          emptyState: {
            title: 'No timeline events available',
            description:
              'The shared timeline service has not yet produced events for this customer.',
            actionLabel: 'Open a customer with documents, visits, or wallet activity.',
          },
        };
      case 'activity log':
        return {
          title: 'Activity log',
          subtitle: `Audit and login activity for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'time', label: 'Time' },
            { key: 'action', label: 'Action' },
            { key: 'actor', label: 'Actor' },
            { key: 'detail', label: 'Detail' },
          ],
          rows: [
            ...selectedAuditLogs.map((log) => ({
              time: this.formatDateTime(log.createdAt),
              action: log.action?.toString().trim() || 'AUDIT',
              actor: this.resolveActorLabel(log.user),
              detail:
                log.entityType?.toString().trim() || log.ipAddress?.toString().trim() || 'Audit log',
            })),
            ...selectedLoginHistory.map((row) => ({
              time: this.formatDateTime(row.createdAt),
              action: row.status?.toString().trim() || 'LOGIN',
              actor: row.loginMethod?.toString().trim() || 'Customer auth',
              detail:
                row.deviceInfo?.toString().trim() ||
                row.ipAddress?.toString().trim() ||
                'Login history',
            })),
          ],
          emptyState: {
            title: 'No activity recorded',
            description:
              'No audit or login evidence is currently stored for the selected customer.',
            actionLabel: 'Perform customer workflows to generate activity evidence.',
          },
        };
      case 'notes':
        return {
          title: 'Notes',
          subtitle: `Freeform CRM and consultation notes for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'time', label: 'Time' },
            { key: 'source', label: 'Source' },
            { key: 'note', label: 'Note' },
          ],
          rows: [
            ...selectedActivities
              .filter((activity) => `${activity.notes ?? ''}`.trim().length > 0)
              .map((activity) => ({
                time: this.formatDateTime(activity.createdAt),
                source: 'CRM activity',
                note: activity.notes?.toString().trim() || '',
              })),
            ...selectedConsultations
              .filter(
                (consultation) =>
                  `${consultation.notes ?? ''}`.trim().length > 0,
              )
              .map((consultation) => ({
                time: this.formatDateTime(consultation.createdAt),
                source: 'Consultation',
                note: consultation.notes?.toString().trim() || '',
              })),
          ],
          emptyState: {
            title: 'No notes available',
            description:
              'There are no CRM activity notes or consultation notes for this customer.',
            actionLabel: 'Add notes through CRM or consultation workflows.',
          },
        };
      case 'crm':
        return {
          title: 'CRM',
          subtitle: `Tasks and CRM activity for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'type', label: 'Type' },
            { key: 'summary', label: 'Summary' },
            { key: 'owner', label: 'Owner' },
            { key: 'status', label: 'Status' },
          ],
          rows: [
            ...selectedTasks.map((task) => ({
              type: 'Task',
              summary: task.title?.toString().trim() || 'CRM task',
              owner: this.resolveUserDisplayName(task.assignedToUser),
              status: task.status?.toString().trim() || 'OPEN',
            })),
            ...selectedActivities.map((activity) => ({
              type: activity.activityType?.toString().trim() || 'Activity',
              summary: activity.subject?.toString().trim() || 'CRM activity',
              owner: this.resolveUserDisplayName(activity.createdByUser),
              status: activity.status?.toString().trim() || 'RECORDED',
            })),
          ],
          emptyState: {
            title: 'No CRM records',
            description:
              'This customer does not currently have CRM tasks or CRM activities.',
            actionLabel: 'Assign CRM follow-ups to populate this tab.',
          },
        };
      case 'services used':
        return {
          title: 'Services used',
          subtitle: `Purchase and provider service history for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'date', label: 'Date' },
            { key: 'provider', label: 'Provider' },
            { key: 'bill', label: 'Bill amount' },
            { key: 'status', label: 'Status' },
          ],
          rows: selectedPurchases.map((purchase) => ({
            date: this.formatDateTime(purchase.purchaseDate),
            provider:
              purchase.provider?.displayName?.toString().trim() ||
              purchase.provider?.providerCode?.toString().trim() ||
              'Provider',
            bill: this.formatMoney(purchase.totalAmount),
            status: purchase.status?.toString().trim() || 'RECORDED',
          })),
          emptyState: {
            title: 'No services recorded',
            description:
              'The selected customer has no purchase or service history yet.',
            actionLabel: 'Complete provider or pharmacy transactions to populate this tab.',
          },
        };
      case 'lab reports':
        return {
          title: 'Lab reports',
          subtitle: `Lab report history for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'reportDate', label: 'Report date' },
            { key: 'title', label: 'Title' },
            { key: 'status', label: 'Status' },
            { key: 'document', label: 'Document' },
          ],
          rows: selectedLabReports.map((report) => ({
            reportDate: this.formatDateTime(report.reportDate),
            title: report.reportType?.toString().trim() || 'Lab report',
            status: report.status?.toString().trim() || 'RECORDED',
            document:
              report.document?.fileName?.toString().trim() || 'No document',
          })),
          emptyState: {
            title: 'No lab reports',
            description:
              'No lab_reports rows were found for this customer.',
            actionLabel: 'Upload or complete lab reports to populate this tab.',
          },
        };
      case 'prescriptions':
        return {
          title: 'Prescriptions',
          subtitle: `Prescription history for ${customerLabel}.`,
          type: 'table',
          columns: [
            { key: 'issueDate', label: 'Issued' },
            { key: 'doctor', label: 'Doctor' },
            { key: 'summary', label: 'Summary' },
            { key: 'status', label: 'Status' },
          ],
          rows: selectedPrescriptions.map((prescription) => ({
            issueDate: this.formatDateTime(prescription.issueDate),
            doctor:
              prescription.consultation?.doctorName?.toString().trim() ||
              'Doctor',
            summary:
              prescription.instructions?.toString().trim() ||
              prescription.diagnosis?.toString().trim() ||
              'Prescription',
            status: prescription.status?.toString().trim() || 'ISSUED',
          })),
          emptyState: {
            title: 'No prescriptions',
            description:
              'No prescription records were found for this customer.',
            actionLabel: 'Complete consultations to generate prescriptions.',
          },
        };
      case 'profile':
      default:
        return {
          title: 'Profile',
          subtitle: `Core customer identity for ${customerLabel}.`,
          type: 'details',
          details: [
            { label: 'Customer', value: customerLabel },
            { label: 'Customer code', value: selectedCustomer.customerCode ?? 'N/A' },
            { label: 'Mobile', value: selectedCustomer.mobile ?? 'N/A' },
            { label: 'Email', value: selectedCustomer.email ?? 'N/A' },
            {
              label: 'Status',
              value: selectedCustomer.status?.toString().trim() || 'UNKNOWN',
            },
            {
              label: 'Date of birth',
              value: this.formatDateTime(selectedCustomer.dob),
            },
            { label: 'Gender', value: selectedCustomer.gender ?? 'N/A' },
            {
              label: 'Address',
              value: [
                selectedCustomer.addressLine1,
                selectedCustomer.addressLine2,
                selectedCustomer.city,
                selectedCustomer.district,
                selectedCustomer.state,
                selectedCustomer.pincode,
              ]
                  .filter(
                    (value: any) => (value ?? '').toString().trim().length > 0,
                  )
                  .join(', '),
            },
            {
              label: 'Agent code',
              value: selectedCustomer.agentCode?.toString().trim() || 'Unassigned',
            },
            {
              label: 'Referral code',
              value: selectedCustomer.referralCode?.toString().trim() || 'N/A',
            },
            {
              label: 'Last login',
              value: this.formatDateTime(selectedCustomer.lastLoginAt),
            },
          ],
        };
    }
  }

  async getAgentsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const agentWhere: any = {
      deletedAt: null,
      OR: [{ userType: 'SHIELD_AGENT' }, { role: { code: 'SHIELD_AGENT' } }],
    };
    const selectedTab = (query.tab ?? 'Overview').trim();
    const [agentCount, assignmentCount, activeSessions, agentUsers, customerRows, followUpRows, visitRows, sessionRows, documentRows, auditRows] =
      await Promise.all([
        this.prisma.user.count({ where: agentWhere }),
        this.prisma.agentBranchAssignment.count(),
        this.prisma.authSession.count({
          where: {
            revokedAt: null,
            user: agentWhere,
          },
        }),
        this.prisma.user.findMany({
          where: agentWhere,
          include: {
            branchBusiness: { select: { name: true } },
            role: { select: { code: true, name: true } },
          },
          orderBy: [{ updatedAt: 'desc' }],
          take: Math.min(query.pageSize, 25),
          skip: (query.page - 1) * query.pageSize,
        }),
        this.prisma.customer.findMany({
          where: { deletedAt: null },
          orderBy: [{ createdAt: 'desc' }],
          take: 25,
        }),
        this.prisma.crmTask.findMany({
          orderBy: [{ dueDate: 'asc' }, { id: 'desc' }],
          take: 25,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            assignedToUser: { select: { firstName: true, lastName: true, employeeCode: true } },
          },
        }),
        this.prisma.appointment.findMany({
          orderBy: [{ appointmentDate: 'desc' }],
          take: 25,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
          },
        }),
        this.prisma.authSession.findMany({
          where: { user: agentWhere },
          orderBy: [{ lastSeenAt: 'desc' }],
          take: 25,
          include: {
            user: { select: { firstName: true, lastName: true, employeeCode: true } },
            authDevice: { select: { deviceName: true, platform: true } },
          },
        }),
        this.prisma.document.findMany({
          where: { uploadedByUser: agentWhere },
          orderBy: [{ createdAt: 'desc' }],
          take: 25,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            uploadedByUser: { select: { firstName: true, lastName: true, employeeCode: true } },
          },
        }),
        this.prisma.auditLog.findMany({
          where: { entityType: { in: ['users', 'agent_branch_assignments'] } },
          orderBy: [{ createdAt: 'desc' }],
          take: 25,
          include: { user: { select: { firstName: true, lastName: true, email: true } } },
        }),
      ]);

    const agentTableRows = this.filterRowsBySearch(
      agentUsers.map((agent) => ({
        name: this.resolveUserDisplayName(agent as any),
        code: agent.employeeCode?.trim() || 'N/A',
        role:
          (agent as any).role?.code?.trim() ||
          agent.userType?.trim() ||
          'AGENT',
        branch: (agent as any).branchBusiness?.name?.trim() || 'Unassigned',
        status: agent.status?.trim() || 'UNKNOWN',
        updatedAt: this.formatDateTime(agent.updatedAt),
      })),
      query.search,
    );
    const assignedCustomersRows = this.filterRowsBySearch(
      customerRows.map((customer) => ({
        name: this.resolveCustomerLabel(customer),
        code: customer.customerCode?.trim() || 'N/A',
        agent: customer.agentCode?.trim() || 'N/A',
        status: customer.status?.trim() || 'UNKNOWN',
        updatedAt: this.formatDateTime(customer.createdAt),
      })),
      query.search,
    );
    const followUpsTableRows = this.filterRowsBySearch(
      followUpRows.map((task) => ({
        due: this.formatDateTime(task.dueDate),
        customer: this.resolveCustomerLabel(task.customer),
        assignee: this.resolveUserDisplayName(task.assignedToUser as any),
        status: task.status?.trim() || 'UNKNOWN',
        notes: task.notes?.trim() || 'N/A',
      })),
      query.search,
    );
    const visitTableRows = this.filterRowsBySearch(
      visitRows.map((visit) => ({
        date: this.formatDateTime(visit.appointmentDate),
        customer: this.resolveCustomerLabel(visit.customer),
        type: visit.appointmentType?.trim() || 'GENERAL',
        status: visit.status?.trim() || 'UNKNOWN',
        remarks: visit.remarks?.trim() || 'N/A',
      })),
      query.search,
    );
    const attendanceTableRows = this.filterRowsBySearch(
      sessionRows.map((session) => ({
        user: this.resolveUserDisplayName((session as any).user),
        device:
          (session as any).authDevice?.deviceName?.trim() || 'Unknown device',
        platform: (session as any).authDevice?.platform?.trim() || 'UNKNOWN',
        status: session.revokedAt == null ? 'ACTIVE' : 'REVOKED',
        lastSeen: this.formatDateTime(session.lastSeenAt),
      })),
      query.search,
    );
    const documentTableRows = this.filterRowsBySearch(
      documentRows.map((document) => ({
        createdAt: this.formatDateTime(document.createdAt),
        customer: this.resolveCustomerLabel((document as any).customer),
        uploadedBy: this.resolveUserDisplayName(
          (document as any).uploadedByUser,
        ),
        type: document.documentType?.trim() || 'DOCUMENT',
        status: document.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const timelineRows = this.filterRowsBySearch(
      auditRows.map((row) => ({
        time: this.formatDateTime(row.createdAt),
        event: row.action?.trim() || 'AUDIT_EVENT',
        status: row.entityType?.trim() || 'users',
      })),
      query.search,
    );

    const selectedRows =
      selectedTab == 'Customers'
        ? assignedCustomersRows
        : selectedTab == 'Follow-Ups'
          ? followUpsTableRows
          : selectedTab == 'Visits'
            ? visitTableRows
            : selectedTab == 'Attendance'
              ? attendanceTableRows
              : selectedTab == 'Documents'
                ? documentTableRows
                : selectedTab == 'Timeline'
                  ? timelineRows
                  : agentTableRows;
    const selectedColumns =
      selectedTab == 'Customers'
        ? [
            { key: 'name', label: 'Customer' },
            { key: 'code', label: 'Code' },
            { key: 'agent', label: 'Agent' },
            { key: 'status', label: 'Status' },
            { key: 'updatedAt', label: 'Created' },
          ]
        : selectedTab == 'Follow-Ups'
          ? [
              { key: 'due', label: 'Due' },
              { key: 'customer', label: 'Customer' },
              { key: 'assignee', label: 'Assignee' },
              { key: 'status', label: 'Status' },
              { key: 'notes', label: 'Notes' },
            ]
          : selectedTab == 'Visits'
            ? [
                { key: 'date', label: 'Visit date' },
                { key: 'customer', label: 'Customer' },
                { key: 'type', label: 'Type' },
                { key: 'status', label: 'Status' },
                { key: 'remarks', label: 'Remarks' },
              ]
            : selectedTab == 'Attendance'
              ? [
                  { key: 'user', label: 'Agent' },
                  { key: 'device', label: 'Device' },
                  { key: 'platform', label: 'Platform' },
                  { key: 'status', label: 'Status' },
                  { key: 'lastSeen', label: 'Last seen' },
                ]
              : selectedTab == 'Documents'
                ? [
                    { key: 'createdAt', label: 'Uploaded' },
                    { key: 'customer', label: 'Customer' },
                    { key: 'uploadedBy', label: 'Uploaded by' },
                    { key: 'type', label: 'Type' },
                    { key: 'status', label: 'Status' },
                  ]
                : selectedTab == 'Timeline'
                  ? [
                      { key: 'time', label: 'Time' },
                      { key: 'event', label: 'Event' },
                      { key: 'status', label: 'Entity' },
                    ]
                  : [
                      { key: 'name', label: 'Agent' },
                      { key: 'code', label: 'Code' },
                      { key: 'role', label: 'Role' },
                      { key: 'branch', label: 'Branch' },
                      { key: 'status', label: 'Status' },
                      { key: 'updatedAt', label: 'Updated' },
                    ];

    const agentActions = [
      {
        id: 'create-agent',
        label: 'Create Agent',
        icon: 'person_add',
        color: 'primary',
        category: 'WORKSPACE',
        endpoint: '/admin/agents/actions/create-agent',
        method: 'POST',
        refreshAfterSuccess: true,
        permission: 'agents.create',
        requiresSelection: false,
        allowBulk: false,
        dialog: {
          type: 'FORM',
          formId: 'create-agent-form',
          title: 'Create New SHIELD Agent',
          description:
            'Enroll a new agent with employee code, department, branch assignment, and profile credentials.',
          submitLabel: 'Create Agent',
        },
      },
    ];

    const agentForms = [
      {
        id: 'create-agent-form',
        title: 'Agent Provisioning Form',
        fields: [
          { key: 'firstName', label: 'First Name', type: 'text', required: true },
          { key: 'lastName', label: 'Last Name', type: 'text', required: false },
          {
            key: 'employeeCode',
            label: 'Agent / Employee Code',
            type: 'text',
            required: true,
            helperText: 'e.g. AGNT-0003 or EMP-0003',
          },
          {
            key: 'mobile',
            label: 'Mobile Number',
            type: 'text',
            required: true,
            helperText: '10-digit mobile number',
          },
          {
            key: 'email',
            label: 'Email Address (Google Sign-In)',
            type: 'text',
            required: true,
            helperText: 'Agent will authenticate via Google Sign-In using this email address.',
          },
          {
            key: 'department',
            label: 'Department',
            type: 'select',
            options: [
              'Administration',
              'Field Operations',
              'Customer Enrollment',
              'Healthcare Services',
              'Sales',
              'Customer Support',
            ],
            required: true,
          },
          {
            key: 'branch',
            label: 'Assigned Branch',
            type: 'select',
            options: [
              'Sahakar Healthcare Group',
              'Hyperpharmacy Branch 1',
              'Hyperpharmacy Main Store',
            ],
            required: true,
          },
          {
            key: 'accessScope',
            label: 'Access Scope',
            type: 'select',
            options: ['BRANCH_SCOPED', 'CROSS_BRANCH', 'ORGANIZATION'],
            required: true,
          },
          {
            key: 'status',
            label: 'Initial Status',
            type: 'select',
            options: ['ACTIVE', 'PENDING', 'INACTIVE'],
            required: true,
          },
        ],
      },
    ];

    return this.buildWorkspacePayload(
      'agents',
      {
        eyebrow: 'Operations / Agents',
        title: 'Agents',
        description:
          'Backend-owned agent operations across assignment, customers, follow-ups, visits, attendance, and uploaded records.',
        primaryActionLabel: 'Create Agent',
        secondaryActionLabel: 'Attendance',
      },
      {
        searchHint: 'Search agents, assigned customers, follow-ups, visits, and uploads',
        tabs: ['Overview', 'Customers', 'Follow-Ups', 'Visits', 'Attendance', 'Documents', 'Timeline'],
        filters: ['ACTIVE', 'PENDING', 'INACTIVE'],
      },
      [
        this.metric('Agents', agentCount, 'Internal users with agent ownership'),
        this.metric('Assignments', assignmentCount, 'agent_branch_assignments rows'),
        this.metric('Live sessions', activeSessions, 'Active agent auth sessions'),
        this.metric('Follow-ups', followUpsTableRows.length, 'Current CRM tasks in scope'),
      ],
      {
        left: {
          title: 'Assignment posture',
          subtitle: 'Agent and branch coverage from current records.',
          type: 'list',
          items: agentTableRows.slice(0, 8).map((row) => ({
            title: row['name'] ?? 'Agent',
            subtitle: `${row['branch'] ?? 'Unassigned'} • ${row['role'] ?? 'AGENT'}`,
            meta: row['code'] ?? 'N/A',
            status: row['status'] ?? 'UNKNOWN',
          })),
          emptyState: {
            title: 'No agents matched this query',
            description: 'No agent users matched the current search or filter.',
            actionLabel: 'Refresh workspace',
          },
        },
        center: {
          title: selectedTab == 'Overview' ? 'Agent registry' : `${selectedTab} queue`,
          subtitle: 'The active tab drives the dataset returned by the backend workspace contract.',
          type: 'table',
          columns: selectedColumns,
          rows: selectedRows,
          emptyState: {
            title: 'No agent records matched this view',
            description: 'The selected tab completed successfully but returned no rows for the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent agent timeline',
          subtitle: 'Live audit evidence tied to user and assignment entities.',
          type: 'table',
          columns: [
            { key: 'time', label: 'Time' },
            { key: 'event', label: 'Event' },
            { key: 'status', label: 'Entity' },
          ],
          rows: timelineRows,
          emptyState: {
            title: 'No agent timeline rows',
            description: 'No recent audit evidence matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
      {
        actions: agentActions as any,
        forms: agentForms,
        permissions: {
          canCreate: true,
          canEdit: true,
        },
        exports: [
          {
            id: 'agents-export-csv',
            label: 'CSV',
            format: 'CSV',
          },
        ],
      },
    );
  }

  async getAgentWorkspaceForm(
    formId: string,
    recordId?: string | null,
    principal?: ShieldPrincipal,
  ) {
    const normalizedFormId = formId.trim().toLowerCase();
    if (
      normalizedFormId === 'create-agent-form' ||
      normalizedFormId === 'create-agent'
    ) {
      const [branches, nextCode] = await Promise.all([
        this.prisma.business.findMany({
          where: { status: 'ACTIVE' },
          select: { name: true },
        }),
        this.generateNextAgentCode(),
      ]);

      const branchOptions = branches.length
        ? branches.map((b) => b.name)
        : [
            'Sahakar Healthcare Group',
            'Hyperpharmacy Branch 1',
            'Hyperpharmacy Main Store',
          ];

      return {
        id: 'create-agent-form',
        entity: 'agent',
        title: 'Agent Provisioning Form',
        fields: [
          { key: 'firstName', label: 'First Name', type: 'text', required: true },
          { key: 'lastName', label: 'Last Name', type: 'text', required: false },
          {
            key: 'employeeCode',
            label: 'Agent / Employee Code',
            type: 'text',
            required: true,
            readOnly: true,
            value: nextCode,
            helperText: 'Auto-generated. Cannot be changed.',
          },
          {
            key: 'mobile',
            label: 'Mobile Number',
            type: 'text',
            required: true,
            helperText: '10-digit mobile number',
          },
          {
            key: 'email',
            label: 'Email Address (Google Sign-In)',
            type: 'text',
            required: true,
            helperText:
              'Agent will authenticate via Google Sign-In using this email address.',
          },
          {
            key: 'department',
            label: 'Department',
            type: 'select',
            options: [
              'Administration',
              'Field Operations',
              'Customer Enrollment',
              'Healthcare Services',
              'Sales',
              'Customer Support',
            ],
            required: true,
          },
          {
            key: 'branch',
            label: 'Assigned Branch',
            type: 'select',
            options: branchOptions,
            required: true,
          },
          {
            key: 'accessScope',
            label: 'Access Scope',
            type: 'select',
            options: ['BRANCH_SCOPED', 'CROSS_BRANCH', 'ORGANIZATION'],
            required: true,
          },
          {
            key: 'status',
            label: 'Initial Status',
            type: 'select',
            options: ['ACTIVE', 'PENDING', 'INACTIVE'],
            value: 'ACTIVE',
            required: true,
          },
        ],
      };
    }
    throw new BadRequestException(
      `Unsupported agent workspace form "${formId}".`,
    );
  }

  /**
   * Derives the next sequential AGNT-NNNN code by scanning existing
   * employeeCodes that match the AGNT-\d+ pattern.
   */
  private async generateNextAgentCode(): Promise<string> {
    const allCodes = await this.prisma.user.findMany({
      where: {
        employeeCode: { startsWith: 'AGNT-' },
        deletedAt: null,
      },
      select: { employeeCode: true },
    });

    let maxSeq = 0;
    for (const { employeeCode } of allCodes) {
      const match = /^AGNT-(\d+)$/i.exec(employeeCode ?? '');
      if (match) {
        const seq = parseInt(match[1], 10);
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    return `AGNT-${String(maxSeq + 1).padStart(4, '0')}`;
  }

  async executeAgentWorkspaceAction(
    actionId: string,
    body: any,
    principal?: ShieldPrincipal,
  ) {
    if (actionId === 'create-agent') {
      const firstName = (body.firstName ?? body.first_name ?? '').toString().trim();
      const lastName = (body.lastName ?? body.last_name ?? '').toString().trim();
      let employeeCode = (body.employeeCode ?? body.employee_code ?? '').toString().trim();
      const mobile = (body.mobile ?? '').toString().trim();
      const email = (body.email ?? '').toString().trim().toLowerCase();
      const departmentName = (body.department ?? 'Field Operations').toString().trim();
      const branchName = (body.branch ?? 'Sahakar Healthcare Group').toString().trim();
      const accessScope = (body.accessScope ?? body.access_scope ?? 'BRANCH_SCOPED').toString().trim();
      const status = (body.status ?? 'ACTIVE').toString().trim().toUpperCase();

      if (!firstName || !mobile || !email) {
        throw new BadRequestException('First Name, Mobile, and Email are required.');
      }

      const isAdmin = departmentName.toLowerCase().includes('admin');
      const resolvedUserType = isAdmin ? 'ADMIN' : 'SHIELD_AGENT';
      const resolvedAccessScope = isAdmin ? 'ORGANIZATION' : (accessScope || 'BRANCH_SCOPED');

      // Auto-generate the agent code if the form did not supply one (or if
      // the submitted value collides with an existing code — handles race conditions
      // where two agents are provisioned simultaneously from the same pre-generated code).
      if (!employeeCode) {
        employeeCode = await this.generateNextAgentCode();
      } else {
        // Verify the submitted code is not already taken.
        const codeInUse = await this.prisma.user.findFirst({
          where: { employeeCode, deletedAt: null },
        });
        if (codeInUse) {
          // Regenerate to avoid collision.
          employeeCode = await this.generateNextAgentCode();
        }
      }

      const existingUser = await this.prisma.user.findFirst({
        where: {
          OR: [{ mobile }, { email }],
          deletedAt: null,
        },
      });

      if (existingUser) {
        throw new BadRequestException('A user with this mobile or email already exists.');
      }

      // Resolve branch (only required for non-admin branch-scoped users)
      const branch = isAdmin
        ? null
        : await this.prisma.business.findFirst({
            where: {
              name: { contains: branchName, mode: 'insensitive' },
            },
          });

      // Resolve department
      let department = await this.prisma.department.findFirst({
        where: { name: { contains: departmentName, mode: 'insensitive' } },
      });

      if (!department) {
        department = await this.prisma.department.findFirst();
      }

      // Resolve role (ADMIN or AGENT)
      const role = await this.prisma.role.findFirst({
        where: { name: { contains: isAdmin ? 'ADMIN' : 'AGENT', mode: 'insensitive' } },
      });

      const newUser = await this.prisma.user.create({
        data: {
          uuid: crypto.randomUUID(),
          firstName,
          lastName,
          employeeCode,
          mobile,
          email,
          userType: resolvedUserType,
          accessScope: resolvedAccessScope,
          status: status || 'ACTIVE',
          branchBusinessId: branch?.id ?? null,
          departmentId: department?.id ?? null,
          roleId: role?.id ?? null,
        },
      });

      if (!isAdmin && branch?.id) {
        await this.prisma.agentBranchAssignment.create({
          data: {
            uuid: crypto.randomUUID(),
            userId: newUser.id,
            businessId: branch.id,
            status: 'APPROVED',
            isPrimary: true,
            approvedAt: new Date(),
          },
        }).catch(() => null);
      }

      return {
        message: `Agent ${firstName}${lastName ? ' ' + lastName : ''} provisioned with code ${employeeCode}. They can sign in via Google Sign-In using ${email}.`,
        agentId: newUser.id.toString(),
        uuid: newUser.uuid,
        employeeCode,
      };
    }

    throw new BadRequestException(`Unknown agent action: ${actionId}`);
  }

  async getCrmWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const selectedTab = (query.tab ?? 'Queues').trim();
    const [taskCount, activityCount, complaintCount, tasks, activities, complaints, customers] =
      await Promise.all([
        this.prisma.crmTask.count(),
        this.prisma.crmActivity.count(),
        this.prisma.complaint.count(),
        this.prisma.crmTask.findMany({
          orderBy: [{ dueDate: 'asc' }, { id: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true, status: true } },
            assignedToUser: { select: { firstName: true, lastName: true, employeeCode: true } },
          },
        }),
        this.prisma.crmActivity.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            createdByUser: { select: { firstName: true, lastName: true, employeeCode: true } },
          },
        }),
        this.prisma.complaint.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
          },
        }),
        this.prisma.customer.findMany({
          where: { deletedAt: null },
          orderBy: [{ updatedAt: 'desc' }],
          take: 50,
        }),
      ]);
    const queueRows = this.filterRowsBySearch(
      tasks.map((task) => ({
        dueDate: this.formatDateTime(task.dueDate),
        customer: this.resolveCustomerLabel(task.customer),
        assignee: this.resolveUserDisplayName(task.assignedToUser as any),
        status: task.status?.trim() || 'UNKNOWN',
        notes: task.notes?.trim() || 'N/A',
      })),
      query.search,
    );
    const activityRows = this.filterRowsBySearch(
      activities.map((activity) => ({
        createdAt: this.formatDateTime(activity.createdAt),
        customer: this.resolveCustomerLabel(activity.customer),
        type: activity.activityType?.trim() || 'ACTIVITY',
        actor: this.resolveUserDisplayName(activity.createdByUser as any),
        notes: activity.notes?.trim() || 'N/A',
      })),
      query.search,
    );
    const complaintRows = this.filterRowsBySearch(
      complaints.map((complaint) => ({
        createdAt: this.formatDateTime(complaint.createdAt),
        customer: this.resolveCustomerLabel(complaint.customer),
        type: complaint.complaintType?.trim() || 'COMPLAINT',
        status: complaint.status?.trim() || 'UNKNOWN',
        description: complaint.description?.trim() || 'N/A',
      })),
      query.search,
    );
    const customerRows = this.filterRowsBySearch(
      customers.map((customer) => ({
        customer: this.resolveCustomerLabel(customer),
        status: customer.status?.trim() || 'UNKNOWN',
        agent: customer.agentCode?.trim() || 'N/A',
        updatedAt: this.formatDateTime(customer.updatedAt),
      })),
      query.search,
    );
    const selectedRows =
      selectedTab == 'Activity'
        ? activityRows
        : selectedTab == 'Escalations'
          ? complaintRows
          : selectedTab == 'Customers'
            ? customerRows
            : queueRows;
    const selectedColumns =
      selectedTab == 'Activity'
        ? [
            { key: 'createdAt', label: 'Time' },
            { key: 'customer', label: 'Customer' },
            { key: 'type', label: 'Type' },
            { key: 'actor', label: 'Actor' },
            { key: 'notes', label: 'Notes' },
          ]
        : selectedTab == 'Escalations'
          ? [
              { key: 'createdAt', label: 'Created' },
              { key: 'customer', label: 'Customer' },
              { key: 'type', label: 'Complaint' },
              { key: 'status', label: 'Status' },
              { key: 'description', label: 'Description' },
            ]
          : selectedTab == 'Customers'
            ? [
                { key: 'customer', label: 'Customer' },
                { key: 'status', label: 'Status' },
                { key: 'agent', label: 'Agent code' },
                { key: 'updatedAt', label: 'Updated' },
              ]
            : [
                { key: 'dueDate', label: 'Due' },
                { key: 'customer', label: 'Customer' },
                { key: 'assignee', label: 'Assignee' },
                { key: 'status', label: 'Status' },
                { key: 'notes', label: 'Notes' },
              ];
    return this.buildWorkspacePayload(
      'crm',
      {
        eyebrow: 'Operations / CRM',
        title: 'CRM',
        description:
          'Backend-owned CRM queues, activities, escalations, and customer follow-up evidence.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Escalations',
      },
      {
        searchHint: 'Search CRM tasks, activities, complaints, and customers',
        tabs: ['Queues', 'Activity', 'Escalations', 'Customers'],
        filters: ['OPEN', 'PENDING', 'COMPLETED', 'CLOSED'],
      },
      [
        this.metric('Tasks', taskCount, 'crm_tasks rows'),
        this.metric('Activities', activityCount, 'crm_activities rows'),
        this.metric('Complaints', complaintCount, 'complaints rows'),
        this.metric('Open queue', queueRows.length, 'Current CRM tasks in result'),
      ],
      {
        left: {
          title: 'CRM workload signals',
          subtitle: 'Queue posture across tasks, activities, and escalations.',
          type: 'details',
          details: [
            { label: 'Selected tab', value: selectedTab },
            { label: 'Tasks', value: `${taskCount}` },
            { label: 'Activities', value: `${activityCount}` },
            { label: 'Complaints', value: `${complaintCount}` },
            {
              label: 'Search',
              value:
                (query.search?.trim().length ?? 0) > 0
                  ? query.search!.trim()
                  : 'No search applied',
            },
          ],
        },
        center: {
          title: selectedTab,
          subtitle: 'Current backend dataset for the selected CRM view.',
          type: 'table',
          columns: selectedColumns,
          rows: selectedRows,
          emptyState: {
            title: 'No CRM records matched this view',
            description: 'The CRM workspace is live, but the selected tab and filters returned no rows.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent CRM activity',
          subtitle: 'Latest recorded CRM activity items.',
          type: 'list',
          items: activityRows.slice(0, 8).map((row) => ({
            title: row['type'] ?? 'ACTIVITY',
            subtitle: row['customer'] ?? 'Customer',
            meta: row['actor'] ?? 'System',
            status: 'RECORDED',
          })),
          emptyState: {
            title: 'No CRM activity available',
            description: 'No CRM activity rows matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getVisitsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const selectedTab = (query.tab ?? 'Visits').trim();
    const [appointmentsCount, consultationsCount, purchasesCount, labReportsCount, dentalCount, visits, consultations, purchases, labReports, dentalRecords] =
      await Promise.all([
        this.prisma.appointment.count(),
        this.prisma.consultation.count(),
        this.prisma.purchase.count(),
        this.prisma.labReport.count(),
        this.prisma.dentalRecord.count(),
        this.prisma.appointment.findMany({
          orderBy: [{ appointmentDate: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            provider: { select: { providerName: true, providerType: true } },
          },
        }),
        this.prisma.consultation.findMany({
          orderBy: [{ id: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            appointment: { select: { appointmentDate: true, status: true } },
          },
        }),
        this.prisma.purchase.findMany({
          orderBy: [{ purchaseDate: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            provider: { select: { providerName: true, providerType: true } },
          },
        }),
        this.prisma.labReport.findMany({
          orderBy: [{ reportDate: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            appointment: { select: { appointmentDate: true, status: true } },
            document: { select: { status: true, fileName: true } },
          },
        }),
        this.prisma.dentalRecord.findMany({
          orderBy: [{ id: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            appointment: { select: { appointmentDate: true, status: true } },
          },
        }),
      ]);
    const visitRows = this.filterRowsBySearch(
      visits.map((visit) => ({
        date: this.formatDateTime(visit.appointmentDate),
        customer: this.resolveCustomerLabel(visit.customer),
        provider: visit.provider?.providerName?.trim() || 'Unassigned provider',
        type: visit.appointmentType?.trim() || 'GENERAL',
        status: visit.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const consultationRows = this.filterRowsBySearch(
      consultations.map((consultation) => ({
        customer: this.resolveCustomerLabel(consultation.customer),
        doctor: consultation.doctorName?.trim() || 'Unknown',
        diagnosis: consultation.diagnosis?.trim() || 'N/A',
        visitDate: this.formatDateTime(consultation.appointment?.appointmentDate),
        status: consultation.appointment?.status?.trim() || 'RECORDED',
      })),
      query.search,
    );
    const purchaseRows = this.filterRowsBySearch(
      purchases.map((purchase) => ({
        purchaseDate: this.formatDateTime(purchase.purchaseDate),
        customer: this.resolveCustomerLabel(purchase.customer),
        provider: purchase.provider?.providerName?.trim() || 'N/A',
        payable: this.formatMoney(purchase.payableAmount),
        status: purchase.paymentStatus?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const labRows = this.filterRowsBySearch(
      labReports.map((report) => ({
        reportDate: this.formatDateTime(report.reportDate),
        customer: this.resolveCustomerLabel(report.customer),
        visitDate: this.formatDateTime(report.appointment?.appointmentDate),
        document: report.document?.fileName?.trim() || 'No document',
        status: report.document?.status?.trim() || report.appointment?.status?.trim() || 'RECORDED',
      })),
      query.search,
    );
    const dentalRows = this.filterRowsBySearch(
      dentalRecords.map((record) => ({
        customer: this.resolveCustomerLabel(record.customer),
        treatment: record.treatmentName?.trim() || 'Treatment',
        visitDate: this.formatDateTime(record.appointment?.appointmentDate),
        status: record.appointment?.status?.trim() || 'RECORDED',
        notes: record.notes?.trim() || 'N/A',
      })),
      query.search,
    );
    const selectedRows =
      selectedTab == 'Consultations'
        ? consultationRows
        : selectedTab == 'Purchases'
          ? purchaseRows
          : selectedTab == 'Labs'
            ? labRows
            : selectedTab == 'Dental'
              ? dentalRows
              : visitRows;
    const selectedColumns =
      selectedTab == 'Consultations'
        ? [
            { key: 'customer', label: 'Customer' },
            { key: 'doctor', label: 'Doctor' },
            { key: 'diagnosis', label: 'Diagnosis' },
            { key: 'visitDate', label: 'Visit date' },
            { key: 'status', label: 'Status' },
          ]
        : selectedTab == 'Purchases'
          ? [
              { key: 'purchaseDate', label: 'Purchase date' },
              { key: 'customer', label: 'Customer' },
              { key: 'provider', label: 'Provider' },
              { key: 'payable', label: 'Payable' },
              { key: 'status', label: 'Payment' },
            ]
          : selectedTab == 'Labs'
            ? [
                { key: 'reportDate', label: 'Report date' },
                { key: 'customer', label: 'Customer' },
                { key: 'visitDate', label: 'Visit date' },
                { key: 'document', label: 'Document' },
                { key: 'status', label: 'Status' },
              ]
            : selectedTab == 'Dental'
              ? [
                  { key: 'customer', label: 'Customer' },
                  { key: 'treatment', label: 'Treatment' },
                  { key: 'visitDate', label: 'Visit date' },
                  { key: 'status', label: 'Status' },
                  { key: 'notes', label: 'Notes' },
                ]
              : [
                  { key: 'date', label: 'Visit date' },
                  { key: 'customer', label: 'Customer' },
                  { key: 'provider', label: 'Provider' },
                  { key: 'type', label: 'Type' },
                  { key: 'status', label: 'Status' },
                ];
    return this.buildWorkspacePayload(
      'visits',
      {
        eyebrow: 'Operations / Visits',
        title: 'Visits',
        description:
          'Backend-owned visit, consultation, purchase, lab, and dental activity across the care journey.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Consultations',
      },
      {
        searchHint: 'Search appointments, consultations, purchases, and records',
        tabs: ['Visits', 'Consultations', 'Purchases', 'Labs', 'Dental'],
        filters: ['SCHEDULED', 'COMPLETED', 'CANCELLED', 'PENDING'],
      },
      [
        this.metric('Appointments', appointmentsCount, 'appointments rows'),
        this.metric('Consultations', consultationsCount, 'consultations rows'),
        this.metric('Purchases', purchasesCount, 'purchases rows'),
        this.metric('Lab reports', labReportsCount + dentalCount, 'diagnostic and dental records'),
      ],
      {
        left: {
          title: 'Visit coverage',
          subtitle: 'Current workload composition across visit-linked tables.',
          type: 'details',
          details: [
            { label: 'Selected tab', value: selectedTab },
            { label: 'Appointments', value: `${appointmentsCount}` },
            { label: 'Consultations', value: `${consultationsCount}` },
            { label: 'Purchases', value: `${purchasesCount}` },
            { label: 'Diagnostics', value: `${labReportsCount + dentalCount}` },
          ],
        },
        center: {
          title: selectedTab,
          subtitle: 'Current visit dataset returned by the backend contract.',
          type: 'table',
          columns: selectedColumns,
          rows: selectedRows,
          emptyState: {
            title: 'No visit rows matched this view',
            description: 'The selected visit tab completed successfully but returned no rows for the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent purchases and records',
          subtitle: 'Cross-linked operational evidence from visit-linked entities.',
          type: 'list',
          items: purchaseRows.slice(0, 8).map((row) => ({
            title: row['customer'] ?? 'Customer',
            subtitle: row['provider'] ?? 'Provider',
            meta: row['payable'] ?? '0',
            status: row['status'] ?? 'UNKNOWN',
          })),
          emptyState: {
            title: 'No visit-linked activity',
            description: 'No purchase or downstream record rows matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getDocumentsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const selectedTab = (query.tab ?? 'Pending').trim();
    const statusFilter =
      selectedTab == 'Pending'
        ? { notIn: ['APPROVED', 'VALIDATED', 'REJECTED'] }
        : { equals: selectedTab.toUpperCase() };
    const [documentCount, documents, classifications, extractions, processingLogs] =
      await Promise.all([
        this.prisma.document.count(),
        this.prisma.document.findMany({
          where: {
            ...(selectedTab == 'Pending'
              ? { status: statusFilter as { notIn: string[] } }
              : { status: statusFilter as { equals: string } }),
          },
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            uploadedByUser: { select: { firstName: true, lastName: true, employeeCode: true } },
          },
        }),
        this.prisma.documentClassification.findMany({
          orderBy: [{ id: 'desc' }],
          take: 50,
          include: { document: { select: { fileName: true, status: true } } },
        }),
        this.prisma.documentExtraction.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: { document: { select: { fileName: true, status: true } } },
        }),
        this.prisma.documentProcessingLog.findMany({
          orderBy: [{ processedAt: 'desc' }, { id: 'desc' }],
          take: 50,
          include: { document: { select: { fileName: true, status: true } } },
        }),
      ]);
    const documentRows = this.filterRowsBySearch(
      documents.map((document) => ({
        createdAt: this.formatDateTime(document.createdAt),
        customer: this.resolveCustomerLabel(document.customer),
        fileName: document.fileName?.trim() || 'Document',
        type: document.documentType?.trim() || 'DOCUMENT',
        status: document.status?.trim() || 'UNKNOWN',
        uploadedBy: this.resolveUserDisplayName(
          (document as any).uploadedByUser,
        ),
      })),
      query.search,
    );
    const extractionRows = this.filterRowsBySearch(
      extractions.map((row) => ({
        createdAt: this.formatDateTime(row.createdAt),
        document: row.document?.fileName?.trim() || 'Document',
        status: row.extractionStatus?.trim() || 'UNKNOWN',
        confidence: this.formatDecimal(row.confidenceScore),
      })),
      query.search,
    );
    const processingRows = this.filterRowsBySearch(
      processingLogs.map((row) => ({
        processedAt: this.formatDateTime(row.processedAt),
        document: row.document?.fileName?.trim() || 'Document',
        stage: row.stage?.trim() || 'PROCESSING',
        status: row.status?.trim() || 'UNKNOWN',
        remarks: row.remarks?.trim() || 'N/A',
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'documents',
      {
        eyebrow: 'Operations / Documents',
        title: 'Documents',
        description:
          'Backend-owned document queue, extraction evidence, and processing lifecycle across stored uploads.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Approved',
      },
      {
        searchHint: 'Search documents, extracted files, and processing status',
        tabs: ['Pending', 'Approved', 'Rejected', 'Extractions', 'Processing'],
        filters: ['PENDING', 'APPROVED', 'REJECTED', 'VALIDATED'],
      },
      [
        this.metric('Documents', documentCount, 'documents rows'),
        this.metric('Classifications', classifications.length, 'document_classifications rows in current sample'),
        this.metric('Extractions', extractionRows.length, 'document_extractions rows in current sample'),
        this.metric('Processing logs', processingRows.length, 'document_processing_logs rows in current sample'),
      ],
      {
        left: {
          title: 'Verification posture',
          subtitle: 'Current document and pipeline coverage.',
          type: 'details',
          details: [
            { label: 'Selected tab', value: selectedTab },
            { label: 'Returned documents', value: `${documentRows.length}` },
            { label: 'Returned extractions', value: `${extractionRows.length}` },
            { label: 'Returned logs', value: `${processingRows.length}` },
            {
              label: 'Search',
              value:
                (query.search?.trim().length ?? 0) > 0
                  ? query.search!.trim()
                  : 'No search applied',
            },
          ],
        },
        center: {
          title: selectedTab,
          subtitle: 'Current backend dataset for the selected documents view.',
          type: 'table',
          columns:
            selectedTab == 'Extractions'
              ? [
                  { key: 'createdAt', label: 'Created' },
                  { key: 'document', label: 'Document' },
                  { key: 'status', label: 'Status' },
                  { key: 'confidence', label: 'Confidence' },
                ]
              : selectedTab == 'Processing'
                ? [
                    { key: 'processedAt', label: 'Processed' },
                    { key: 'document', label: 'Document' },
                    { key: 'stage', label: 'Stage' },
                    { key: 'status', label: 'Status' },
                    { key: 'remarks', label: 'Remarks' },
                  ]
                : [
                    { key: 'createdAt', label: 'Uploaded' },
                    { key: 'customer', label: 'Customer' },
                    { key: 'fileName', label: 'File' },
                    { key: 'type', label: 'Type' },
                    { key: 'status', label: 'Status' },
                    { key: 'uploadedBy', label: 'Uploaded by' },
                  ],
          rows:
            selectedTab == 'Extractions'
              ? extractionRows
              : selectedTab == 'Processing'
                ? processingRows
                : documentRows,
          emptyState: {
            title: 'No document rows matched this view',
            description: 'The selected document tab completed successfully but returned no rows for the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent classification labels',
          subtitle: 'Latest classification outputs attached to documents.',
          type: 'list',
          items: this.filterRowsBySearch(
            classifications.map((row) => ({
              title: row.classification?.trim() || 'Classification',
              subtitle: row.document?.fileName?.trim() || 'Document',
              meta: this.formatDecimal(row.confidence),
              status: row.document?.status?.trim() || 'RECORDED',
            })),
            query.search,
          ).slice(0, 10),
          emptyState: {
            title: 'No classification evidence',
            description: 'No document classification rows matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getMembershipsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const selectedTab = (query.tab ?? 'Plans').trim();
    const [planCount, membershipCount, cardCount, membershipTypes, memberships, cards, statusHistory] =
      await Promise.all([
        this.prisma.membershipType.count(),
        this.prisma.membership.count(),
        this.prisma.shieldCard.count(),
        this.prisma.membershipType.findMany({
          orderBy: [{ name: 'asc' }],
          take: 50,
        }),
        this.prisma.membership.findMany({
          orderBy: [{ updatedAt: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true, status: true } },
            membershipType: { select: { name: true, code: true } },
          },
        }),
        this.prisma.shieldCard.findMany({
          orderBy: [{ issuedAt: 'desc' }],
          take: 50,
          include: {
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
            issuedBusiness: { select: { name: true } },
          },
        }),
        this.prisma.customerStatusHistory.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: { customer: { select: { customerCode: true, firstName: true, lastName: true } } },
        }),
      ]);
    const planRows = this.filterRowsBySearch(
      membershipTypes.map((plan) => ({
        code: plan.code?.trim() || 'N/A',
        name: plan.name?.trim() || 'Plan',
        joiningFee: this.formatMoney(plan.joiningFee),
        discount: this.formatDecimal(plan.discountPercentage),
        status: plan.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const membershipRows = this.filterRowsBySearch(
      memberships.map((membership) => ({
        customer: this.resolveCustomerLabel(membership.customer),
        plan: membership.membershipType?.name?.trim() || membership.membershipType?.code?.trim() || 'Plan',
        number: membership.membershipNumber?.trim() || 'N/A',
        expiry: this.formatDateTime(membership.expiryDate),
        status: membership.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const cardRows = this.filterRowsBySearch(
      cards.map((card) => ({
        customer: this.resolveCustomerLabel(card.customer),
        card: card.cardNumber?.trim() || 'N/A',
        branch: card.issuedBusiness?.name?.trim() || 'Unassigned',
        issuedAt: this.formatDateTime(card.issuedAt),
        status: card.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const historyRows = this.filterRowsBySearch(
      statusHistory.map((history) => ({
        createdAt: this.formatDateTime(history.createdAt),
        customer: this.resolveCustomerLabel(history.customer),
        from: history.oldStatus?.trim() || 'N/A',
        to: history.newStatus?.trim() || 'N/A',
        remarks: history.remarks?.trim() || 'N/A',
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'memberships',
      {
        eyebrow: 'Business / Memberships',
        title: 'Memberships',
        description:
          'Backend-owned plan, active membership, card issuance, and lifecycle history workspace.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Renewals',
      },
      {
        searchHint: 'Search plans, memberships, cards, and lifecycle history',
        tabs: ['Plans', 'Renewals', 'Cards', 'History'],
        filters: ['ACTIVE', 'EXPIRED', 'PENDING', 'SUSPENDED'],
      },
      [
        this.metric('Plans', planCount, 'membership_types rows'),
        this.metric('Memberships', membershipCount, 'memberships rows'),
        this.metric('Cards', cardCount, 'shield_cards rows'),
        this.metric('Renewals', membershipRows.filter((row) => row['status'] == 'ACTIVE').length, 'Active memberships in current sample'),
      ],
      {
        left: {
          title: 'Membership posture',
          subtitle: 'Plan and card coverage from live records.',
          type: 'details',
          details: [
            { label: 'Selected tab', value: selectedTab },
            { label: 'Plans', value: `${planCount}` },
            { label: 'Memberships', value: `${membershipCount}` },
            { label: 'Cards', value: `${cardCount}` },
            { label: 'History rows', value: `${historyRows.length}` },
          ],
        },
        center: {
          title: selectedTab,
          subtitle: 'Current backend dataset for the selected memberships view.',
          type: 'table',
          columns:
            selectedTab == 'Cards'
              ? [
                  { key: 'customer', label: 'Customer' },
                  { key: 'card', label: 'Card' },
                  { key: 'branch', label: 'Issued branch' },
                  { key: 'issuedAt', label: 'Issued' },
                  { key: 'status', label: 'Status' },
                ]
              : selectedTab == 'History'
                ? [
                    { key: 'createdAt', label: 'Created' },
                    { key: 'customer', label: 'Customer' },
                    { key: 'from', label: 'From' },
                    { key: 'to', label: 'To' },
                    { key: 'remarks', label: 'Remarks' },
                  ]
                : selectedTab == 'Renewals'
                  ? [
                      { key: 'customer', label: 'Customer' },
                      { key: 'plan', label: 'Plan' },
                      { key: 'number', label: 'Membership no.' },
                      { key: 'expiry', label: 'Expiry' },
                      { key: 'status', label: 'Status' },
                    ]
                  : [
                      { key: 'code', label: 'Code' },
                      { key: 'name', label: 'Plan' },
                      { key: 'joiningFee', label: 'Joining fee' },
                      { key: 'discount', label: 'Discount' },
                      { key: 'status', label: 'Status' },
                    ],
          rows:
            selectedTab == 'Cards'
              ? cardRows
              : selectedTab == 'History'
                ? historyRows
                : selectedTab == 'Renewals'
                  ? membershipRows
                  : planRows,
          emptyState: {
            title: 'No membership rows matched this view',
            description: 'The selected membership tab completed successfully but returned no rows for the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Active memberships',
          subtitle: 'Current live memberships in scope.',
          type: 'list',
          items: membershipRows.slice(0, 10).map((row) => ({
            title: row['customer'] ?? 'Customer',
            subtitle: row['plan'] ?? 'Plan',
            meta: row['expiry'] ?? 'N/A',
            status: row['status'] ?? 'UNKNOWN',
          })),
          emptyState: {
            title: 'No active memberships',
            description: 'No membership rows matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getWalletWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const selectedTab = (query.tab ?? 'Ledger').trim();
    const [walletCount, walletTxCount, pricingAuditCount, rewardTxCount, wallets, walletTransactions, pricingAudits, rewardTransactions] =
      await Promise.all([
        this.prisma.wallet.count(),
        this.prisma.walletTransaction.count(),
        this.prisma.pricingRuleAudit.count(),
        this.prisma.rewardPointTransaction.count(),
        this.prisma.wallet.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: { customer: { select: { customerCode: true, firstName: true, lastName: true, status: true } } },
        }),
        this.prisma.walletTransaction.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: {
            wallet: { include: { customer: { select: { customerCode: true, firstName: true, lastName: true } } } },
            createdByUser: { select: { firstName: true, lastName: true, employeeCode: true } },
          },
        }),
        this.prisma.pricingRuleAudit.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: { customer: { select: { customerCode: true, firstName: true, lastName: true } } },
        }),
        this.prisma.rewardPointTransaction.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: { wallet: { include: { customer: { select: { customerCode: true, firstName: true, lastName: true } } } } },
        }),
      ]);
    const walletRows = this.filterRowsBySearch(
      wallets.map((wallet) => ({
        customer: this.resolveCustomerLabel(wallet.customer),
        walletStatus: wallet.status?.trim() || 'UNKNOWN',
        createdAt: this.formatDateTime(wallet.createdAt),
      })),
      query.search,
    );
    const ledgerRows = this.filterRowsBySearch(
      walletTransactions.map((tx) => ({
        createdAt: this.formatDateTime(tx.createdAt),
        customer: this.resolveCustomerLabel(tx.wallet?.customer),
        subLedger: tx.subLedgerType?.trim() || 'CASH',
        amount: this.formatMoney(tx.amount),
        type: tx.transactionType?.trim() || 'TRANSACTION',
        actor: this.resolveUserDisplayName(tx.createdByUser),
      })),
      query.search,
    );
    const pricingRows = this.filterRowsBySearch(
      pricingAudits.map((audit) => ({
        createdAt: this.formatDateTime(audit.createdAt),
        customer: this.resolveCustomerLabel(audit.customer),
        service: audit.serviceType,
        finalPayable: this.formatMoney(audit.finalPayableAmount),
        rule: audit.matchedRuleCode?.trim() || 'N/A',
      })),
      query.search,
    );
    const rewardRows = this.filterRowsBySearch(
      rewardTransactions.map((tx) => ({
        createdAt: this.formatDateTime(tx.createdAt),
        customer: this.resolveCustomerLabel(tx.wallet?.customer),
        action: tx.actionCode?.trim() || 'REWARD',
        points: this.formatMoney(tx.points),
        status: tx.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'wallet',
      {
        eyebrow: 'Business / Wallet',
        title: 'Wallet',
        description:
          'Backend-owned wallet ledger, reward movement, and pricing audit evidence across all customer wallets.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Rewards',
      },
      {
        searchHint: 'Search wallets, ledger transactions, rewards, and pricing audits',
        tabs: ['Ledger', 'Wallets', 'Rewards', 'Audits'],
        filters: ['CASH', 'REWARD_POINTS', 'SHIELD_BENEFIT', 'ACTIVE'],
      },
      [
        this.metric('Wallets', walletCount, 'wallets rows'),
        this.metric('Ledger rows', walletTxCount, 'wallet_transactions rows'),
        this.metric('Pricing audits', pricingAuditCount, 'pricing_rule_audits rows'),
        this.metric('Reward rows', rewardTxCount, 'reward_point_transactions rows'),
      ],
      {
        left: {
          title: 'Wallet posture',
          subtitle: 'Ledger and wallet coverage from live records.',
          type: 'details',
          details: [
            { label: 'Selected tab', value: selectedTab },
            { label: 'Wallets', value: `${walletCount}` },
            { label: 'Ledger rows', value: `${walletTxCount}` },
            { label: 'Pricing audits', value: `${pricingAuditCount}` },
            { label: 'Reward rows', value: `${rewardTxCount}` },
          ],
        },
        center: {
          title: selectedTab,
          subtitle: 'Current backend dataset for the selected wallet view.',
          type: 'table',
          columns:
            selectedTab == 'Wallets'
              ? [
                  { key: 'customer', label: 'Customer' },
                  { key: 'walletStatus', label: 'Status' },
                  { key: 'createdAt', label: 'Created' },
                ]
              : selectedTab == 'Rewards'
                ? [
                    { key: 'createdAt', label: 'Created' },
                    { key: 'customer', label: 'Customer' },
                    { key: 'action', label: 'Action' },
                    { key: 'points', label: 'Points' },
                    { key: 'status', label: 'Status' },
                  ]
                : selectedTab == 'Audits'
                  ? [
                      { key: 'createdAt', label: 'Created' },
                      { key: 'customer', label: 'Customer' },
                      { key: 'service', label: 'Service' },
                      { key: 'finalPayable', label: 'Final payable' },
                      { key: 'rule', label: 'Rule' },
                    ]
                  : [
                      { key: 'createdAt', label: 'Created' },
                      { key: 'customer', label: 'Customer' },
                      { key: 'subLedger', label: 'Sub-ledger' },
                      { key: 'amount', label: 'Amount' },
                      { key: 'type', label: 'Type' },
                      { key: 'actor', label: 'Actor' },
                    ],
          rows:
            selectedTab == 'Wallets'
              ? walletRows
              : selectedTab == 'Rewards'
                ? rewardRows
                : selectedTab == 'Audits'
                  ? pricingRows
                  : ledgerRows,
          emptyState: {
            title: 'No wallet rows matched this view',
            description: 'The selected wallet tab completed successfully but returned no rows for the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent ledger trail',
          subtitle: 'Latest wallet transaction evidence.',
          type: 'list',
          items: ledgerRows.slice(0, 10).map((row) => ({
            title: row['customer'] ?? 'Customer',
            subtitle: row['subLedger'] ?? 'CASH',
            meta: row['amount'] ?? '0',
            status: row['type'] ?? 'TRANSACTION',
          })),
          emptyState: {
            title: 'No ledger trail',
            description: 'No wallet transaction rows matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getRewardsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const selectedTab = (query.tab ?? 'Rules').trim();
    const [ruleCount, redemptionCount, txCount, referralCount, pointRules, redemptionRules, pointTx, referralEvents] =
      await Promise.all([
        this.prisma.rewardPointRule.count(),
        this.prisma.rewardRedemptionRule.count(),
        this.prisma.rewardPointTransaction.count(),
        this.prisma.referralRewardEvent.count(),
        this.prisma.rewardPointRule.findMany({ orderBy: [{ updatedAt: 'desc' }], take: 50 }),
        this.prisma.rewardRedemptionRule.findMany({ orderBy: [{ updatedAt: 'desc' }], take: 50 }),
        this.prisma.rewardPointTransaction.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: { wallet: { include: { customer: { select: { customerCode: true, firstName: true, lastName: true } } } } },
        }),
        this.prisma.referralRewardEvent.findMany({
          orderBy: [{ createdAt: 'desc' }],
          take: 50,
          include: {
            referrerCustomer: { select: { customerCode: true, firstName: true, lastName: true } },
            referredCustomer: { select: { customerCode: true, firstName: true, lastName: true } },
          },
        }),
      ]);
    const rulesRows = this.filterRowsBySearch(
      pointRules.map((rule) => ({
        action: rule.actionCode,
        displayName: rule.displayName,
        points: this.formatMoney(rule.points),
        approval: rule.requiresApproval ? 'REQUIRES_APPROVAL' : 'AUTO',
        status: rule.status,
      })),
      query.search,
    );
    const redemptionRows = this.filterRowsBySearch(
      redemptionRules.map((rule) => ({
        code: rule.code,
        pointsRequired: this.formatMoney(rule.pointsRequired),
        cashCredit: this.formatMoney(rule.cashCreditAmount),
        ledger: rule.creditLedgerType,
        status: rule.status,
      })),
      query.search,
    );
    const txRows = this.filterRowsBySearch(
      pointTx.map((tx) => ({
        createdAt: this.formatDateTime(tx.createdAt),
        customer: this.resolveCustomerLabel(tx.wallet?.customer),
        action: tx.actionCode?.trim() || 'REWARD',
        points: this.formatMoney(tx.points),
        status: tx.status,
      })),
      query.search,
    );
    const referralRows = this.filterRowsBySearch(
      referralEvents.map((event) => ({
        createdAt: this.formatDateTime(event.createdAt),
        referrer: this.resolveCustomerLabel(event.referrerCustomer),
        referred: this.resolveCustomerLabel(event.referredCustomer),
        points: this.formatMoney(event.rewardPoints),
        status: event.status,
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'rewards',
      {
        eyebrow: 'Business / Rewards',
        title: 'Rewards',
        description:
          'Backend-owned reward rules, redemption rules, reward transactions, and referral reward evidence.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Transactions',
      },
      {
        searchHint: 'Search reward rules, redemptions, transactions, and referral rewards',
        tabs: ['Rules', 'Redemptions', 'Transactions', 'Referrals'],
        filters: ['ACTIVE', 'APPROVED', 'PENDING', 'REJECTED'],
      },
      [
        this.metric('Reward rules', ruleCount, 'reward_point_rules rows'),
        this.metric('Redemption rules', redemptionCount, 'reward_redemption_rules rows'),
        this.metric('Reward rows', txCount, 'reward_point_transactions rows'),
        this.metric('Referral rewards', referralCount, 'referral_reward_events rows'),
      ],
      {
        left: {
          title: 'Rewards posture',
          subtitle: 'Rules and transactions from live rewards tables.',
          type: 'details',
          details: [
            { label: 'Selected tab', value: selectedTab },
            { label: 'Rules', value: `${ruleCount}` },
            { label: 'Redemptions', value: `${redemptionCount}` },
            { label: 'Transactions', value: `${txCount}` },
            { label: 'Referrals', value: `${referralCount}` },
          ],
        },
        center: {
          title: selectedTab,
          subtitle: 'Current backend dataset for the selected rewards view.',
          type: 'table',
          columns:
            selectedTab == 'Redemptions'
              ? [
                  { key: 'code', label: 'Code' },
                  { key: 'pointsRequired', label: 'Points required' },
                  { key: 'cashCredit', label: 'Cash credit' },
                  { key: 'ledger', label: 'Ledger' },
                  { key: 'status', label: 'Status' },
                ]
              : selectedTab == 'Transactions'
                ? [
                    { key: 'createdAt', label: 'Created' },
                    { key: 'customer', label: 'Customer' },
                    { key: 'action', label: 'Action' },
                    { key: 'points', label: 'Points' },
                    { key: 'status', label: 'Status' },
                  ]
                : selectedTab == 'Referrals'
                  ? [
                      { key: 'createdAt', label: 'Created' },
                      { key: 'referrer', label: 'Referrer' },
                      { key: 'referred', label: 'Referred' },
                      { key: 'points', label: 'Points' },
                      { key: 'status', label: 'Status' },
                    ]
                  : [
                      { key: 'action', label: 'Action code' },
                      { key: 'displayName', label: 'Display name' },
                      { key: 'points', label: 'Points' },
                      { key: 'approval', label: 'Approval' },
                      { key: 'status', label: 'Status' },
                    ],
          rows:
            selectedTab == 'Redemptions'
              ? redemptionRows
              : selectedTab == 'Transactions'
                ? txRows
                : selectedTab == 'Referrals'
                  ? referralRows
                  : rulesRows,
          emptyState: {
            title: 'No reward rows matched this view',
            description: 'The selected rewards tab completed successfully but returned no rows for the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent referral rewards',
          subtitle: 'Latest referral reward events in scope.',
          type: 'list',
          items: referralRows.slice(0, 10).map((row) => ({
            title: row['referrer'] ?? 'Referrer',
            subtitle: row['referred'] ?? 'Referred',
            meta: row['points'] ?? '0',
            status: row['status'] ?? 'UNKNOWN',
          })),
          emptyState: {
            title: 'No referral reward events',
            description: 'No referral reward events matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getReferralsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const referrals = await this.prisma.referralRewardEvent.findMany({
      orderBy: [{ createdAt: 'desc' }],
      take: 50,
      include: {
        referrerCustomer: { select: { customerCode: true, firstName: true, lastName: true } },
        referredCustomer: { select: { customerCode: true, firstName: true, lastName: true, status: true } },
      },
    });
    const referralRows = this.filterRowsBySearch(
      referrals.map((event) => ({
        createdAt: this.formatDateTime(event.createdAt),
        referrer: this.resolveCustomerLabel(event.referrerCustomer),
        referred: this.resolveCustomerLabel(event.referredCustomer),
        code: event.referralCode?.trim() || 'N/A',
        status: event.status,
        points: this.formatMoney(event.rewardPoints),
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'referrals',
      {
        eyebrow: 'Business / Referrals',
        title: 'Referrals',
        description:
          'Backend-owned referral tree and reward qualification evidence from referral reward events and customer records.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Qualified',
      },
      {
        searchHint: 'Search referrers, referred customers, codes, and reward status',
        tabs: ['Pipeline', 'Qualified', 'Rewarded', 'Rejected'],
        filters: ['PENDING', 'VERIFIED', 'QUALIFIED', 'REWARDED', 'REJECTED'],
      },
      [
        this.metric('Referral events', referralRows.length, 'Current referral_reward_events result size'),
        this.metric('Qualified', referralRows.filter((row) => row['status'] == 'QUALIFIED').length, 'Qualified referrals in result'),
        this.metric('Rewarded', referralRows.filter((row) => row['status'] == 'REWARDED').length, 'Rewarded referrals in result'),
        this.metric('Rejected', referralRows.filter((row) => row['status'] == 'REJECTED').length, 'Rejected referrals in result'),
      ],
      {
        left: {
          title: 'Referral status breakdown',
          subtitle: 'Live referral progression from the rewards pipeline.',
          type: 'list',
          items: this.buildStatusSummaryItems(referralRows, 'status'),
        },
        center: {
          title: 'Referral pipeline',
          subtitle: 'Current backend dataset for referral qualification and reward status.',
          type: 'table',
          columns: [
            { key: 'createdAt', label: 'Created' },
            { key: 'referrer', label: 'Referrer' },
            { key: 'referred', label: 'Referred' },
            { key: 'code', label: 'Code' },
            { key: 'status', label: 'Status' },
            { key: 'points', label: 'Points' },
          ],
          rows: this.filterRowsByRequestedStatus(referralRows, query.status),
          emptyState: {
            title: 'No referral rows matched this view',
            description: 'The referrals workspace is live, but the current filters returned no rows.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent referral trail',
          subtitle: 'Most recent referral events in scope.',
          type: 'list',
          items: referralRows.slice(0, 10).map((row) => ({
            title: row['referrer'] ?? 'Referrer',
            subtitle: row['referred'] ?? 'Referred',
            meta: row['code'] ?? 'N/A',
            status: row['status'] ?? 'UNKNOWN',
          })),
          emptyState: {
            title: 'No referral trail',
            description: 'No referral events matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getProvidersWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const selectedTab = (query.tab ?? 'Profile').trim();
    const [providerCount, profileCount, assignmentCount, providers, profiles, assignments, appointments] =
      await Promise.all([
        this.prisma.serviceProvider.count(),
        this.prisma.providerProfile.count({ where: { deletedAt: null } }),
        this.prisma.providerProfileBranchAssignment.count(),
        this.prisma.serviceProvider.findMany({
          orderBy: [{ providerName: 'asc' }],
          take: 50,
          include: { business: { select: { name: true } } },
        }),
        this.prisma.providerProfile.findMany({
          where: { deletedAt: null },
          orderBy: [{ updatedAt: 'desc' }],
          take: 50,
          include: {
            user: { select: { firstName: true, lastName: true, email: true, status: true } },
          },
        }),
        this.prisma.providerProfileBranchAssignment.findMany({
          orderBy: [{ assignedAt: 'desc' }],
          take: 50,
          include: {
            providerProfile: {
              include: { user: { select: { firstName: true, lastName: true } } },
            },
            business: { select: { name: true } },
          },
        }),
        this.prisma.appointment.findMany({
          orderBy: [{ appointmentDate: 'desc' }],
          take: 50,
          include: {
            provider: { select: { providerName: true, providerType: true } },
            customer: { select: { customerCode: true, firstName: true, lastName: true } },
          },
        }),
      ]);
    const providerRows = this.filterRowsBySearch(
      providers.map((provider) => ({
        provider: provider.providerName?.trim() || 'Provider',
        type: provider.providerType?.trim() || 'GENERAL',
        branch: provider.business?.name?.trim() || 'Unassigned',
        status: provider.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const profileRows = this.filterRowsBySearch(
      profiles.map((profile) => ({
        profile:
          profile.displayName?.trim() ||
          this.resolveUserDisplayName(profile.user as any),
        specialization: profile.specialization?.trim() || 'N/A',
        contact: profile.contactPhone?.trim() || profile.contactEmail?.trim() || 'N/A',
        status: (profile.user as any)?.status?.trim() || 'UNKNOWN',
        updatedAt: this.formatDateTime(profile.updatedAt),
      })),
      query.search,
    );
    const assignmentRows = this.filterRowsBySearch(
      assignments.map((assignment) => ({
        profile:
          assignment.providerProfile.displayName?.trim() ||
          this.resolveUserDisplayName(
            (assignment.providerProfile as any).user,
          ),
        branch: assignment.business.name?.trim() || 'Branch',
        primary: assignment.isPrimary ? 'PRIMARY' : 'SECONDARY',
        assignedAt: this.formatDateTime(assignment.assignedAt),
      })),
      query.search,
    );
    const bookingRows = this.filterRowsBySearch(
      appointments.map((appointment) => ({
        date: this.formatDateTime(appointment.appointmentDate),
        provider: appointment.provider?.providerName?.trim() || 'Provider',
        customer: this.resolveCustomerLabel(appointment.customer),
        type: appointment.appointmentType?.trim() || 'GENERAL',
        status: appointment.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'providers',
      {
        eyebrow: 'Providers / Network',
        title: 'Providers',
        description:
          'Backend-owned provider registry, profile, branch assignment, and booking visibility.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Bookings',
      },
      {
        searchHint: 'Search provider registry, profiles, assignments, and bookings',
        tabs: ['Profile', 'Availability', 'Bookings', 'Assignments'],
        filters: ['ACTIVE', 'PENDING', 'INACTIVE'],
      },
      [
        this.metric('Providers', providerCount, 'service_providers rows'),
        this.metric('Profiles', profileCount, 'provider_profiles rows'),
        this.metric('Assignments', assignmentCount, 'provider_profile_branch_assignments rows'),
        this.metric('Bookings', bookingRows.length, 'Current appointment sample'),
      ],
      {
        left: {
          title: 'Provider registry',
          subtitle: 'Branch-linked provider entities.',
          type: 'list',
          items: providerRows.slice(0, 10).map((row) => ({
            title: row['provider'] ?? 'Provider',
            subtitle: `${row['type'] ?? 'GENERAL'} • ${row['branch'] ?? 'Unassigned'}`,
            meta: row['status'] ?? 'UNKNOWN',
            status: row['status'] ?? 'UNKNOWN',
          })),
          emptyState: {
            title: 'No providers matched this search',
            description: 'No provider rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        center: {
          title: selectedTab,
          subtitle: 'Current backend dataset for the selected providers view.',
          type: 'table',
          columns:
            selectedTab == 'Assignments'
              ? [
                  { key: 'profile', label: 'Profile' },
                  { key: 'branch', label: 'Branch' },
                  { key: 'primary', label: 'Mapping' },
                  { key: 'assignedAt', label: 'Assigned' },
                ]
              : selectedTab == 'Bookings'
                ? [
                    { key: 'date', label: 'Date' },
                    { key: 'provider', label: 'Provider' },
                    { key: 'customer', label: 'Customer' },
                    { key: 'type', label: 'Type' },
                    { key: 'status', label: 'Status' },
                  ]
                : [
                    { key: 'profile', label: 'Profile' },
                    { key: 'specialization', label: 'Specialization' },
                    { key: 'contact', label: 'Contact' },
                    { key: 'status', label: 'Status' },
                    { key: 'updatedAt', label: 'Updated' },
                  ],
          rows:
            selectedTab == 'Assignments'
              ? assignmentRows
              : selectedTab == 'Bookings'
                ? bookingRows
                : profileRows,
          emptyState: {
            title: 'No provider rows matched this view',
            description: 'The selected providers tab completed successfully but returned no rows.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent bookings',
          subtitle: 'Latest appointment evidence tied to providers.',
          type: 'list',
          items: bookingRows.slice(0, 10).map((row) => ({
            title: row['provider'] ?? 'Provider',
            subtitle: row['customer'] ?? 'Customer',
            meta: row['date'] ?? 'N/A',
            status: row['status'] ?? 'UNKNOWN',
          })),
          emptyState: {
            title: 'No provider booking trail',
            description: 'No provider booking rows matched the current search.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getServicesWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const [serviceProviderTypes, serviceRules, pricingAudits] = await Promise.all([
      this.prisma.serviceProvider.findMany({
        orderBy: [{ providerType: 'asc' }],
        take: 100,
      }),
      this.prisma.serviceBenefitRule.findMany({
        orderBy: [{ updatedAt: 'desc' }],
        take: 50,
      }),
      this.prisma.pricingRuleAudit.findMany({
        orderBy: [{ createdAt: 'desc' }],
        take: 50,
      }),
    ]);
    const typeCounts = new Map<string, number>();
    for (const provider of serviceProviderTypes) {
      const type = provider.providerType?.trim() || 'GENERAL';
      typeCounts.set(type, (typeCounts.get(type) ?? 0) + 1);
    }
    const serviceRows = this.filterRowsBySearch(
      serviceRules.map((rule) => ({
        serviceType: rule.serviceType,
        benefitEligible: rule.isBenefitEligible ? 'YES' : 'NO',
        rewardPoints: this.formatMoney(rule.rewardPointsOnService),
        walletsAllowed: rule.walletsAllowed?.trim() || 'CASH',
        status: rule.status,
      })),
      query.search,
    );
    const typeRows = this.filterRowsBySearch(
      Array.from(typeCounts.entries()).map(([serviceType, count]) => ({
        serviceType,
        providers: `${count}`,
        status: 'ACTIVE',
      })),
      query.search,
    );
    const auditRows = this.filterRowsBySearch(
      pricingAudits.map((audit) => ({
        createdAt: this.formatDateTime(audit.createdAt),
        serviceType: audit.serviceType,
        matchedRule: audit.matchedRuleCode?.trim() || 'N/A',
        finalPayable: this.formatMoney(audit.finalPayableAmount),
        status: audit.preloadingUsed ? 'PRELOADED' : 'STANDARD',
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'services',
      {
        eyebrow: 'Providers / Services',
        title: 'Services',
        description:
          'Backend-owned service types, benefit eligibility rules, and pricing outcomes.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Rules',
      },
      {
        searchHint: 'Search service types, benefit rules, and pricing outcomes',
        tabs: ['Catalog', 'Rules', 'Pricing audits'],
        filters: ['ACTIVE', 'INACTIVE', 'YES', 'NO'],
      },
      [
        this.metric('Service types', typeRows.length, 'Distinct provider types in current sample'),
        this.metric('Service rules', serviceRows.length, 'service_benefit_rules rows in current sample'),
        this.metric('Pricing audits', auditRows.length, 'pricing_rule_audits rows in current sample'),
      ],
      {
        left: {
          title: 'Service catalog',
          subtitle: 'Distinct provider service types and counts.',
          type: 'table',
          columns: [
            { key: 'serviceType', label: 'Service type' },
            { key: 'providers', label: 'Providers' },
            { key: 'status', label: 'Status' },
          ],
          rows: typeRows,
        },
        center: {
          title: 'Benefit rules',
          subtitle: 'Current benefit-rule coverage across service types.',
          type: 'table',
          columns: [
            { key: 'serviceType', label: 'Service type' },
            { key: 'benefitEligible', label: 'Benefit eligible' },
            { key: 'rewardPoints', label: 'Reward points' },
            { key: 'walletsAllowed', label: 'Wallets allowed' },
            { key: 'status', label: 'Status' },
          ],
          rows: serviceRows,
          emptyState: {
            title: 'No service rules matched this search',
            description: 'No service benefit rules matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Recent pricing outcomes',
          subtitle: 'Latest pricing rule audits tied to service types.',
          type: 'table',
          columns: [
            { key: 'createdAt', label: 'Created' },
            { key: 'serviceType', label: 'Service type' },
            { key: 'matchedRule', label: 'Matched rule' },
            { key: 'finalPayable', label: 'Final payable' },
            { key: 'status', label: 'Mode' },
          ],
          rows: auditRows,
          emptyState: {
            title: 'No pricing audits matched this search',
            description: 'No pricing rule audits matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getAvailabilityWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const [profiles, upcomingAppointments, businesses] = await Promise.all([
      this.prisma.providerProfile.findMany({
        where: { deletedAt: null },
        orderBy: [{ updatedAt: 'desc' }],
        take: 50,
        include: {
          user: { select: { firstName: true, lastName: true, status: true } },
          branchAssignments: { include: { business: { select: { name: true } } } },
        },
      }),
      this.prisma.appointment.findMany({
        orderBy: [{ appointmentDate: 'asc' }],
        take: 50,
        include: { provider: { select: { providerName: true, providerType: true } } },
      }),
      this.prisma.business.findMany({
        orderBy: [{ updatedAt: 'desc' }],
        take: 25,
      }),
    ]);
    const profileRows = this.filterRowsBySearch(
      profiles.map((profile) => ({
        provider:
          profile.displayName?.trim() ||
          this.resolveUserDisplayName(profile.user as any),
        specialization: profile.specialization?.trim() || 'N/A',
        branches: `${profile.branchAssignments.length}`,
        status: (profile.user as any)?.status?.trim() || 'UNKNOWN',
        updatedAt: this.formatDateTime(profile.updatedAt),
      })),
      query.search,
    );
    const bookingRows = this.filterRowsBySearch(
      upcomingAppointments.map((appointment) => ({
        date: this.formatDateTime(appointment.appointmentDate),
        provider: appointment.provider?.providerName?.trim() || 'Provider',
        type: appointment.provider?.providerType?.trim() || appointment.appointmentType?.trim() || 'GENERAL',
        status: appointment.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const branchRows = this.filterRowsBySearch(
      businesses.map((business) => ({
        branch: business.name,
        status: business.status?.trim() || 'UNKNOWN',
        updatedAt: this.formatDateTime(business.updatedAt),
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'availability',
      {
        eyebrow: 'Providers / Availability',
        title: 'Availability',
        description:
          'Backend-owned provider profile availability and booking pressure across active branches.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Bookings',
      },
      {
        searchHint: 'Search provider availability, bookings, and branch load',
        tabs: ['Profiles', 'Bookings', 'Branches'],
        filters: ['ACTIVE', 'PENDING', 'INACTIVE'],
      },
      [
        this.metric('Provider profiles', profileRows.length, 'Current provider profile sample'),
        this.metric('Upcoming bookings', bookingRows.length, 'Current appointment sample'),
        this.metric('Branches', branchRows.length, 'Current business sample'),
      ],
      {
        left: {
          title: 'Provider availability profiles',
          subtitle: 'Current provider profile coverage and branch mappings.',
          type: 'table',
          columns: [
            { key: 'provider', label: 'Provider' },
            { key: 'specialization', label: 'Specialization' },
            { key: 'branches', label: 'Branches' },
            { key: 'status', label: 'Status' },
            { key: 'updatedAt', label: 'Updated' },
          ],
          rows: profileRows,
          emptyState: {
            title: 'No provider profiles matched this search',
            description: 'No provider profile rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        center: {
          title: 'Upcoming bookings',
          subtitle: 'Booking demand that currently consumes provider availability.',
          type: 'table',
          columns: [
            { key: 'date', label: 'Date' },
            { key: 'provider', label: 'Provider' },
            { key: 'type', label: 'Type' },
            { key: 'status', label: 'Status' },
          ],
          rows: bookingRows,
          emptyState: {
            title: 'No bookings matched this search',
            description: 'No appointment rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Branch load context',
          subtitle: 'Current branches linked to provider availability coverage.',
          type: 'table',
          columns: [
            { key: 'branch', label: 'Branch' },
            { key: 'status', label: 'Status' },
            { key: 'updatedAt', label: 'Updated' },
          ],
          rows: branchRows,
          emptyState: {
            title: 'No branches matched this search',
            description: 'No branch rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getBranchesWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const [businesses, users, providers, customers, purchases] = await Promise.all([
      this.prisma.business.findMany({
        orderBy: [{ updatedAt: 'desc' }],
        take: 50,
      }),
      this.prisma.user.findMany({
        where: { deletedAt: null, branchBusinessId: { not: null } },
        orderBy: [{ updatedAt: 'desc' }],
        take: 100,
      }),
      this.prisma.serviceProvider.findMany({
        orderBy: [{ providerName: 'asc' }],
        take: 100,
      }),
      this.prisma.customer.findMany({
        where: { deletedAt: null },
        orderBy: [{ updatedAt: 'desc' }],
        take: 100,
      }),
      this.prisma.purchase.findMany({
        orderBy: [{ purchaseDate: 'desc' }],
        take: 100,
        include: { provider: { select: { businessId: true } } },
      }),
    ]);
    const branchRows = this.filterRowsBySearch(
      businesses.map((business) => {
        const employeeCount = users.filter(
          (user) => `${user.branchBusinessId ?? ''}` == `${business.id}`,
        ).length;
        const providerCount = providers.filter(
          (provider) => `${provider.businessId ?? ''}` == `${business.id}`,
        ).length;
        const revenue = purchases
          .filter((purchase) => `${purchase.provider?.businessId ?? ''}` == `${business.id}`)
          .reduce((sum, purchase) => sum + Number(purchase.payableAmount ?? 0), 0);
        return {
          branch: business.name,
          employees: `${employeeCount}`,
          providers: `${providerCount}`,
          customers: `${customers.length}`,
          revenue: this.formatMoneyValue(revenue),
          status: business.status?.trim() || 'UNKNOWN',
        };
      }),
      query.search,
    );
    return this.buildWorkspacePayload(
      'branches',
      {
        eyebrow: 'Organization / Branches',
        title: 'Branches',
        description:
          'Backend-owned branch profile, staffing, provider mapping, and purchase-linked revenue signals.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Performance',
      },
      {
        searchHint: 'Search branch name, staffing, provider coverage, and revenue',
        tabs: ['Overview', 'Performance', 'Employees', 'Providers', 'Reports'],
        filters: ['ACTIVE', 'INACTIVE'],
      },
      [
        this.metric('Branches', branchRows.length, 'Current business rows in result'),
        this.metric('Employees', users.length, 'Branch-scoped users in sample'),
        this.metric('Providers', providers.length, 'Providers in sample'),
        this.metric('Purchases', purchases.length, 'Purchase rows in sample'),
      ],
      {
        left: {
          title: 'Branch registry',
          subtitle: 'Live business entities in the branch scope.',
          type: 'table',
          columns: [
            { key: 'branch', label: 'Branch' },
            { key: 'employees', label: 'Employees' },
            { key: 'providers', label: 'Providers' },
            { key: 'customers', label: 'Customers sampled' },
            { key: 'revenue', label: 'Revenue sampled' },
            { key: 'status', label: 'Status' },
          ],
          rows: branchRows,
          emptyState: {
            title: 'No branches matched this search',
            description: 'No business rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        center: {
          title: 'Branch staffing',
          subtitle: 'Recent branch-scoped internal users.',
          type: 'table',
          columns: [
            { key: 'employee', label: 'Employee' },
            { key: 'code', label: 'Code' },
            { key: 'scope', label: 'Access scope' },
            { key: 'status', label: 'Status' },
            { key: 'updatedAt', label: 'Updated' },
          ],
          rows: this.filterRowsBySearch(
            users.map((user) => ({
              employee: this.resolveUserDisplayName(user as any),
              code: user.employeeCode?.trim() || 'N/A',
              scope: user.accessScope?.trim() || 'N/A',
              status: user.status?.trim() || 'UNKNOWN',
              updatedAt: this.formatDateTime(user.updatedAt),
            })),
            query.search,
          ),
          emptyState: {
            title: 'No employees matched this search',
            description: 'No branch-scoped employee rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Branch provider mapping',
          subtitle: 'Recent providers linked to branches.',
          type: 'table',
          columns: [
            { key: 'provider', label: 'Provider' },
            { key: 'type', label: 'Type' },
            { key: 'status', label: 'Status' },
          ],
          rows: this.filterRowsBySearch(
            providers.map((provider) => ({
              provider: provider.providerName?.trim() || 'Provider',
              type: provider.providerType?.trim() || 'GENERAL',
              status: provider.status?.trim() || 'UNKNOWN',
            })),
            query.search,
          ),
          emptyState: {
            title: 'No providers matched this search',
            description: 'No provider rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getEmployeesWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const [userCount, sessionCount, deviceCount, users, sessions, devices] =
      await Promise.all([
        this.prisma.user.count({ where: { deletedAt: null } }),
        this.prisma.authSession.count(),
        this.prisma.authDevice.count(),
        this.prisma.user.findMany({
          where: { deletedAt: null },
          orderBy: [{ updatedAt: 'desc' }],
          take: 50,
          include: {
            role: { select: { code: true, name: true } },
            branchBusiness: { select: { name: true } },
          },
        }),
        this.prisma.authSession.findMany({
          orderBy: [{ lastSeenAt: 'desc' }],
          take: 50,
          include: {
            user: { select: { firstName: true, lastName: true, employeeCode: true } },
            authDevice: { select: { deviceName: true, platform: true } },
          },
        }),
        this.prisma.authDevice.findMany({
          orderBy: [{ lastSeenAt: 'desc' }],
          take: 50,
          include: {
            user: { select: { firstName: true, lastName: true, employeeCode: true } },
          },
        }),
      ]);
    const userRows = this.filterRowsBySearch(
      users.map((user) => ({
        employee: this.resolveUserDisplayName(user as any),
        code: user.employeeCode?.trim() || 'N/A',
        role: (user as any).role?.code?.trim() || 'N/A',
        branch: (user as any).branchBusiness?.name?.trim() || 'Unassigned',
        status: user.status?.trim() || 'UNKNOWN',
      })),
      query.search,
    );
    const sessionRows = this.filterRowsBySearch(
      sessions.map((session) => ({
        employee: this.resolveUserDisplayName((session as any).user),
        device: (session as any).authDevice?.deviceName?.trim() || 'Unknown device',
        platform: (session as any).authDevice?.platform?.trim() || 'UNKNOWN',
        status: session.revokedAt == null ? 'ACTIVE' : 'REVOKED',
        lastSeen: this.formatDateTime(session.lastSeenAt),
      })),
      query.search,
    );
    const deviceRows = this.filterRowsBySearch(
      devices.map((device) => ({
        employee: this.resolveUserDisplayName((device as any).user),
        device: device.deviceName?.trim() || 'Unknown device',
        platform: device.platform?.trim() || 'UNKNOWN',
        trusted: device.isTrusted ? 'TRUSTED' : 'UNTRUSTED',
        lastSeen: this.formatDateTime(device.lastSeenAt),
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'employees',
      {
        eyebrow: 'Organization / Employees',
        title: 'Employees',
        description:
          'Backend-owned employee identity, session, and trusted-device visibility from users, auth sessions, and devices.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Sessions',
      },
      {
        searchHint: 'Search employees, roles, sessions, and devices',
        tabs: ['Users', 'Sessions', 'Devices'],
        filters: ['ACTIVE', 'INACTIVE', 'TRUSTED', 'UNTRUSTED'],
      },
      [
        this.metric('Users', userCount, 'users rows'),
        this.metric('Sessions', sessionCount, 'auth_sessions rows'),
        this.metric('Devices', deviceCount, 'auth_devices rows'),
      ],
      {
        left: {
          title: 'Employee registry',
          subtitle: 'Internal users and branch scope.',
          type: 'table',
          columns: [
            { key: 'employee', label: 'Employee' },
            { key: 'code', label: 'Code' },
            { key: 'role', label: 'Role' },
            { key: 'branch', label: 'Branch' },
            { key: 'status', label: 'Status' },
          ],
          rows: userRows,
        },
        center: {
          title: 'Active sessions',
          subtitle: 'Recent auth session evidence for internal users.',
          type: 'table',
          columns: [
            { key: 'employee', label: 'Employee' },
            { key: 'device', label: 'Device' },
            { key: 'platform', label: 'Platform' },
            { key: 'status', label: 'Status' },
            { key: 'lastSeen', label: 'Last seen' },
          ],
          rows: sessionRows,
          emptyState: {
            title: 'No sessions matched this search',
            description: 'No auth session rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Trusted devices',
          subtitle: 'Recent auth-device evidence for internal users.',
          type: 'table',
          columns: [
            { key: 'employee', label: 'Employee' },
            { key: 'device', label: 'Device' },
            { key: 'platform', label: 'Platform' },
            { key: 'trusted', label: 'Trust' },
            { key: 'lastSeen', label: 'Last seen' },
          ],
          rows: deviceRows,
          emptyState: {
            title: 'No devices matched this search',
            description: 'No auth device rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getRolesWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const [roleCount, permissionCount, roles, rolePermissions, permissions] =
      await Promise.all([
        this.prisma.role.count(),
        this.prisma.permission.count(),
        this.prisma.role.findMany({
          orderBy: [{ code: 'asc' }],
          take: 50,
          include: {
            _count: { select: { users: true, rolePermissions: true } },
          },
        }),
        this.prisma.rolePermission.findMany({
          take: 200,
          include: {
            role: { select: { code: true } },
            permission: { select: { code: true, name: true } },
          },
        }),
        this.prisma.permission.findMany({
          orderBy: [{ code: 'asc' }],
          take: 100,
        }),
      ]);
    const roleRows = this.filterRowsBySearch(
      roles.map((role) => ({
        code: role.code?.trim() || 'N/A',
        name: role.name?.trim() || 'Role',
        scope: role.defaultScope?.trim() || 'N/A',
        users: `${role._count.users}`,
        permissions: `${role._count.rolePermissions}`,
        status: role.isSystemRole ? 'SYSTEM' : 'CUSTOM',
      })),
      query.search,
    );
    const permissionRows = this.filterRowsBySearch(
      permissions.map((permission) => ({
        code: permission.code?.trim() || 'N/A',
        name: permission.name?.trim() || 'Permission',
        description: permission.description?.trim() || 'N/A',
      })),
      query.search,
    );
    const mappingRows = this.filterRowsBySearch(
      rolePermissions.map((mapping) => ({
        role: mapping.role.code?.trim() || 'Role',
        permission: mapping.permission.code?.trim() || 'Permission',
        name: mapping.permission.name?.trim() || 'Permission',
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'roles',
      {
        eyebrow: 'Organization / Roles',
        title: 'Roles',
        description:
          'Backend-owned role catalog, permission registry, and role-permission mappings.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Mappings',
      },
      {
        searchHint: 'Search roles, permissions, and role-permission mappings',
        tabs: ['Roles', 'Permissions', 'Mappings'],
        filters: ['SYSTEM', 'CUSTOM'],
      },
      [
        this.metric('Roles', roleCount, 'roles rows'),
        this.metric('Permissions', permissionCount, 'permissions rows'),
        this.metric('Mappings', mappingRows.length, 'role_permissions rows in current sample'),
      ],
      {
        left: {
          title: 'Role catalog',
          subtitle: 'Current roles and user coverage.',
          type: 'table',
          columns: [
            { key: 'code', label: 'Code' },
            { key: 'name', label: 'Name' },
            { key: 'scope', label: 'Default scope' },
            { key: 'users', label: 'Users' },
            { key: 'permissions', label: 'Permissions' },
            { key: 'status', label: 'Type' },
          ],
          rows: roleRows,
        },
        center: {
          title: 'Permission registry',
          subtitle: 'Current backend permission definitions.',
          type: 'table',
          columns: [
            { key: 'code', label: 'Code' },
            { key: 'name', label: 'Name' },
            { key: 'description', label: 'Description' },
          ],
          rows: permissionRows,
          emptyState: {
            title: 'No permissions matched this search',
            description: 'No permission rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Role-permission mappings',
          subtitle: 'Current backend RBAC graph edges.',
          type: 'table',
          columns: [
            { key: 'role', label: 'Role' },
            { key: 'permission', label: 'Permission code' },
            { key: 'name', label: 'Permission name' },
          ],
          rows: mappingRows,
          emptyState: {
            title: 'No mappings matched this search',
            description: 'No role-permission rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
      },
    );
  }

  async getReportsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const reportMetadata = this.platformReportService.listMetadata('provider');
    const auditRows = await this.prisma.auditLog.findMany({
      orderBy: [{ createdAt: 'desc' }],
      take: 50,
    });
    const reportsRows = this.filterRowsBySearch(
      reportMetadata.reports.map((report) => ({
        id: report.id?.toString() || 'report',
        title: report.title?.toString() || 'Report',
        workspace: report.workspace?.toString() || 'shared',
        formats: Array.isArray(report.availableFormats)
          ? report.availableFormats.join(', ')
          : 'PDF',
        status: 'CONFIGURED',
      })),
      query.search,
    );
    const historyRows = this.filterRowsBySearch(
      auditRows.map((row) => ({
        createdAt: this.formatDateTime(row.createdAt),
        action: row.action?.trim() || 'AUDIT_EVENT',
        entity: row.entityType?.trim() || 'UNKNOWN',
        entityId: row.entityId?.toString() || 'N/A',
      })),
      query.search,
    );
    return this.buildWorkspacePayload(
      'reports',
      {
        eyebrow: 'Analytics / Reports',
        title: 'Reports',
        description:
          'Backend-owned report catalog and recent operational audit history related to report-capable workflows.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'History',
      },
      {
        searchHint: 'Search report metadata and recent operational export history',
        tabs: ['Catalog', 'History'],
        filters: ['CONFIGURED', 'PDF', 'CSV', 'XLSX'],
      },
      [
        this.metric('Configured reports', reportsRows.length, 'platform report metadata'),
        this.metric('History rows', historyRows.length, 'recent audit rows in sample'),
      ],
      {
        left: {
          title: 'Report catalog',
          subtitle: 'Configured platform report definitions.',
          type: 'table',
          columns: [
            { key: 'id', label: 'Report ID' },
            { key: 'title', label: 'Title' },
            { key: 'workspace', label: 'Workspace' },
            { key: 'formats', label: 'Formats' },
            { key: 'status', label: 'Status' },
          ],
          rows: reportsRows,
          emptyState: {
            title: 'No reports matched this search',
            description: 'No configured report metadata matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        center: {
          title: 'Recent operational history',
          subtitle: 'Recent audit rows that support report history visibility.',
          type: 'table',
          columns: [
            { key: 'createdAt', label: 'Created' },
            { key: 'action', label: 'Action' },
            { key: 'entity', label: 'Entity' },
            { key: 'entityId', label: 'Entity ID' },
          ],
          rows: historyRows,
          emptyState: {
            title: 'No report history matched this search',
            description: 'No recent audit rows matched the current query.',
            actionLabel: 'Refresh workspace',
          },
        },
        right: {
          title: 'Report engine summary',
          subtitle: 'Current report-engine posture from configured metadata.',
          type: 'details',
          details: [
            { label: 'Workspace', value: 'provider' },
            { label: 'Reports configured', value: `${reportsRows.length}` },
            {
              label: 'Available formats',
              value: Array.from(
                new Set(
                  reportsRows
                    .map((row) => row['formats'])
                    .filter(
                      (value): value is string =>
                        typeof value === 'string' && value.trim().length > 0,
                    ),
                ),
              ).join(', '),
            },
            { label: 'Recent history rows', value: `${historyRows.length}` },
          ],
        },
      },
    );
  }

  async getInsightsWorkspace(query: AdminGovernanceWorkspaceQuery) {
    const [customers, memberships, appointments, referrals, documents] =
      await Promise.all([
        this.prisma.customer.count({ where: { deletedAt: null } }),
        this.prisma.membership.count(),
        this.prisma.appointment.count(),
        this.prisma.referralRewardEvent.count(),
        this.prisma.document.count(),
      ]);
    return this.buildWorkspacePayload(
      'insights',
      {
        eyebrow: 'Analytics / Insights',
        title: 'Insights',
        description:
          'Backend-owned high-level insight metrics assembled from live customer, membership, appointment, referral, and document records.',
        primaryActionLabel: 'Refresh workspace',
        secondaryActionLabel: 'Dashboard',
      },
      {
        searchHint: 'Search insight labels and operational summaries',
        tabs: ['Overview', 'Growth', 'Retention', 'Compliance'],
        filters: ['LIVE', 'HEALTHY', 'REVIEW'],
      },
      [
        this.metric('Customers', customers, 'Live customer count'),
        this.metric('Memberships', memberships, 'Live membership count'),
        this.metric('Appointments', appointments, 'Live visit count'),
        this.metric('Referrals', referrals + documents, 'Referral and document signal volume'),
      ],
      {
        left: {
          title: 'Growth signals',
          subtitle: 'High-level backend-owned metrics only.',
          type: 'list',
          items: [
            { title: 'Customer growth', subtitle: `${customers} live customers`, meta: 'customers', status: 'LIVE' },
            { title: 'Membership base', subtitle: `${memberships} live memberships`, meta: 'memberships', status: 'LIVE' },
            { title: 'Visit throughput', subtitle: `${appointments} appointments`, meta: 'appointments', status: 'LIVE' },
          ],
        },
        center: {
          title: 'Compliance and retention',
          subtitle: 'Combined compliance and retention signals from live tables.',
          type: 'details',
          details: [
            { label: 'Documents', value: `${documents}` },
            { label: 'Referrals', value: `${referrals}` },
            { label: 'Membership retention base', value: `${memberships}` },
            { label: 'Visit activity', value: `${appointments}` },
          ],
        },
        right: {
          title: 'Insight summary',
          subtitle: 'Current backend-derived metric posture.',
          type: 'list',
          items: [
            { title: 'Growth', subtitle: `${customers} customers`, meta: 'customer growth baseline', status: 'HEALTHY' },
            { title: 'Retention', subtitle: `${memberships} memberships`, meta: 'membership base', status: 'LIVE' },
            { title: 'Compliance', subtitle: `${documents} documents`, meta: 'document pipeline', status: documents > 0 ? 'LIVE' : 'REVIEW' },
          ],
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
    options: WorkspacePayloadOptions = {},
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
      actions: options.actions ?? [],
      bulkActions: options.bulkActions ?? [],
      permissions: options.permissions ?? {},
      exports: options.exports ?? [],
      forms: options.forms ?? [],
      commands: options.commands ?? [],
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
            ...(panel.selectionKey != null
              ? { selectionKey: panel.selectionKey }
              : {}),
            ...(panel.selectedId != null ? { selectedId: panel.selectedId } : {}),
            ...(panel.selectionEnabled != null
              ? { selectionEnabled: panel.selectionEnabled }
              : {}),
            ...(panel.sortKey != null ? { sortKey: panel.sortKey } : {}),
            ...(panel.sortDirection != null
              ? { sortDirection: panel.sortDirection }
              : {}),
            ...(panel.pagination != null ? { pagination: panel.pagination } : {}),
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

  private filterRowsByRequestedStatus(
    rows: Array<Record<string, string>>,
    status?: string | null,
  ) {
    const normalized = status?.trim().toUpperCase();
    if (!normalized) {
      return rows;
    }
    return rows.filter(
      (row) => (row.status ?? row.Status ?? '').trim().toUpperCase() === normalized,
    );
  }

  private buildStatusSummaryItems(
    rows: Array<Record<string, string>>,
    key: string,
  ) {
    const counts = new Map<string, number>();
    for (const row of rows) {
      const value = row[key]?.trim() || 'UNKNOWN';
      counts.set(value, (counts.get(value) ?? 0) + 1);
    }
    return Array.from(counts.entries())
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([status, count]) => ({
        title: status,
        subtitle: `${count} rows`,
        meta: key,
        status,
      }));
  }

  private resolveUserDisplayName(user: any) {
    if (user == null || typeof user !== 'object') {
      return 'Unknown user';
    }
    const name = [user.firstName, user.lastName]
      .filter((value): value is string => Boolean(value?.trim().length))
      .join(' ')
      .trim();
    if (name.length > 0 && typeof user.employeeCode === 'string' && user.employeeCode.trim().length > 0) {
      return `${name} (${user.employeeCode.trim()})`;
    }
    if (name.length > 0 && typeof user.email === 'string' && user.email.trim().length > 0) {
      return `${name} (${user.email.trim()})`;
    }
    if (name.length > 0) {
      return name;
    }
    if (typeof user.employeeCode === 'string' && user.employeeCode.trim().length > 0) {
      return user.employeeCode.trim();
    }
    if (typeof user.email === 'string' && user.email.trim().length > 0) {
      return user.email.trim();
    }
    return 'Unknown user';
  }

  private formatMoney(value: any) {
    const amount =
      value == null
        ? 0
        : typeof value === 'number'
          ? value
          : typeof value?.toNumber === 'function'
            ? value.toNumber()
            : Number(value);
    return Number.isFinite(amount) ? amount.toFixed(2) : '0.00';
  }

  private formatMoneyValue(value: number) {
    return this.formatMoney(value);
  }

  private formatDecimal(value: any) {
    const numeric =
      value == null
        ? NaN
        : typeof value === 'number'
          ? value
          : typeof value?.toNumber === 'function'
            ? value.toNumber()
            : Number(value);
    return Number.isFinite(numeric) ? numeric.toFixed(2) : 'N/A';
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
    if (value == null) {
      return 'N/A';
    }
    return new Intl.DateTimeFormat('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
      timeZone: 'Asia/Kolkata',
    }).format(value);
  }
}
