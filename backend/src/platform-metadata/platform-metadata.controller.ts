import { Controller, Get, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { PlatformMetadataService } from './platform-metadata.service';

@Controller('platform')
export class PlatformMetadataController {
  constructor(private readonly platformMetadataService: PlatformMetadataService) {}

  @RequirePermissions('providers.view')
  @Get('workspace/provider')
  async getProviderWorkspaceMetadata(
    @Query('provider_id') providerId?: string,
    @Query('provider_type') providerType?: string,
    @Query('business_id') businessId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const scopedQuery = this.resolveProviderScope(principal, {
      providerId,
      providerType,
      businessId,
    });
    const data = await this.platformMetadataService.getProviderWorkspaceMetadata(
      {
        providerId: scopedQuery.providerId,
        providerType: scopedQuery.providerType,
        businessId: scopedQuery.businessId,
      },
      principal,
    );
    return {
      success: true,
      message: 'Provider platform metadata retrieved successfully.',
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
