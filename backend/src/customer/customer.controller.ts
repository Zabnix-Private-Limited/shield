import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { CustomerService } from './customer.service';

@Controller('customers')
export class CustomerController {
  constructor(private customerService: CustomerService) {}

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

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const customer = await this.customerService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Customer details retrieved',
      data: customer,
    };
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    const customer = await this.customerService.update(BigInt(id), body);
    return {
      success: true,
      message: 'Customer profile updated successfully',
      data: customer,
    };
  }

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
