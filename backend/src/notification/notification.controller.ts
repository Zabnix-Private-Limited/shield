import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { NotificationService } from './notification.service';

@Controller('notifications')
export class NotificationController {
  constructor(private notificationService: NotificationService) {}

  @Get()
  async list(@Query('customer_id') customerId?: string) {
    const targetCustomerId = customerId ? BigInt(customerId) : undefined;
    const notifs = await this.notificationService.list(targetCustomerId);
    return {
      success: true,
      message: 'Notifications retrieved successfully',
      data: notifs,
    };
  }

  @Post(':id/read')
  async markAsRead(@Param('id') id: string) {
    const notif = await this.notificationService.markAsRead(BigInt(id));
    return {
      success: true,
      message: 'Notification marked as read',
      data: notif,
    };
  }

  @Post('send')
  async send(@Body() body: any) {
    const notif = await this.notificationService.send({
      customerId: BigInt(body.customer_id),
      title: body.title,
      message: body.message,
    });
    return {
      success: true,
      message: 'Notification sent successfully',
      data: notif,
    };
  }
}
