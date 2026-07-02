import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AgentScopeService } from '../auth/agent-scope.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { NotificationService } from './notification.service';

@Controller('notifications')
export class NotificationController {
  constructor(
    private notificationService: NotificationService,
    private readonly agentScopeService: AgentScopeService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  @RequirePermissions('notifications.view')
  @Get()
  async list(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const targetCustomerId =
      principal?.principalType === 'CUSTOMER'
        ? BigInt(principal.customerId!)
        : customerId
          ? BigInt(customerId)
          : undefined;
    if (targetCustomerId) {
      await this.agentScopeService.assertAgentCanAccessCustomer(
        targetCustomerId,
        principal,
      );
      await this.providerScopeService.assertProviderCanAccessCustomer(
        targetCustomerId,
        principal,
      );
    }
    const notifs = await this.notificationService.list(targetCustomerId, principal);
    return {
      success: true,
      message: 'Notifications retrieved successfully',
      data: notifs,
    };
  }

  @RequirePermissions('notifications.view')
  @Post(':id/read')
  async markAsRead(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessNotification(BigInt(id), principal);
    await this.providerScopeService.assertProviderCanAccessNotification(
      BigInt(id),
      principal,
    );
    const notif = await this.notificationService.markAsRead(BigInt(id));
    return {
      success: true,
      message: 'Notification marked as read',
      data: notif,
    };
  }

  @RequirePermissions('notifications.update')
  @Post('mark-all-read')
  async markAllRead(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const customerIds = body.customer_id
      ? [BigInt(body.customer_id)]
      : this.agentScopeService.isAgentPrincipal(principal)
        ? await this.agentScopeService.listAccessibleCustomerIds(principal)
        : [];

    if (body.customer_id) {
      await this.agentScopeService.assertAgentCanAccessCustomer(
        BigInt(body.customer_id),
        principal,
      );
      await this.providerScopeService.assertProviderCanAccessCustomer(
        BigInt(body.customer_id),
        principal,
      );
    }

    const result = await this.notificationService.markAllAsRead(customerIds);
    return {
      success: true,
      message: 'Notifications marked as read',
      data: result,
    };
  }

  @RequirePermissions('notifications.create')
  @Post('device-token')
  async registerDeviceToken(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const token = (body.token ?? '').toString().trim();
    const platform = (body.platform ?? '').toString().trim();
    const customerId =
      principal?.principalType === 'CUSTOMER'
        ? principal.customerId ?? ''
        : (body.customer_id ?? '').toString().trim();

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
      sessionId: principal?.sessionId,
    });

    return {
      success: true,
      message: 'Device push token registered successfully',
      data: deviceToken,
    };
  }

  @RequirePermissions('notifications.update')
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

  @RequirePermissions('notifications.create')
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
