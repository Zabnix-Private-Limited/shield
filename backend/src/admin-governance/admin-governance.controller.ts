import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import {
  AdminGovernanceService,
  AdminGovernanceSettingsMutation,
  AdminGovernanceWorkspaceQuery,
} from './admin-governance.service';

@Controller('admin/workspaces')
export class AdminGovernanceController {
  constructor(
    private readonly adminGovernanceService: AdminGovernanceService,
  ) {}

  @RequirePermissions('settings.view')
  @Get('settings')
  async getSettingsWorkspace(
    @Query() query: Record<string, string | undefined>,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin settings workspace retrieved successfully.',
      data: await this.adminGovernanceService.getSettingsWorkspace(
        this.parseQuery(query),
        principal,
      ),
    };
  }

  @RequirePermissions('settings.update')
  @Patch('settings/:code')
  async updateSetting(
    @Param('code') code: string,
    @Body() body: Record<string, unknown>,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin setting updated successfully.',
      data: await this.adminGovernanceService.updateSetting(
        code,
        this.parseSettingsMutation(body),
        principal,
      ),
    };
  }

  @RequirePermissions('platform.view')
  @Get('platform')
  async getPlatformWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin platform workspace retrieved successfully.',
      data: await this.adminGovernanceService.getPlatformWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('analytics.view')
  @Get('dashboard')
  async getDashboardWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin dashboard workspace retrieved successfully.',
      data: await this.adminGovernanceService.getDashboardWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('customers')
  async getCustomersWorkspace(
    @Query() query: Record<string, string | undefined>,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin customers workspace retrieved successfully.',
      data: await this.adminGovernanceService.getCustomersWorkspace(
        this.parseQuery(query),
        principal,
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('customers/forms/:formId')
  async getCustomerWorkspaceForm(
    @Param('formId') formId: string,
    @Query() query: Record<string, string | undefined>,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin customer workspace form retrieved successfully.',
      data: await this.adminGovernanceService.getCustomerWorkspaceForm(
        formId,
        this.normalizeString(query.record_id),
        principal,
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Post('customers/actions/:actionId')
  async executeCustomerWorkspaceAction(
    @Param('actionId') actionId: string,
    @Body() body: Record<string, unknown>,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin customer workspace action executed successfully.',
      data: await this.adminGovernanceService.executeCustomerWorkspaceAction(
        actionId,
        body,
        principal,
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Post('customers/bulk-actions/:actionId')
  async executeCustomerWorkspaceBulkAction(
    @Param('actionId') actionId: string,
    @Body() body: Record<string, unknown>,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin customer workspace bulk action executed successfully.',
      data: await this.adminGovernanceService.executeCustomerWorkspaceBulkAction(
        actionId,
        body,
        principal,
      ),
    };
  }

  @RequirePermissions('agents.view')
  @Get('agents')
  async getAgentsWorkspace(@Query() query: Record<string, string | undefined>) {
    return {
      success: true,
      message: 'Admin agents workspace retrieved successfully.',
      data: await this.adminGovernanceService.getAgentsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('agents.view')
  @Get('agents/performance/:code')
  async getAgentProfilePerformance(@Param('code') code: string) {
    return {
      success: true,
      message: 'Agent profile performance details retrieved successfully.',
      data: await this.adminGovernanceService.getAgentProfilePerformance(code),
    };
  }

  @RequirePermissions('agents.view')
  @Get('agents/forms/:formId')
  async getAgentWorkspaceForm(
    @Param('formId') formId: string,
    @Query() query: Record<string, string | undefined>,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin agent workspace form retrieved successfully.',
      data: await this.adminGovernanceService.getAgentWorkspaceForm(
        formId,
        this.normalizeString(query.record_id),
        principal,
      ),
    };
  }

  @RequirePermissions('agents.create')
  @Post('agents/actions/:actionId')
  async executeAgentWorkspaceAction(
    @Param('actionId') actionId: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Admin agent workspace action executed successfully.',
      data: await this.adminGovernanceService.executeAgentWorkspaceAction(
        actionId,
        body,
        principal,
      ),
    };
  }

  @RequirePermissions('crm.view')
  @Get('crm')
  async getCrmWorkspace(@Query() query: Record<string, string | undefined>) {
    return {
      success: true,
      message: 'Admin CRM workspace retrieved successfully.',
      data: await this.adminGovernanceService.getCrmWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('visits.view')
  @Get('visits')
  async getVisitsWorkspace(@Query() query: Record<string, string | undefined>) {
    return {
      success: true,
      message: 'Admin visits workspace retrieved successfully.',
      data: await this.adminGovernanceService.getVisitsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('documents.view')
  @Get('documents')
  async getDocumentsWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin documents workspace retrieved successfully.',
      data: await this.adminGovernanceService.getDocumentsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('memberships.view')
  @Get('memberships')
  async getMembershipsWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin memberships workspace retrieved successfully.',
      data: await this.adminGovernanceService.getMembershipsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('wallet.view')
  @Get('wallet')
  async getWalletWorkspace(@Query() query: Record<string, string | undefined>) {
    return {
      success: true,
      message: 'Admin wallet workspace retrieved successfully.',
      data: await this.adminGovernanceService.getWalletWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('rewards.view')
  @Get('rewards')
  async getRewardsWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin rewards workspace retrieved successfully.',
      data: await this.adminGovernanceService.getRewardsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('referrals.view')
  @Get('referrals')
  async getReferralsWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin referrals workspace retrieved successfully.',
      data: await this.adminGovernanceService.getReferralsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('providers.view')
  @Get('providers')
  async getProvidersWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin providers workspace retrieved successfully.',
      data: await this.adminGovernanceService.getProvidersWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('services.view')
  @Get('services')
  async getServicesWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin services workspace retrieved successfully.',
      data: await this.adminGovernanceService.getServicesWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('availability.view')
  @Get('availability')
  async getAvailabilityWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin availability workspace retrieved successfully.',
      data: await this.adminGovernanceService.getAvailabilityWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('branches.view')
  @Get('branches')
  async getBranchesWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin branches workspace retrieved successfully.',
      data: await this.adminGovernanceService.getBranchesWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('employees.view')
  @Get('employees')
  async getEmployeesWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin employees workspace retrieved successfully.',
      data: await this.adminGovernanceService.getEmployeesWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('roles.view')
  @Get('roles')
  async getRolesWorkspace(@Query() query: Record<string, string | undefined>) {
    return {
      success: true,
      message: 'Admin roles workspace retrieved successfully.',
      data: await this.adminGovernanceService.getRolesWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('reports.view')
  @Get('reports')
  async getReportsWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin reports workspace retrieved successfully.',
      data: await this.adminGovernanceService.getReportsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('analytics.view')
  @Get('insights')
  async getInsightsWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin insights workspace retrieved successfully.',
      data: await this.adminGovernanceService.getInsightsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('audit.view')
  @Get('audit')
  async getAuditWorkspace(@Query() query: Record<string, string | undefined>) {
    return {
      success: true,
      message: 'Admin audit workspace retrieved successfully.',
      data: await this.adminGovernanceService.getAuditWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  @RequirePermissions('notifications.view')
  @Get('notifications')
  async getNotificationsWorkspace(
    @Query() query: Record<string, string | undefined>,
  ) {
    return {
      success: true,
      message: 'Admin notifications workspace retrieved successfully.',
      data: await this.adminGovernanceService.getNotificationsWorkspace(
        this.parseQuery(query),
      ),
    };
  }

  private parseQuery(
    query: Record<string, string | undefined>,
  ): AdminGovernanceWorkspaceQuery {
    return {
      search: this.normalizeString(query.search),
      status: this.normalizeString(query.status),
      tab: this.normalizeString(query.tab),
      selectedId: this.normalizeString(query.selected_id),
      sortKey: this.normalizeString(query.sort_key),
      sortDirection: this.normalizeSortDirection(query.sort_direction),
      page: this.parsePositiveInt(query.page, 1),
      pageSize: this.parsePositiveInt(query.page_size, 25),
    };
  }

  private parseSettingsMutation(
    body: Record<string, unknown>,
  ): AdminGovernanceSettingsMutation {
    return {
      valueType: this.normalizeRequiredString(body.value_type, 'value_type'),
      valueText: this.normalizeString(body.value_text),
      valueNumber: this.normalizeNumber(body.value_number),
      valueBoolean: this.normalizeBoolean(body.value_boolean),
      status: this.normalizeString(body.status) ?? 'ACTIVE',
    };
  }

  private parsePositiveInt(value: unknown, fallback: number) {
    const parsed = Number.parseInt(`${value ?? ''}`.trim(), 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
  }

  private normalizeRequiredString(value: unknown, field: string) {
    const normalized = this.normalizeString(value);
    if (normalized == null) {
      throw new Error(`${field} is required.`);
    }
    return normalized;
  }

  private normalizeString(value: unknown) {
    const normalized = `${value ?? ''}`.trim();
    return normalized.length == 0 ? null : normalized;
  }

  private normalizeNumber(value: unknown) {
    if (value == null || `${value}`.trim().length == 0) {
      return null;
    }
    const parsed = Number(`${value}`.trim());
    if (!Number.isFinite(parsed)) {
      throw new Error('value_number must be numeric.');
    }
    return parsed;
  }

  private normalizeBoolean(value: unknown) {
    if (value == null || `${value}`.trim().length == 0) {
      return null;
    }
    if (typeof value === 'boolean') {
      return value;
    }
    const normalized = `${value}`.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    throw new Error('value_boolean must be boolean-like.');
  }

  private normalizeSortDirection(value: unknown): 'asc' | 'desc' | null {
    const normalized = this.normalizeString(value)?.toLowerCase();
    if (normalized == null) {
      return null;
    }
    if (normalized == 'asc' || normalized == 'desc') {
      return normalized;
    }
    return null;
  }
}
