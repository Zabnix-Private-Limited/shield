import { Controller, Get, Param, UseGuards, Request } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { MockAuthGuard } from '../auth/mock-auth.guard';

@Controller('dashboard')
@UseGuards(MockAuthGuard)
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get('customer')
  async getCustomerDashboard(@Request() req: any) {
    const customerId = BigInt(req.user.id);
    const data = await this.dashboardService.getCustomerDashboard(customerId);
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
    @Request() req: any,
  ) {
    // Falls back to mock customer ID if not staff, or resolves the active user ID
    const customerId = BigInt(req.user.id);
    const data = await this.dashboardService.getRoleSectionDashboard(
      role,
      section,
      customerId,
    );
    return {
      success: true,
      message: `Role ${role} section ${section} metrics retrieved`,
      data,
    };
  }
}
