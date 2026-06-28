import {
  Controller,
  ForbiddenException,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CustomerService } from './customer.service';

@Controller('customers')
export class CustomerController {
  constructor(private customerService: CustomerService) {}

  @RequirePermissions('customers.create')
  @Post()
  async create(@Body() body: any) {
    const staffId = body.created_by ? BigInt(body.created_by) : undefined;
    const customer = await this.customerService.create(body, staffId);
    return {
      success: true,
      message: 'Customer created successfully',
      data: customer,
    };
  }

  @RequirePermissions('customers.view')
  @Get('search')
  async search(
    @Query('mobile') mobile?: string,
    @Query('name') name?: string,
    @Query('aadhaar') aadhaar?: string,
    @Query('membership') membership?: string,
  ) {
    const results = await this.customerService.search({
      mobile,
      name,
      aadhaar,
      membership,
    });
    return {
      success: true,
      message: 'Search completed',
      data: results,
    };
  }

  @RequirePermissions('customers.view')
  @Get('me')
  async me(@CurrentPrincipal() principal?: ShieldPrincipal) {
    if (!principal?.customerId) {
      throw new ForbiddenException('Only customers can use /customers/me.');
    }

    const customer = await this.customerService.findOne(BigInt(principal.customerId));
    return {
      success: true,
      message: 'Customer details retrieved',
      data: customer,
    };
  }

  @RequirePermissions('customers.view')
  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (
      principal?.principalType === 'CUSTOMER' &&
      principal.customerId !== id
    ) {
      throw new ForbiddenException('Customers can only view their own profile.');
    }

    const customer = await this.customerService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Customer details retrieved',
      data: customer,
    };
  }

  @RequirePermissions('customers.update')
  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (
      principal?.principalType === 'CUSTOMER' &&
      principal.customerId !== id
    ) {
      throw new ForbiddenException('Customers can only update their own profile.');
    }

    const customer = await this.customerService.update(BigInt(id), body);
    return {
      success: true,
      message: 'Customer profile updated successfully',
      data: customer,
    };
  }

  @RequirePermissions('customers.approve')
  @Post(':id/approve')
  async approve(@Param('id') id: string, @Body() body: any) {
    const staffId = body.staff_id ? BigInt(body.staff_id) : BigInt(1);
    const customer = await this.customerService.approve(BigInt(id), staffId);
    return {
      success: true,
      message: 'Customer onboarding approved successfully',
      data: customer,
    };
  }

  @RequirePermissions('customers.approve')
  @Post(':id/suspend')
  async suspend(@Param('id') id: string, @Body() body: any) {
    const staffId = body.staff_id ? BigInt(body.staff_id) : BigInt(1);
    const customer = await this.customerService.suspend(BigInt(id), staffId);
    return {
      success: true,
      message: 'Customer status suspended',
      data: customer,
    };
  }
}
