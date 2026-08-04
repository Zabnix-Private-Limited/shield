import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { ManagementDemoService } from './management-demo.service';

@Controller('management-demo')
export class ManagementDemoController {
  constructor(private readonly service: ManagementDemoService) {}

  @RequirePermissions('customers.view')
  @Post('subscriptions/preview')
  previewSubscription(@Body() body: any) {
    return {
      success: true,
      data: this.service.subscriptionPreview(
        BigInt(body.carry_forward_paise || 0),
        BigInt(body.used_paise || 0),
      ),
    };
  }

  @RequirePermissions('customers.approve')
  @Post('subscriptions/:customerId/activate')
  activateSubscription(@Param('customerId') id: string) {
    return this.service
      .activateSubscription(BigInt(id))
      .then((data) => ({ success: true, data }));
  }

  @RequirePermissions('customers.view')
  @Get('subscriptions/:customerId')
  subscription(@Param('customerId') id: string) {
    return this.service
      .getSubscription(BigInt(id))
      .then((data) => ({ success: true, data }));
  }

  @RequirePermissions('customers.approve')
  @Post('commissions/preview')
  previewCommission(@Body() body: any) {
    return {
      success: true,
      data: this.service.commissionPreview(
        BigInt(body.pool_paise),
        body.originating_level,
      ),
    };
  }

  @RequirePermissions('customers.approve')
  @Post('commissions')
  createCommission(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return this.service
      .createCommissionEvent({
        customerId: body.customer_id ? BigInt(body.customer_id) : undefined,
        sourceType: body.source_type,
        originatingLevel: body.originating_level,
        poolPaise: BigInt(body.pool_paise),
        createdBy: principal?.userId ? BigInt(principal.userId) : undefined,
      })
      .then((data) => ({ success: true, data }));
  }

  @RequirePermissions('customers.view')
  @Get('commissions')
  commissionHistory() {
    return this.service
      .listCommissionHistory()
      .then((data) => ({ success: true, data }));
  }

  @RequirePermissions('customers.view')
  @Get('customers/:customerId/activities')
  customerActivities(@Param('customerId') id: string) {
    return this.service
      .listCustomerActivities(BigInt(id))
      .then((data) => ({ success: true, data }));
  }
}
