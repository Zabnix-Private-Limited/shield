import { Controller, Get, Query } from '@nestjs/common';
import { RequirePermissions } from '../auth/permissions.decorator';
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
  ) {
    const data = await this.operationsQueueService.getProviderWorkspace({
      providerId: providerId ? BigInt(providerId) : undefined,
      providerType: providerType?.trim() || undefined,
      businessId: businessId ? BigInt(businessId) : undefined,
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
}
