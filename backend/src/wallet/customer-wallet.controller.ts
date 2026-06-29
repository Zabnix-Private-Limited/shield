import { Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { WalletService } from './wallet.service';

@Controller('customer')
export class CustomerWalletController {
  constructor(private readonly walletService: WalletService) {}

  @RequirePermissions('wallet.view')
  @Get('wallet')
  async getWallet(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const id =
      principal?.principalType === 'CUSTOMER'
        ? BigInt(principal.customerId!)
        : customerId
          ? BigInt(customerId)
          : BigInt(1);

    return {
      success: true,
      message: 'Customer wallet retrieved successfully.',
      data: await this.walletService.getCustomerWalletBundle(id),
    };
  }
}
