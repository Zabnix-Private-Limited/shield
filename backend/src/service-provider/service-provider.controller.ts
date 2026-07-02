import {
  HttpCode,
  Controller,
  Get,
  Post,
  Patch,
  Put,
  Delete,
  Param,
  Body,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { OperationsQueueService } from '../operations-queue/operations-queue.service';
import { RequirePermissions } from '../auth/permissions.decorator';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { ServiceProviderService } from './service-provider.service';

@Controller('service-providers')
export class ServiceProviderController {
  constructor(
    private readonly serviceProviderService: ServiceProviderService,
    private readonly operationsQueueService: OperationsQueueService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  @RequirePermissions('providers.create')
  @Post()
  async create(@Body() body: any) {
    const provider = await this.serviceProviderService.create(body);
    return {
      success: true,
      message: 'Service provider created successfully.',
      data: provider,
    };
  }

  @RequirePermissions('providers.view')
  @Get()
  async findAll() {
    const providers = await this.serviceProviderService.findAll();
    return {
      success: true,
      message: 'Service providers retrieved successfully.',
      data: providers,
    };
  }

  @RequirePermissions('providers.view')
  @Get('analytics')
  async getAnalytics() {
    const analytics = await this.serviceProviderService.getAnalytics();
    return {
      success: true,
      message: 'Provider network analytics retrieved successfully.',
      data: analytics,
    };
  }

  @RequirePermissions('providers.view')
  @Get('workspace')
  async getWorkspace(
    @Query('provider_id') providerId?: string,
    @Query('provider_type') providerType?: string,
    @Query('business_id') businessId?: string,
    @Query('limit') limit?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const scope = this.providerScopeService.resolveWorkspaceScope(principal, {
      providerId,
      providerType,
      businessId,
    });
    const workspace = await this.operationsQueueService.getProviderWorkspace({
      providerId: scope.providerId,
      providerType: scope.providerType,
      businessId: scope.businessId,
      limit: limit ? Number(limit) : undefined,
    });
    return {
      success: true,
      message: 'Provider information retrieved successfully.',
      data: workspace,
    };
  }

  @RequirePermissions('providers.view')
  @Get('workspace/patients/:customerId')
  async getPatientWorkspace(
    @Param('customerId') customerId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.serviceProviderService.getPatientWorkspace(
      BigInt(customerId),
      principal,
    );
    return {
      success: true,
      message: 'Patient record retrieved successfully.',
      data: workspace,
    };
  }

  @RequirePermissions('settings.view')
  @Get('me/profile')
  async getCurrentProviderProfile(
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const profile =
      await this.serviceProviderService.getCurrentProviderProfile(principal);
    return {
      success: true,
      message: 'Provider profile retrieved successfully.',
      data: profile,
    };
  }

  @RequirePermissions('settings.update')
  @Patch('me/profile')
  async updateCurrentProviderProfile(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const profile = await this.serviceProviderService.updateCurrentProviderProfile(
      principal,
      body,
    );
    return {
      success: true,
      message: 'Provider profile updated successfully.',
      data: profile,
    };
  }

  @RequirePermissions('settings.update')
  @Patch('me/preferences')
  async updateCurrentProviderPreferences(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const profile =
      await this.serviceProviderService.updateCurrentProviderPreferences(
        principal,
        body,
      );
    return {
      success: true,
      message: 'Provider preferences updated successfully.',
      data: profile,
    };
  }

  @RequirePermissions('settings.update')
  @Post('me/profile/photo')
  @HttpCode(200)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: multer.memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadCurrentProviderPhoto(
    @UploadedFile() file: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const profile = await this.serviceProviderService.uploadCurrentProviderAsset(
      principal,
      'photo',
      file,
    );
    return {
      success: true,
      message: 'Provider profile photo updated successfully.',
      data: profile,
    };
  }

  @RequirePermissions('settings.update')
  @Post('me/profile/signature')
  @HttpCode(200)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: multer.memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadCurrentProviderSignature(
    @UploadedFile() file: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const profile = await this.serviceProviderService.uploadCurrentProviderAsset(
      principal,
      'signature',
      file,
    );
    return {
      success: true,
      message: 'Provider digital signature updated successfully.',
      data: profile,
    };
  }

  @RequirePermissions('providers.view')
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const provider = await this.serviceProviderService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Service provider details retrieved successfully.',
      data: provider,
    };
  }

  @RequirePermissions('providers.update')
  @Put(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    const provider = await this.serviceProviderService.update(BigInt(id), body);
    return {
      success: true,
      message: 'Service provider updated successfully.',
      data: provider,
    };
  }

  @RequirePermissions('providers.delete')
  @Delete(':id')
  async remove(@Param('id') id: string) {
    const provider = await this.serviceProviderService.remove(BigInt(id));
    return {
      success: true,
      message: 'Service provider deleted successfully.',
      data: provider,
    };
  }

  @RequirePermissions('providers.view')
  @Get(':id/performance')
  async getPerformance(@Param('id') id: string) {
    const stats = await this.serviceProviderService.getPerformance(BigInt(id));
    return {
      success: true,
      message: 'Service provider performance metrics retrieved successfully.',
      data: stats,
    };
  }
}
