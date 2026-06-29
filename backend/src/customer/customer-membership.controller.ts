import { Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CustomerService } from './customer.service';

@Controller('customer')
export class CustomerMembershipController {
  constructor(private readonly customerService: CustomerService) {}

  @RequirePermissions('customers.view')
  @Get('membership')
  async getMembership(
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
      message: 'Customer membership retrieved successfully.',
      data: await this.customerService.getCustomerPortalMembership(id),
    };
  }
}
