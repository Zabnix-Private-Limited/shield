import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CustomerService } from './customer.service';

@Controller('customer')
export class CustomerMembershipController {
  constructor(private readonly customerService: CustomerService) {}

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

  @RequirePermissions('customers.view')
  @Get('membership')
  async getMembership(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Customer membership retrieved successfully.',
      data: await this.customerService.getCustomerPortalMembership(
        this.resolveCustomerId(customerId, principal),
      ),
    };
  }
}
