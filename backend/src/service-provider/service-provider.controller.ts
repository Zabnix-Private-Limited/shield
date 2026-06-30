import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { OperationsQueueService } from '../operations-queue/operations-queue.service';
import { RequirePermissions } from '../auth/permissions.decorator';
import { ServiceProviderService } from './service-provider.service';

@Controller('service-providers')
export class ServiceProviderController {
  constructor(
    private readonly serviceProviderService: ServiceProviderService,
    private readonly operationsQueueService: OperationsQueueService,
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
  ) {
    const workspace = await this.operationsQueueService.getProviderWorkspace({
      providerId: providerId ? BigInt(providerId) : undefined,
      providerType: providerType?.trim() || undefined,
      businessId: businessId ? BigInt(businessId) : undefined,
      limit: limit ? Number(limit) : undefined,
    });
    return {
      success: true,
      message: 'Provider workspace retrieved successfully.',
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
      message: 'Provider patient workspace retrieved successfully.',
      data: workspace,
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
