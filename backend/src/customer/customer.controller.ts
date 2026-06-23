import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { CustomerService } from './customer.service';
import { MockAuthGuard } from '../auth/mock-auth.guard';

@Controller('customers')
@UseGuards(MockAuthGuard)
export class CustomerController {
  constructor(private customerService: CustomerService) {}

  @Post()
  async create(@Body() body: any, @Request() req: any) {
    const customer = await this.customerService.create(
      body,
      req.user.isStaff ? BigInt(req.user.id) : undefined,
    );
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
  async approve(@Param('id') id: string, @Request() req: any) {
    const staffId = req.user.isStaff ? BigInt(req.user.id) : BigInt(1); // fallback to ID 1 if not staff
    const customer = await this.customerService.approve(BigInt(id), staffId);
    return {
      success: true,
      message: 'Customer onboarding approved successfully',
      data: customer,
    };
  }

  @Post(':id/suspend')
  async suspend(@Param('id') id: string, @Request() req: any) {
    const staffId = req.user.isStaff ? BigInt(req.user.id) : BigInt(1);
    const customer = await this.customerService.suspend(BigInt(id), staffId);
    return {
      success: true,
      message: 'Customer status suspended',
      data: customer,
    };
  }
}
