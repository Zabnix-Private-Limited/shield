import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationService {
  constructor(private prisma: PrismaService) {}

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
    return this.prisma.notification.update({
      where: { id },
      data: { status: 'READ' },
    });
  }

  async send(data: { customerId: bigint; title: string; message: string }) {
    return this.prisma.notification.create({
      data: {
        customerId: data.customerId,
        title: data.title,
        message: data.message,
        channel: 'IN_APP',
        status: 'UNREAD',
        sentAt: new Date(),
      },
    });
  }
}
