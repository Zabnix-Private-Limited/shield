import { Body, Controller, Get, Post } from '@nestjs/common';
import { RequirePermissions } from '../auth/permissions.decorator';
import { PricingService } from './pricing.service';

@Controller('pricing')
export class PricingController {
  constructor(private readonly pricingService: PricingService) {}

  @RequirePermissions('analytics.view')
  @Post('evaluate')
  async evaluate(@Body() body: any) {
    const evaluation = await this.pricingService.evaluateServicePrice({
      customerId: BigInt(body.customer_id),
      serviceType: body.service_type,
      originalAmount: Number(body.original_amount),
      requestedRewardPoints: body.requested_reward_points
        ? Number(body.requested_reward_points)
        : undefined,
      persistAudit: Boolean(body.persist_audit),
      referenceType: body.reference_type,
      referenceId: body.reference_id ? BigInt(body.reference_id) : undefined,
    });

    return {
      success: true,
      message: 'Pricing evaluation completed successfully.',
      data: evaluation,
    };
  }

  @RequirePermissions('settings.view')
  @Get('admin/config')
  async getAdminConfig() {
    return {
      success: true,
      message: 'Commercial configuration retrieved successfully.',
      data: await this.pricingService.getAdminCommercialConfig(),
    };
  }

  @RequirePermissions('analytics.view')
  @Get('admin/audits')
  async getPricingAudits() {
    return {
      success: true,
      message: 'Pricing rule audits retrieved successfully.',
      data: await this.pricingService.getPricingAudits(),
    };
  }

  @RequirePermissions('settings.update')
  @Post('admin/service-rules')
  async upsertServiceRule(@Body() body: any) {
    return {
      success: true,
      message: 'Service benefit rule saved successfully.',
      data: await this.pricingService.upsertServiceRule(body),
    };
  }

  @RequirePermissions('settings.update')
  @Post('admin/reward-rules')
  async upsertRewardRule(@Body() body: any) {
    return {
      success: true,
      message: 'Reward point rule saved successfully.',
      data: await this.pricingService.upsertRewardRule(body),
    };
  }

  @RequirePermissions('settings.update')
  @Post('admin/redemption-rules')
  async upsertRedemptionRule(@Body() body: any) {
    return {
      success: true,
      message: 'Reward redemption rule saved successfully.',
      data: await this.pricingService.upsertRedemptionRule(body),
    };
  }

  @RequirePermissions('settings.update')
  @Post('admin/settings')
  async upsertCommercialSetting(@Body() body: any) {
    return {
      success: true,
      message: 'Commercial setting saved successfully.',
      data: await this.pricingService.upsertCommercialSetting(body),
    };
  }
}
