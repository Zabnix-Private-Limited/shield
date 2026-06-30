import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Query,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

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

  @RequirePermissions('analytics.view')
  @Get('customer')
  async getCustomerDashboard(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const id = this.resolveCustomerId(customerId, principal);
    const data = await this.dashboardService.getCustomerDashboard(id);
    return {
      success: true,
      message: 'Customer dashboard metrics retrieved',
      data,
    };
  }

  @RequirePermissions('analytics.view')
  @Get('staff')
  async getStaffDashboard() {
    const data = await this.dashboardService.getStaffDashboard();
    return {
      success: true,
      message: 'Staff dashboard metrics retrieved',
      data,
    };
  }

  @RequirePermissions('analytics.view')
  @Get('crm')
  async getCrmDashboard() {
    const data = await this.dashboardService.getCrmDashboard();
    return {
      success: true,
      message: 'CRM dashboard metrics retrieved',
      data,
    };
  }

  @RequirePermissions('analytics.view')
  @Get('management')
  async getManagementDashboard() {
    const data = await this.dashboardService.getManagementDashboard();
    return {
      success: true,
      message: 'Management dashboard metrics retrieved',
      data,
    };
  }

  @RequirePermissions('analytics.view')
  @Get('role/:role/:section')
  async getRoleSectionDashboard(
    @Param('role') role: string,
    @Param('section') section: string,
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const data = await this.dashboardService.getRoleSectionDashboard(
      role,
      section,
      principal?.principalType === 'CUSTOMER' && principal.customerId
        ? BigInt(principal.customerId)
        : customerId?.trim()
          ? BigInt(customerId)
          : undefined,
    );
    return {
      success: true,
      message: `Role ${role} section ${section} metrics retrieved`,
      data,
    };
  }
}
