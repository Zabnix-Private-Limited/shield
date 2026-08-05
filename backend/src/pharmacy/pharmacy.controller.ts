import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { PharmacyService } from './pharmacy.service';

@Controller()
export class PharmacyController {
  constructor(
    private pharmacyService: PharmacyService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  @RequirePermissions('providers.update')
  @Post('products')
  async createProduct(@Body() body: any) {
    const prod = await this.pharmacyService.createProduct(body);
    return {
      success: true,
      message: 'Product created successfully',
      data: prod,
    };
  }

  @RequirePermissions('providers.view')
  @Get('products/search')
  async searchProducts(@Query('query') query?: string) {
    const prods = await this.pharmacyService.searchProducts(query);
    return {
      success: true,
      message: 'Product catalog search completed',
      data: prods,
    };
  }

  @RequirePermissions('providers.view')
  @Get('wellness/products')
  async listWellnessProducts() {
    return {
      success: true,
      message: 'Wellness catalog retrieved',
      data: await this.pharmacyService.listWellnessProducts(),
    };
  }

  @RequirePermissions('customers.view')
  @Get('customer/wellness-products')
  async listCustomerWellnessProducts(
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType !== 'CUSTOMER' || !principal.customerId) {
      throw new ForbiddenException(
        'Only authenticated customers can browse the customer wellness catalogue.',
      );
    }

    return {
      success: true,
      message: 'Customer wellness catalog retrieved',
      data: await this.pharmacyService.listWellnessProducts(),
    };
  }

  @RequirePermissions('providers.view')
  @Get('products/:id')
  async getProduct(@Param('id') id: string) {
    const prod = await this.pharmacyService.getProduct(BigInt(id));
    return {
      success: true,
      message: 'Product details retrieved',
      data: prod,
    };
  }

  @RequirePermissions('providers.create')
  @Post('pharmacy/purchases')
  async createPurchase(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessCustomer(
      BigInt(body.customer_id),
      principal,
    );
    const staffId = body.staff_user_id ? BigInt(body.staff_user_id) : undefined;
    const itemsMapped = (body.items || []).map((i: any) => ({
      productId: BigInt(i.product_id),
      quantity: Number(i.quantity || 1),
      unitPrice: Number(i.unit_price || 0),
    }));

    const purchase = await this.pharmacyService.createPurchase({
      customerId: BigInt(body.customer_id),
      providerId: BigInt(body.provider_id),
      invoiceNumber: body.invoice_number || `INV-${Date.now()}`,
      items: itemsMapped,
      staffUserId: staffId,
    });

    return {
      success: true,
      message: 'Purchase recorded and wallet debited successfully',
      data: purchase,
    };
  }

  @RequirePermissions('providers.view')
  @Get('pharmacy/purchases')
  async listPurchases(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType === 'CUSTOMER' && !principal.customerId) {
      throw new ForbiddenException('Authenticated customer context is required.');
    }
    const targetCustomerId =
      principal?.principalType === 'CUSTOMER'
        ? BigInt(principal.customerId!)
        : customerId
          ? BigInt(customerId)
          : undefined;
    if (targetCustomerId) {
      await this.providerScopeService.assertProviderCanAccessCustomer(
        targetCustomerId,
        principal,
      );
    }
    const purchases = await this.pharmacyService.listPurchases(
      targetCustomerId,
      principal,
    );
    return {
      success: true,
      message: 'Purchase logs retrieved',
      data: purchases,
    };
  }
}
