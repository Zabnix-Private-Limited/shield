import { Controller, Get, Param, Query } from '@nestjs/common';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get('customer')
  async getCustomerDashboard(@Query('customer_id') customerId?: string) {
    const id = customerId ? BigInt(customerId) : BigInt(1);
    const data = await this.dashboardService.getCustomerDashboard(id);
    return {
      success: true,
      message: 'Customer dashboard metrics retrieved',
      data,
    };
  }

  @Get('staff')
  async getStaffDashboard() {
    const data = await this.dashboardService.getStaffDashboard();
    return {
      success: true,
      message: 'Staff dashboard metrics retrieved',
      data,
    };
  }

  @Get('crm')
  async getCrmDashboard() {
    const data = await this.dashboardService.getCrmDashboard();
    return {
      success: true,
      message: 'CRM dashboard metrics retrieved',
      data,
    };
  }

  @Get('management')
  async getManagementDashboard() {
    const data = await this.dashboardService.getManagementDashboard();
    return {
      success: true,
      message: 'Management dashboard metrics retrieved',
      data,
    };
  }

  @Get('role/:role/:section')
  async getRoleSectionDashboard(
    @Param('role') role: string,
    @Param('section') section: string,
    @Query('customer_id') customerId?: string,
  ) {
    const id = customerId ? BigInt(customerId) : BigInt(1);
    const data = await this.dashboardService.getRoleSectionDashboard(
      role,
      section,
      id,
    );
    return {
      success: true,
      message: `Role ${role} section ${section} metrics retrieved`,
      data,
    };
  }
}
