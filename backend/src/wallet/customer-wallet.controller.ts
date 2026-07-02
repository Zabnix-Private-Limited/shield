import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { AgentScopeService } from '../auth/agent-scope.service';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { WalletService } from './wallet.service';

@Controller('customer')
export class CustomerWalletController {
  constructor(
    private readonly walletService: WalletService,
    private readonly agentScopeService: AgentScopeService,
  ) {}

  private resolveCustomerId(
    customerId?: string,
    principal?: ShieldPrincipal,
  ): bigint {
    if (principal?.principalType === 'CUSTOMER' && principal.customerId) {
      return BigInt(principal.customerId);
    }
    if (customerId?.trim()) {
      return BigInt(customerId);
    }
    throw new BadRequestException('Authenticated customer context is required.');
  }

  @RequirePermissions('wallet.view')
  @Get('wallet')
  async getWallet(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const resolvedCustomerId = this.resolveCustomerId(customerId, principal);
    await this.agentScopeService.assertAgentCanAccessWalletByCustomer(
      resolvedCustomerId,
      principal,
    );
    return {
      success: true,
      message: 'Customer wallet retrieved successfully.',
      data: await this.walletService.getCustomerWalletBundle(
        resolvedCustomerId,
      ),
    };
  }
}
