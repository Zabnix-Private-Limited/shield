import { Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { OperationsQueueService } from './operations-queue.service';

@Controller('operations-queue')
export class OperationsQueueController {
  constructor(
    private readonly operationsQueueService: OperationsQueueService,
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
    const scopedQuery = this.resolveProviderScope(principal, {
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
      message: 'Provider workspace queue retrieved successfully.',
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

  private resolveProviderScope(
    principal: ShieldPrincipal | undefined,
    query: {
      providerId?: string;
      providerType?: string;
      businessId?: string;
    },
  ) {
    const providerId = query.providerId?.trim()
      ? BigInt(query.providerId.trim())
      : undefined;
    const explicitProviderType = query.providerType?.trim() || undefined;
    const explicitBusinessId = query.businessId?.trim()
      ? BigInt(query.businessId.trim())
      : undefined;

    if (
      principal?.principalType !== 'USER' ||
      principal.userType !== 'SERVICE_PROVIDER'
    ) {
      return {
        providerId,
        providerType: explicitProviderType,
        businessId: explicitBusinessId,
      };
    }

    return {
      providerId,
      providerType:
        explicitProviderType ?? this.mapRoleCodeToProviderType(principal.roleCode),
      businessId:
        explicitBusinessId ??
        (principal.branchBusinessId?.trim()
          ? BigInt(principal.branchBusinessId.trim())
          : undefined),
    };
  }

  private mapRoleCodeToProviderType(roleCode?: string) {
    switch (roleCode?.trim().toUpperCase()) {
      case 'PHARMACY_PROVIDER':
        return 'PHARMACY';
      case 'LAB_PROVIDER':
        return 'LABORATORY';
      case 'DOCTOR':
        return 'CLINIC';
      case 'HOMECARE_PROVIDER':
        return 'HOME_VISIT';
      case 'DENTAL_PROVIDER':
        return 'DENTAL';
      case 'COSMETIC_PROVIDER':
        return 'COSMETIC';
      case 'DIETITIAN':
        return 'DIETITIAN';
      default:
        return undefined;
    }
  }
}
