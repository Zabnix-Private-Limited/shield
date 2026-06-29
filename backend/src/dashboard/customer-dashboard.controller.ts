import { Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { DashboardService } from './dashboard.service';

@Controller('customer')
export class CustomerDashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @RequirePermissions('customers.view')
  @Get('dashboard')
  async getDashboard(
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
      message: 'Customer dashboard retrieved successfully.',
      data: await this.dashboardService.getCustomerPortalDashboard(id),
    };
  }
}
