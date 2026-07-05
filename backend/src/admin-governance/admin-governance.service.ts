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
