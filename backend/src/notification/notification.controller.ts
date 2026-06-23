import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { NotificationService } from './notification.service';
import { MockAuthGuard } from '../auth/mock-auth.guard';

@Controller('notifications')
@UseGuards(MockAuthGuard)
export class NotificationController {
  constructor(private notificationService: NotificationService) {}

  @Get()
  async list(@Request() req: any, @Query('customer_id') customerId?: string) {
    let targetCustomerId: bigint | undefined = undefined;

    if (!req.user.isStaff) {
      targetCustomerId = BigInt(req.user.id);
    } else if (customerId) {
      targetCustomerId = BigInt(customerId);
    }

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
