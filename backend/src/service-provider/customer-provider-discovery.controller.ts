import { Controller, ForbiddenException, Get, Param, Query } from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { RequirePermissions } from '../auth/permissions.decorator';
import { ServiceProviderService } from './service-provider.service';

@Controller('customer/providers')
export class CustomerProviderDiscoveryController {
  constructor(
    private readonly serviceProviderService: ServiceProviderService,
  ) {}

  private assertCustomer(principal?: ShieldPrincipal) {
    if (!principal || principal.roleCode === 'ADMIN') {
      return;
    }
    if (principal.principalType !== 'CUSTOMER' || !principal.customerId) {
      throw new ForbiddenException('Authenticated customer context is required.');
    }
  }

  @RequirePermissions('customers.view')
  @Get('categories')
  async categories(@CurrentPrincipal() principal?: ShieldPrincipal) {
    this.assertCustomer(principal);
    return {
      success: true,
      message: 'Customer service categories retrieved successfully.',
      data: await this.serviceProviderService.listCustomerProviderCategories(),
    };
  }

  @RequirePermissions('customers.view')
  @Get()
  async list(
    @CurrentPrincipal() principal?: ShieldPrincipal,
    @Query('query') query?: string,
    @Query('type') type?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    this.assertCustomer(principal);
    return {
      success: true,
      message: 'Customer providers retrieved successfully.',
      data: await this.serviceProviderService.listCustomerProviders({
        query,
        type,
        page,
        pageSize,
      }),
    };
  }

  @RequirePermissions('customers.view')
  @Get(':id')
  async detail(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    this.assertCustomer(principal);
    return {
      success: true,
      message: 'Customer provider details retrieved successfully.',
      data: await this.serviceProviderService.getCustomerProvider(BigInt(id)),
    };
  }
}
