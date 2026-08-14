import {
  Controller,
  ForbiddenException,
  Get,
  Post,
  Param,
  Body,
  Query,
  UnauthorizedException,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { AgentScopeService } from '../auth/agent-scope.service';
import { WalletService } from './wallet.service';
import { WALLET_LEDGER_TYPES } from '../pricing/pricing.types';

@Controller('wallets')
export class WalletController {
  constructor(
    private walletService: WalletService,
    private readonly providerScopeService: ProviderScopeService,
    private readonly agentScopeService: AgentScopeService,
  ) {}

  @RequirePermissions('wallet.view')
  @Get(':customerId')
  async getWallet(
    @Param('customerId') customerId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (
      principal?.principalType === 'CUSTOMER' &&
      principal.customerId !== customerId
    ) {
      throw new ForbiddenException('Customers can only view their own wallet.');
    }

    await this.providerScopeService.assertProviderCanAccessWalletByCustomer(
      BigInt(customerId),
      principal,
    );
    await this.agentScopeService.assertAgentCanAccessWalletByCustomer(
      BigInt(customerId),
      principal,
    );
    const data = await this.walletService.getWalletByCustomerId(
      BigInt(customerId),
      {
        includeHiddenBenefit: principal?.roleCode === 'ADMIN',
      },
    );
    return {
      success: true,
      message: 'Wallet profile retrieved successfully',
      data,
    };
  }

  @RequirePermissions('wallet.update')
  @Post('recharge')
  async recharge(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (!principal || !principal.userId) {
      throw new UnauthorizedException('Authentication required');
    }
    const staffId = BigInt(principal.userId);
    await this.agentScopeService.assertAgentCanAccessWalletByCustomer(
      BigInt(body.customer_id),
      principal,
    );
    if (
      (body.ledger_type || WALLET_LEDGER_TYPES.CASH) ===
        WALLET_LEDGER_TYPES.SHIELD_BENEFIT &&
      principal?.roleCode !== 'ADMIN'
    ) {
      throw new ForbiddenException(
        'Only admin may grant or preload SHIELD benefit ledger entries.',
      );
    }
    const txn = await this.walletService.recharge(
      BigInt(body.customer_id),
      Number(body.amount),
      staffId,
      body.remarks,
      body.ledger_type || WALLET_LEDGER_TYPES.CASH,
    );
    return {
      success: true,
      message: 'Wallet recharged successfully',
      data: txn,
    };
  }

  @RequirePermissions('wallet.update')
  @Post('adjustments')
  async adjust(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (!principal || !principal.userId) {
      throw new UnauthorizedException('Authentication required');
    }
    const staffId = BigInt(principal.userId);
    await this.agentScopeService.assertAgentCanAccessWalletByCustomer(
      BigInt(body.customer_id),
      principal,
    );
    if (
      (body.ledger_type || WALLET_LEDGER_TYPES.CASH) ===
        WALLET_LEDGER_TYPES.SHIELD_BENEFIT &&
      principal?.roleCode !== 'ADMIN'
    ) {
      throw new ForbiddenException(
        'Only admin may adjust SHIELD benefit ledger entries.',
      );
    }
    const txn = await this.walletService.adjust(
      BigInt(body.customer_id),
      Number(body.amount),
      body.type,
      staffId,
      body.remarks,
      body.ledger_type || WALLET_LEDGER_TYPES.CASH,
    );
    return {
      success: true,
      message: 'Wallet adjustment processed successfully',
      data: txn,
    };
  }

  @RequirePermissions('wallet.view')
  @Get(':id/transactions')
  async getTransactions(
    @Param('id') id: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('type') type?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType === 'CUSTOMER') {
      if (!principal.customerId) {
        throw new ForbiddenException(
          'Authenticated customer context is required.',
        );
      }
      const ownsWallet = await this.walletService.walletBelongsToCustomer(
        BigInt(id),
        BigInt(principal.customerId),
      );
      if (!ownsWallet) {
        throw new ForbiddenException(
          'Customers can only view their own wallet transactions.',
        );
      }
    }
    await this.providerScopeService.assertProviderCanAccessWallet(
      BigInt(id),
      principal,
    );
    await this.agentScopeService.assertAgentCanAccessWallet(
      BigInt(id),
      principal,
    );
    const txns = await this.walletService.getTransactions(BigInt(id), {
      from,
      to,
      type,
    });
    return {
      success: true,
      message: 'Transactions feed retrieved',
      data: txns,
    };
  }

  @RequirePermissions('wallet.update')
  @Post('redeem-points')
  async redeemPoints(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (!principal || !principal.userId) {
      throw new UnauthorizedException('Authentication required');
    }
    const staffId = BigInt(principal.userId);
    await this.agentScopeService.assertAgentCanAccessWalletByCustomer(
      BigInt(body.customer_id),
      principal,
    );
    const result = await this.walletService.redeemRewardPoints(
      BigInt(body.customer_id),
      Number(body.points),
      staffId,
    );
    return {
      success: true,
      message: 'Reward points redeemed successfully.',
      data: result,
    };
  }
}
