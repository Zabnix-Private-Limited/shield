import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
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
    private readonly platformRealtimeService: PlatformRealtimeService,
  ) {}

  async list(customerId?: bigint) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    }
    return this.prisma.notification.findMany({
      where: whereClause,
      orderBy: { sentAt: 'desc' },
    });
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

  async deactivateDeviceToken(token: string) {
    return this.prisma.devicePushToken.updateMany({
      where: { token },
      data: {
        isActive: false,
        lastSeenAt: new Date(),
      },
    });
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
