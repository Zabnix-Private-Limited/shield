import { Body, Controller, Get, Param, Patch, Query } from '@nestjs/common';
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
}
