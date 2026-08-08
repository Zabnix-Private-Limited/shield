import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Put,
  Post,
  ForbiddenException,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CustomerService } from './customer.service';

@Controller('customer')
export class CustomerAccountController {
  constructor(private readonly customerService: CustomerService) {}

  private customerId(principal?: ShieldPrincipal) {
    if (principal?.principalType !== 'CUSTOMER' || !principal.customerId) {
      throw new ForbiddenException('Customer session required.');
    }
    return BigInt(principal.customerId);
  }

  private resourceId(value: string) {
    if (!/^\d+$/.test(value))
      throw new BadRequestException('Invalid resource id.');
    return BigInt(value);
  }

  @RequirePermissions('customers.view')
  @Get('profile')
  async profile(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      data: await this.customerService.getCustomerSelfProfile(
        this.customerId(principal),
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Patch('profile')
  async updateProfile(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.updateCustomerSelfProfile(
        this.customerId(principal),
        body,
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('addresses')
  async addresses(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      data: await this.customerService.listAddresses(
        this.customerId(principal),
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('addresses/:id')
  async address(@Param('id') id: string, @CurrentPrincipal() principal?: ShieldPrincipal) {
    return { success: true, data: await this.customerService.getAddress(this.customerId(principal), this.resourceId(id)) };
  }

  @RequirePermissions('customers.update')
  @Post('addresses')
  async createAddress(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.saveAddress(
        this.customerId(principal),
        body,
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Patch('addresses/:id')
  async updateAddress(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.saveAddress(this.customerId(principal), {
        ...body,
        id: this.resourceId(id),
      }),
    };
  }

  @RequirePermissions('customers.update')
  @Delete('addresses/:id')
  async removeAddress(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.customerService.removeAddress(
      this.customerId(principal),
      this.resourceId(id),
    );
    return { success: true };
  }

  @RequirePermissions('customers.view')
  @Get('dependents')
  async dependents(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      data: await this.customerService.listDependents(
        this.customerId(principal),
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('dependents/:id')
  async dependent(@Param('id') id: string, @CurrentPrincipal() principal?: ShieldPrincipal) {
    return { success: true, data: await this.customerService.getDependent(this.customerId(principal), this.resourceId(id)) };
  }

  @RequirePermissions('customers.update')
  @Post('dependents')
  async createDependent(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.saveDependent(
        this.customerId(principal),
        body,
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Patch('dependents/:id')
  async updateDependent(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.saveDependent(
        this.customerId(principal),
        { ...body, id: this.resourceId(id) },
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Delete('dependents/:id')
  async removeDependent(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.customerService.removeDependent(
      this.customerId(principal),
      this.resourceId(id),
    );
    return { success: true };
  }

  @RequirePermissions('customers.view')
  @Get('contacts')
  async contacts(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      data: await this.customerService.listContacts(this.customerId(principal)),
    };
  }

  @RequirePermissions('customers.view')
  @Get('contacts/:id')
  async contact(@Param('id') id: string, @CurrentPrincipal() principal?: ShieldPrincipal) {
    return { success: true, data: await this.customerService.getContact(this.customerId(principal), this.resourceId(id)) };
  }

  @RequirePermissions('customers.update')
  @Post('contacts')
  async createContact(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.saveContact(
        this.customerId(principal),
        body,
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Patch('contacts/:id')
  async updateContact(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.saveContact(this.customerId(principal), {
        ...body,
        id: this.resourceId(id),
      }),
    };
  }

  @RequirePermissions('customers.update')
  @Delete('contacts/:id')
  async removeContact(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.customerService.removeContact(
      this.customerId(principal),
      this.resourceId(id),
    );
    return { success: true };
  }

  @RequirePermissions('customers.view')
  @Get('preferences')
  async preferences(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      data: await this.customerService.getPreferences(
        this.customerId(principal),
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Patch('preferences')
  async updatePreferences(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.savePreferences(
        this.customerId(principal),
        body,
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('pharmacies')
  async pharmacies() {
    return {
      success: true,
      data: await this.customerService.listEligiblePharmacies(),
    };
  }

  @RequirePermissions('customers.view')
  @Get('preferred-provider')
  async preferredProvider(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      data: await this.customerService.getPreferredProvider(
        this.customerId(principal),
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Put('preferred-provider')
  async setPreferredProvider(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const providerId =
      body.providerId == null ? null : this.resourceId(String(body.providerId));
    return {
      success: true,
      data: await this.customerService.setPreferredProvider(
        this.customerId(principal),
        providerId,
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Delete('preferred-provider')
  async removePreferredProvider(
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      data: await this.customerService.setPreferredProvider(
        this.customerId(principal),
        null,
      ),
    };
  }
}
