import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PharmacyService } from './pharmacy.service';
import { MockAuthGuard } from '../auth/mock-auth.guard';

@Controller()
@UseGuards(MockAuthGuard)
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
  async createPurchase(@Body() body: any, @Request() req: any) {
    const staffId = req.user.isStaff ? BigInt(req.user.id) : undefined;
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
  async listPurchases(@Request() req: any, @Query('customer_id') customerId?: string) {
    let targetCustomerId: bigint | undefined = undefined;

    if (!req.user.isStaff) {
      targetCustomerId = BigInt(req.user.id);
    } else if (customerId) {
      targetCustomerId = BigInt(customerId);
    }

    const purchases = await this.pharmacyService.listPurchases(targetCustomerId);
    return {
      success: true,
      message: 'Purchase logs retrieved',
      data: purchases,
    };
  }
}
