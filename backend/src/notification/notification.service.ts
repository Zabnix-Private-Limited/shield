import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AgentScopeService } from '../auth/agent-scope.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { PlatformRealtimeService } from '../platform-capabilities/platform-realtime.service';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseAdminService } from './firebase-admin.service';

type SendNotificationInput = {
  customerId: bigint;
  title: string;
  message: string;
  data?: Record<string, string>;
};

type RegisterTokenInput = {
  customerId: bigint;
  token: string;
  platform: string;
  deviceLabel?: string;
  sessionId?: string;
};

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private prisma: PrismaService,
    private firebaseAdminService: FirebaseAdminService,
    private readonly agentScopeService: AgentScopeService,
    private readonly providerScopeService: ProviderScopeService,
    private readonly platformRealtimeService: PlatformRealtimeService,
  ) {}

  async list(customerId?: bigint, principal?: ShieldPrincipal, limit?: number) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    } else if (this.agentScopeService.isAgentPrincipal(principal)) {
      const accessibleCustomerIds =
        await this.agentScopeService.listAccessibleCustomerIds(principal);
      whereClause.customerId =
        accessibleCustomerIds.length > 0 ? { in: accessibleCustomerIds } : { in: [] };
    } else if (this.providerScopeService.isProviderPrincipal(principal)) {
      const accessibleCustomerIds =
        await this.providerScopeService.listAccessibleCustomerIds(principal);
      whereClause.customerId =
        accessibleCustomerIds.length > 0 ? { in: accessibleCustomerIds } : { in: [] };
    }
    return this.prisma.notification.findMany({
      where: whereClause,
      orderBy: { sentAt: 'desc' },
      ...(limit == null ? {} : { take: Math.max(1, Math.min(50, limit)) }),
    });
  }

  async listCustomerNotifications(
    customerId: bigint,
    offset = 0,
    limit = 25,
  ) {
    const safeOffset = Number.isFinite(offset) ? Math.max(0, Math.floor(offset)) : 0;
    const safeLimit = Number.isFinite(limit) ? Math.min(50, Math.max(1, Math.floor(limit))) : 25;
    const [notifications, unreadCount, total] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
      where: { customerId },
      select: {
        id: true,
        title: true,
        message: true,
        channel: true,
        status: true,
        sentAt: true,
      },
      orderBy: [{ sentAt: 'desc' }, { id: 'desc' }],
      skip: safeOffset,
      take: safeLimit,
    }),
      this.prisma.notification.count({ where: { customerId, NOT: { status: 'READ' } } }),
      this.prisma.notification.count({ where: { customerId } }),
    ]);
    return {
      unreadCount,
      total,
      offset: safeOffset,
      limit: safeLimit,
      nextOffset: safeOffset + notifications.length < total
        ? safeOffset + notifications.length
        : null,
      items: notifications.map((notification) => ({
        id: notification.id.toString(),
        title: notification.title ?? 'Notification',
        message: notification.message ?? '',
        channel: notification.channel ?? 'IN_APP',
        status: notification.status ?? 'UNREAD',
        sentAt: notification.sentAt,
      })),
    };
  }

  async notificationBelongsToCustomer(
    notificationId: bigint,
    customerId: bigint,
  ): Promise<boolean> {
    return (
      (await this.prisma.notification.count({
        where: { id: notificationId, customerId },
      })) > 0
    );
  }

  async markAsRead(id: bigint) {
    const notification = await this.prisma.notification.update({
      where: { id },
      data: { status: 'READ' },
    });
    this.platformRealtimeService.publish({
      id: `notification-read:${notification.id.toString()}`,
      type: 'NOTIFICATION_READ',
      category: 'notification',
      title: 'Notification marked as read',
      description: notification.title ?? 'Notification marked as read',
      workspace: 'provider',
      customerId: notification.customerId?.toString(),
      metadata: {
        notificationId: notification.id.toString(),
      },
    });
    return notification;
  }

  async markAllAsRead(customerIds: bigint[]) {
    if (customerIds.length === 0) {
      return { count: 0 };
    }

    const unread = await this.prisma.notification.findMany({
      where: {
        customerId: { in: customerIds },
        NOT: { status: 'READ' },
      },
      select: {
        id: true,
        customerId: true,
        title: true,
      },
    });

    if (unread.length === 0) {
      return { count: 0 };
    }

    await this.prisma.notification.updateMany({
      where: {
        id: { in: unread.map((item) => item.id) },
      },
      data: {
        status: 'READ',
      },
    });

    for (const notification of unread) {
      this.platformRealtimeService.publish({
        id: `notification-read:${notification.id.toString()}`,
        type: 'NOTIFICATION_READ',
        category: 'notification',
        title: 'Notification marked as read',
        description: notification.title ?? 'Notification marked as read',
        workspace: 'agent',
        customerId: notification.customerId?.toString(),
        metadata: {
          notificationId: notification.id.toString(),
          bulkAction: true,
        },
      });
    }

    return { count: unread.length };
  }

  async registerDeviceToken(input: RegisterTokenInput) {
    const session = input.sessionId
      ? await this.prisma.authSession.findUnique({
          where: { sessionId: input.sessionId },
          select: { authDeviceId: true },
        })
      : null;

    return this.prisma.devicePushToken.upsert({
      where: { token: input.token },
      update: {
        customerId: input.customerId,
        authDeviceId: session?.authDeviceId ?? undefined,
        platform: input.platform.toUpperCase(),
        deviceLabel: input.deviceLabel,
        isActive: true,
        lastSeenAt: new Date(),
      },
      create: {
        uuid: randomUUID(),
        customerId: input.customerId,
        authDeviceId: session?.authDeviceId ?? undefined,
        token: input.token,
        platform: input.platform.toUpperCase(),
        deviceLabel: input.deviceLabel,
        isActive: true,
        lastSeenAt: new Date(),
      },
    });
  }

  async deactivateDeviceToken(token: string, customerId?: bigint) {
    return this.prisma.devicePushToken.updateMany({
      where: { token, ...(customerId == null ? {} : { customerId }) },
      data: {
        isActive: false,
        lastSeenAt: new Date(),
      },
    });
  }

  async getDeviceTokenCustomerId(token: string) {
    const deviceToken = await this.prisma.devicePushToken.findUnique({
      where: { token },
      select: { customerId: true },
    });
    return deviceToken?.customerId;
  }

  async send(data: SendNotificationInput) {
    const notification = await this.prisma.notification.create({
      data: {
        customerId: data.customerId,
        title: data.title,
        message: data.message,
        channel: 'IN_APP',
        status: 'UNREAD',
        sentAt: new Date(),
      },
    });
    this.platformRealtimeService.publish({
      id: `notification:${notification.id.toString()}`,
      type: 'NOTIFICATION_CREATED',
      category: 'notification',
      title: notification.title ?? 'Notification',
      description: notification.message ?? 'A new notification was created.',
      workspace: 'provider',
      customerId: data.customerId.toString(),
      metadata: {
        notificationId: notification.id.toString(),
        channel: notification.channel,
        status: notification.status,
      },
    });

    const deviceTokens = await this.prisma.devicePushToken.findMany({
      where: {
        customerId: data.customerId,
        isActive: true,
      },
      orderBy: { updatedAt: 'desc' },
    });

    if (deviceTokens.length == 0) {
      return {
        notification,
        push: {
          attempted: false,
          configured: this.firebaseAdminService.isConfigured(),
          reason: 'No active device tokens registered for customer.',
        },
      };
    }

    const result = await this.firebaseAdminService.sendToTokens(
      deviceTokens.map((item) => item.token),
      {
        title: data.title,
        body: data.message,
        data: {
          customerId: data.customerId.toString(),
          notificationId: notification.id.toString(),
          ...(data.data ?? {}),
        },
      },
    );

    if (result.failureCount > 0) {
      this.logger.warn(
        `FCM delivery reported ${result.failureCount} failures for customer ${data.customerId.toString()}.`,
      );
    }

    return {
      notification,
      push: {
        attempted: true,
        configured: this.firebaseAdminService.isConfigured(),
        successCount: result.successCount,
        failureCount: result.failureCount,
      },
    };
  }
}
