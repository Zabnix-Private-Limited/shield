import { Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { OperationsQueueService } from './operations-queue.service';

@Controller('operations-queue')
export class OperationsQueueController {
  constructor(
    private readonly operationsQueueService: OperationsQueueService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  @RequirePermissions('providers.view')
  @Get('provider')
  async getProviderWorkspace(
    @Query('provider_id') providerId?: string,
    @Query('provider_type') providerType?: string,
    @Query('business_id') businessId?: string,
    @Query('limit') limit?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const scopedQuery = this.providerScopeService.resolveWorkspaceScope(principal, {
      providerId,
      providerType,
      businessId,
    });
    const data = await this.operationsQueueService.getProviderWorkspace({
      providerId: scopedQuery.providerId,
      providerType: scopedQuery.providerType,
      businessId: scopedQuery.businessId,
      limit: limit ? Number(limit) : undefined,
    });
    return {
      success: true,
      message: 'Provider queue retrieved successfully.',
      data,
    };
  }

  @RequirePermissions('crm.view')
  @Get('crm')
  async getCrmQueue(
    @Query('assigned_to') assignedTo?: string,
    @Query('customer_id') customerId?: string,
    @Query('limit') limit?: string,
  ) {
    const data = await this.operationsQueueService.getCrmQueue({
      assignedTo: assignedTo ? BigInt(assignedTo) : undefined,
      customerId: customerId ? BigInt(customerId) : undefined,
      limit: limit ? Number(limit) : undefined,
    });
    return {
      success: true,
      message: 'CRM operations queue retrieved successfully.',
      data,
    };
  }

  @RequirePermissions('analytics.view')
  @Get('admin')
  async getAdminQueue(
    @Query('business_id') businessId?: string,
    @Query('limit') limit?: string,
  ) {
    const data = await this.operationsQueueService.getAdminQueue({
      businessId: businessId ? BigInt(businessId) : undefined,
      limit: limit ? Number(limit) : undefined,
    });
    return {
      success: true,
      message: 'Admin operations queue retrieved successfully.',
      data,
    };
  }

}
