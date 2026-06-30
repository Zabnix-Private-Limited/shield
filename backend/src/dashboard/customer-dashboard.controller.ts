import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { DashboardService } from './dashboard.service';

@Controller('customer')
export class CustomerDashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

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
  @Get('dashboard')
  async getDashboard(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Customer dashboard retrieved successfully.',
      data: await this.dashboardService.getCustomerPortalDashboard(
        this.resolveCustomerId(customerId, principal),
      ),
    };
  }
}
