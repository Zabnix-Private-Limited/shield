import { Body, Controller, ForbiddenException, Get, Param, Post } from '@nestjs/common';
import { AgentScopeService } from '../auth/agent-scope.service';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import { ReferralService } from './referral.service';

@Controller('referrals')
export class ReferralController {
  constructor(
    private readonly referralService: ReferralService,
    private readonly agentScopeService: AgentScopeService,
  ) {}

  private assertCustomerOwnReferralData(
    customerId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType !== 'CUSTOMER') {
      return;
    }
    if (!principal.customerId) {
      throw new ForbiddenException('Authenticated customer context is required.');
    }
    if (BigInt(principal.customerId) !== customerId) {
      throw new ForbiddenException(
        'Customers can only access their own referral data.',
      );
    }
  }

  @RequirePermissions('referrals.view')
  @Get('tree/:customerId')
  async tree(
    @Param('customerId') customerId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const requestedCustomerId = BigInt(customerId);
    this.assertCustomerOwnReferralData(requestedCustomerId, principal);
    await this.agentScopeService.assertAgentCanAccessCustomer(
      requestedCustomerId,
      principal,
    );
    return {
      success: true,
      message: 'Referral tree retrieved successfully.',
      data: await this.referralService.getReferralTree(requestedCustomerId),
    };
  }

  @RequirePermissions('referrals.view')
  @Get('summary/:customerId')
  async summary(
    @Param('customerId') customerId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const requestedCustomerId = BigInt(customerId);
    this.assertCustomerOwnReferralData(requestedCustomerId, principal);
    await this.agentScopeService.assertAgentCanAccessCustomer(
      requestedCustomerId,
      principal,
    );
    return {
      success: true,
      message: 'Referral summary retrieved successfully.',
      data: await this.referralService.getReferralSummary(requestedCustomerId),
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
