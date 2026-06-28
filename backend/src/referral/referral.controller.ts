import { Controller, Get, Param, Post, Body } from '@nestjs/common';
import { RequirePermissions } from '../auth/permissions.decorator';
import { ReferralService } from './referral.service';

@Controller('referrals')
export class ReferralController {
  constructor(private readonly referralService: ReferralService) {}

  @RequirePermissions('referrals.view')
  @Get('tree/:customerId')
  async tree(@Param('customerId') customerId: string) {
    return {
      success: true,
      message: 'Referral tree retrieved successfully.',
      data: await this.referralService.getReferralTree(BigInt(customerId)),
    };
  }

  @RequirePermissions('referrals.view')
  @Get('summary/:customerId')
  async summary(@Param('customerId') customerId: string) {
    return {
      success: true,
      message: 'Referral summary retrieved successfully.',
      data: await this.referralService.getReferralSummary(BigInt(customerId)),
    };
  }

  @RequirePermissions('referrals.approve')
  @Post('qualify')
  async qualify(@Body() body: any) {
    return {
      success: true,
      message: 'Referral qualification processed successfully.',
      data: await this.referralService.qualifyRewardFromTransaction({
        customerId: BigInt(body.customer_id),
        serviceType: body.service_type,
        referenceType: body.reference_type,
        referenceId: BigInt(body.reference_id),
        performedBy: body.performed_by ? BigInt(body.performed_by) : undefined,
      }),
    };
  }
}
