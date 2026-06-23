import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { PharmacyService } from './pharmacy.service';

@Controller()
export class PharmacyController {
  constructor(private pharmacyService: PharmacyService) {}

  @Post('products')
  async createProduct(@Body() body: any) {
    const prod = await this.pharmacyService.createProduct(body);
    return {
      success: true,
      message: 'Product created successfully',
      data: prod,
    };
  }

  @Get('products/search')
  async searchProducts(@Query('query') query?: string) {
    const prods = await this.pharmacyService.searchProducts(query);
    return {
      success: true,
      message: 'Product catalog search completed',
      data: prods,
    };
  }

  @Get('products/:id')
  async getProduct(@Param('id') id: string) {
    const prod = await this.pharmacyService.getProduct(BigInt(id));
    return {
      success: true,
      message: 'Product details retrieved',
      data: prod,
    };
  }

  @Post('pharmacy/purchases')
  async createPurchase(@Body() body: any) {
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

  @Get('pharmacy/purchases')
  async listPurchases(@Query('customer_id') customerId?: string) {
    const targetCustomerId = customerId ? BigInt(customerId) : undefined;
    const purchases = await this.pharmacyService.listPurchases(targetCustomerId);
    return {
      success: true,
      message: 'Purchase logs retrieved',
      data: purchases,
    };
  }
}
