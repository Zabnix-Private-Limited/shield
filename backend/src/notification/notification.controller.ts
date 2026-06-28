import {
  Body,
  Controller,
  Get,
  Param,
  Post,
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

  @Post('device-token')
  async registerDeviceToken(@Body() body: any) {
    const token = (body.token ?? '').toString().trim();
    const platform = (body.platform ?? '').toString().trim();
    const customerId = (body.customer_id ?? '').toString().trim();

    if (!token || !platform || !customerId) {
      return {
        success: false,
        message: 'customer_id, token, and platform are required.',
      };
    }

    const deviceToken = await this.notificationService.registerDeviceToken({
      customerId: BigInt(customerId),
      token,
      platform,
      deviceLabel: body.device_label?.toString().trim() || undefined,
    });

    return {
      success: true,
      message: 'Device push token registered successfully',
      data: deviceToken,
    };
  }

  @Post('device-token/deactivate')
  async deactivateDeviceToken(@Body() body: any) {
    const token = (body.token ?? '').toString().trim();
    if (!token) {
      return {
        success: false,
        message: 'token is required.',
      };
    }

    const result = await this.notificationService.deactivateDeviceToken(token);
    return {
      success: true,
      message: 'Device push token deactivated successfully',
      data: result,
    };
  }

  @Post('send')
  async send(@Body() body: any) {
    const result = await this.notificationService.send({
      customerId: BigInt(body.customer_id),
      title: body.title,
      message: body.message,
      data:
        body.data && typeof body.data === 'object'
          ? Object.fromEntries(
              Object.entries(body.data).map(([key, value]) => [
                key,
                String(value),
              ]),
            )
          : undefined,
    });

    return {
      success: true,
      message: 'Notification sent successfully',
      data: result,
    };
  }
}
