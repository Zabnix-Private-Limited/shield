import {
  Body,
  BadRequestException,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import type { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { Public } from '../auth/public.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { PharmacyService } from './pharmacy.service';
import { PharmacyPaymentDetailsService } from './pharmacy-payment-details.service';
import { PharmacyPaymentsService } from './pharmacy-payments.service';
import {
  CreateBankAccountDto,
  CreateUpiDto,
  UpdateBankAccountDto,
  UpdateUpiDto,
} from './dto/pharmacy-payment-details.dto';
import { RejectPaymentDto, SubmitManualPaymentDto } from './dto/pharmacy-payments.dto';
import { PharmacySettingsDto } from './dto/pharmacy-settings.dto';

@Controller()
export class PharmacyController {
  constructor(
    private pharmacyService: PharmacyService,
    private paymentDetailsService: PharmacyPaymentDetailsService,
    private paymentsService: PharmacyPaymentsService,
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

  private requireCustomer(principal?: ShieldPrincipal) {
    if (principal?.principalType !== 'CUSTOMER' || !principal.customerId) {
      throw new ForbiddenException(
        'Authenticated customer context is required.',
      );
    }
    return BigInt(principal.customerId);
  }

  private parseId(value: unknown, label: string) {
    const normalized = String(value ?? '').trim();
    if (!/^\d+$/.test(normalized)) {
      throw new BadRequestException(`${label} is required.`);
    }
    return BigInt(normalized);
  }

  @RequirePermissions('documents.create')
  @Post('pharmacy/prescriptions')
  async submitCustomerPrescription(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const request =
      await this.pharmacyService.createCustomerPrescriptionRequest({
        customerId: this.requireCustomer(principal),
        documentId: this.parseId(body.document_id, 'Prescription document ID'),
        providerId: this.parseId(body.provider_id, 'Pharmacy provider ID'),
        customerNotes: String(body.customer_notes ?? '').trim() || undefined,
      });
    return {
      success: true,
      message: 'Prescription request submitted to the selected pharmacy.',
      data: request,
    };
  }

  @RequirePermissions('documents.view')
  @Get('pharmacy/prescriptions')
  async listCustomerPrescriptionRequests(
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const requests =
      await this.pharmacyService.listCustomerPrescriptionRequests(
        this.requireCustomer(principal),
      );
    return {
      success: true,
      message: 'Prescription pharmacy requests retrieved.',
      data: requests,
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

  // Public catalogue projections intentionally contain no inventory, provider,
  // customer, or ordering data. Checkout remains customer-authenticated.
  @Public()
  @Get('wellness-products')
  async listPublicWellnessProducts(
    @Query('query') query?: string,
    @Query('categoryId') categoryId?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return {
      success: true,
      data: await this.pharmacyService.listCustomerWellnessProducts({
        query,
        categoryId,
        page,
        pageSize,
      }),
    };
  }

  @Public()
  @Get('wellness-products/:id')
  async getPublicWellnessProduct(@Param('id') id: string) {
    return {
      success: true,
      data: await this.pharmacyService.getCustomerWellnessProduct(BigInt(id)),
    };
  }

  @RequirePermissions('customers.view')
  @Get('customer/wellness-products')
  async listCustomerWellnessProducts(
    @CurrentPrincipal() principal?: ShieldPrincipal,
    @Query('query') query?: string,
    @Query('categoryId') categoryId?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    if (principal?.principalType !== 'CUSTOMER' || !principal.customerId) {
      throw new ForbiddenException(
        'Only authenticated customers can browse the customer wellness catalogue.',
      );
    }
    return {
      success: true,
      message: 'Customer wellness catalog retrieved',
      data: await this.pharmacyService.listCustomerWellnessProducts({
        query,
        categoryId,
        page,
        pageSize,
      }),
    };
  }

  @RequirePermissions('customers.view')
  @Get('customer/wellness-products/:id')
  async getCustomerWellnessProduct(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType !== 'CUSTOMER' || !principal.customerId) {
      throw new ForbiddenException(
        'Only authenticated customers can browse the customer wellness catalogue.',
      );
    }
    return {
      success: true,
      message: 'Customer wellness product retrieved',
      data: await this.pharmacyService.getCustomerWellnessProduct(BigInt(id)),
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
      throw new ForbiddenException(
        'Authenticated customer context is required.',
      );
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

  @RequirePermissions('customers.view')
  @Get('customer/orders')
  async listCustomerOrders(
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Customer order history retrieved.',
      data: await this.pharmacyService.listCustomerOrders(
        this.requireCustomer(principal),
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('customer/orders/:id')
  async getCustomerOrder(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Customer order retrieved.',
      data: await this.pharmacyService.getCustomerOrder(
        this.requireCustomer(principal),
        this.parseId(id, 'Order ID'),
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Post('customer/orders')
  async createCustomerOrder(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const customerId = this.requireCustomer(principal);
    const orderSource = body.order_source || body.request_type || body.source;
    const documentId = body.document_id ? this.parseId(body.document_id, 'Prescription document ID') : undefined;
    const providerId = this.parseId(body.provider_id || body.pharmacy_id, 'Pharmacy provider ID');

    const itemsMapped = Array.isArray(body.items)
      ? body.items.map((i: any) => ({
          productId: i.product_id ? BigInt(i.product_id) : undefined,
          name: i.name || i.product_name,
          quantity: Number(i.quantity || 1),
          notes: i.notes,
        }))
      : undefined;

    const order = await this.pharmacyService.createCustomerOrder({
      customerId,
      providerId,
      orderSource,
      documentId,
      items: itemsMapped,
      fulfillmentPreference: body.fulfillment_preference,
      deliveryAddress: body.delivery_address,
      customerNotes: body.customer_notes,
      idempotencyKey: body.idempotency_key,
    });
    return {
      success: true,
      message: 'Order submitted to the selected pharmacy.',
      data: order,
    };
  }

  @RequirePermissions('providers.view')
  @Get('pharmacy/orders/summary')
  async getPharmacyOrdersSummary(
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Pharmacy orders summary retrieved.',
      data: await this.pharmacyService.getPharmacyOrdersSummary(principal),
    };
  }

  @RequirePermissions('providers.view')
  @Get('pharmacy/orders')
  async listPharmacyOrders(
    @Query('status') status?: string,
    @Query('source') source?: string,
    @Query('query') query?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Pharmacy order queue retrieved.',
      data: await this.pharmacyService.listPharmacyOrders({
        status,
        source,
        query,
        page,
        pageSize,
        principal,
      }),
    };
  }

  @RequirePermissions('providers.read')
  @Get('pharmacy/orders/history')
  async listPharmacyOrderHistory(
    @CurrentPrincipal() principal?: ShieldPrincipal,
    @Query('status') status?: string,
    @Query('source') source?: string,
    @Query('fulfillment') fulfillment?: string,
    @Query('search') search?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return {
      success: true,
      message: 'Pharmacy order history retrieved successfully.',
      data: await this.pharmacyService.listPharmacyOrderHistory(
        {
          status,
          source,
          fulfillment,
          search,
          from,
          to,
          page: page ? Number(page) : undefined,
          pageSize: pageSize ? Number(pageSize) : undefined,
        },
        principal,
      ),
    };
  }

  @RequirePermissions('providers.read')
  @Get('pharmacy/orders/history/:id')
  async getPharmacyOrderHistoryDetail(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Pharmacy order history detail retrieved successfully.',
      data: await this.pharmacyService.getPharmacyOrderHistoryDetail(
        this.parseId(id, 'Order ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.view')
  @Get('pharmacy/orders/:id')
  async getPharmacyOrderDetail(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Pharmacy order detail retrieved.',
      data: await this.pharmacyService.getPharmacyOrderDetail(
        this.parseId(id, 'Order ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/orders/:id/status')
  async updateOrderStatus(
    @Param('id') id: string,
    @Body() body: { status: string; cancellationReason?: string },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (!body.status?.trim()) {
      throw new BadRequestException('Status is required.');
    }
    return {
      success: true,
      message: 'Order status updated successfully.',
      data: await this.pharmacyService.updateOrderStatus(
        this.parseId(id, 'Order ID'),
        body.status,
        body.cancellationReason,
        principal,
      ),
    };
  }

  // ==========================================
  // PHASE 2: PHARMACY PAYMENT DETAILS APIs
  // ==========================================

  @RequirePermissions('providers.view')
  @Get('pharmacy/payment-details')
  async listPaymentDetails(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      message: 'Pharmacy payment details retrieved.',
      data: await this.paymentDetailsService.listPaymentMethods(principal),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/payment-details/bank-accounts')
  async createBankAccount(
    @Body() dto: CreateBankAccountDto,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Bank account added successfully.',
      data: await this.paymentDetailsService.createBankAccount(dto, principal),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/payment-details/bank-accounts/:id')
  async updateBankAccount(
    @Param('id') id: string,
    @Body() dto: UpdateBankAccountDto,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Bank account updated successfully.',
      data: await this.paymentDetailsService.updateBankAccount(
        this.parseId(id, 'Bank Account ID'),
        dto,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/payment-details/upi')
  async createUpi(
    @Body() dto: CreateUpiDto,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'UPI payment method added successfully.',
      data: await this.paymentDetailsService.createUpi(dto, principal),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/payment-details/upi/:id')
  async updateUpi(
    @Param('id') id: string,
    @Body() dto: UpdateUpiDto,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'UPI payment method updated successfully.',
      data: await this.paymentDetailsService.updateUpi(
        this.parseId(id, 'UPI ID'),
        dto,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.view')
  @Get('pharmacy/payment-details/upi/:id/qr-image')
  async getUpiQrImage(
    @Param('id') id: string,
    @Res() res: Response,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const { buffer, contentType } = await this.paymentDetailsService.getUpiQrImageStream(
      this.parseId(id, 'UPI ID'),
      principal,
    );
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.send(buffer);
  }

  @Public()
  @Get('customer/pharmacies/payment-details/upi/:id/qr-image')
  async getCustomerUpiQrImage(
    @Param('id') id: string,
    @Res() res: Response,
  ) {
    const { buffer, contentType } = await this.paymentDetailsService.getUpiQrImageStream(
      this.parseId(id, 'UPI ID'),
      undefined,
    );
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.send(buffer);
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/payment-details/upi/:id/qr')
  @UseInterceptors(FileInterceptor('file'))
  async uploadUpiQr(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'UPI QR image uploaded successfully.',
      data: await this.paymentDetailsService.uploadUpiQr(
        this.parseId(id, 'UPI ID'),
        file,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Delete('pharmacy/payment-details/upi/:id/qr')
  async removeUpiQr(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'UPI QR image removed successfully.',
      data: await this.paymentDetailsService.removeUpiQr(
        this.parseId(id, 'UPI ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/payment-details/:id/primary')
  async setPrimaryMethod(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Primary payment method updated.',
      data: await this.paymentDetailsService.setPrimaryMethod(
        this.parseId(id, 'Payment Method ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/payment-details/:id/toggle-active')
  async toggleActiveMethod(
    @Param('id') id: string,
    @Body() body: { isActive: boolean },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Payment method status updated.',
      data: await this.paymentDetailsService.toggleActiveMethod(
        this.parseId(id, 'Payment Method ID'),
        body.isActive,
        principal,
      ),
    };
  }

  @Public()
  @Get('customer/pharmacies/:providerId/payment-details')
  async getCustomerSafePaymentDetails(@Param('providerId') providerId: string) {
    return {
      success: true,
      message: 'Active pharmacy payment details retrieved.',
      data: await this.paymentDetailsService.getCustomerSafePaymentDetails(
        this.parseId(providerId, 'Provider ID'),
      ),
    };
  }

  // -------------------------------------------------------------
  // PHARMACY DASHBOARD & PHASE 3 MANUAL PAYMENTS
  // -------------------------------------------------------------

  @RequirePermissions('providers.read')
  @Get('pharmacy/dashboard')
  async getPharmacyDashboard(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      message: 'Pharmacy dashboard metrics retrieved successfully.',
      data: await this.paymentsService.getPharmacyDashboard(principal),
    };
  }

  @RequirePermissions('providers.read')
  @Get('pharmacy/payments')
  async listPayments(
    @CurrentPrincipal() principal?: ShieldPrincipal,
    @Query('status') status?: string,
    @Query('search') search?: string,
  ) {
    return {
      success: true,
      message: 'Pharmacy payments retrieved.',
      data: await this.paymentsService.listPayments(principal, { status, search }),
    };
  }

  @RequirePermissions('providers.read')
  @Get('pharmacy/payments/:id')
  async getPaymentDetail(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Payment detail retrieved.',
      data: await this.paymentsService.getPaymentDetail(
        this.parseId(id, 'Payment ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/payments/submit')
  async submitManualPayment(
    @Body() dto: SubmitManualPaymentDto,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Manual payment intent submitted.',
      data: await this.paymentsService.submitManualPayment(dto, principal),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/payments/:id/approve')
  async approvePayment(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Payment approved and customer wallet credited.',
      data: await this.paymentsService.approvePayment(
        this.parseId(id, 'Payment ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/payments/:id/reject')
  async rejectPayment(
    @Param('id') id: string,
    @Body() dto: RejectPaymentDto,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Payment request rejected.',
      data: await this.paymentsService.rejectPayment(
        this.parseId(id, 'Payment ID'),
        dto,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/orders/:id/items/:itemId')
  async updateOrderItemFulfillment(
    @Param('id') id: string,
    @Param('itemId') itemId: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Item fulfillment decision updated.',
      data: await this.pharmacyService.updateOrderItemFulfillment(
        this.parseId(id, 'Order ID'),
        this.parseId(itemId, 'Item ID'),
        body,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/orders/:id/chronic')
  async toggleChronicOrder(
    @Param('id') id: string,
    @Body() body: { isChronic: boolean; repeatIntervalDays?: number },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Chronic order status updated.',
      data: await this.pharmacyService.toggleChronicOrder(
        this.parseId(id, 'Order ID'),
        body.isChronic,
        body.repeatIntervalDays,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/orders/:id/notes')
  async savePharmacistNotes(
    @Param('id') id: string,
    @Body() body: { notes: string },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Pharmacist notes saved successfully.',
      data: await this.pharmacyService.savePharmacistNotes(
        this.parseId(id, 'Order ID'),
        body.notes,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/orders/:id/request-customer-confirmation')
  async requestCustomerConfirmation(
    @Param('id') id: string,
    @Body() body: { reason?: string },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Customer confirmation request triggered.',
      data: await this.pharmacyService.requestCustomerConfirmation(
        this.parseId(id, 'Order ID'),
        body.reason,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/orders/:id/invoice/upload')
  @UseInterceptors(FileInterceptor('file'))
  async uploadOrderInvoiceFile(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Order invoice file uploaded successfully.',
      data: await this.pharmacyService.uploadOrderInvoiceFile(
        this.parseId(id, 'Order ID'),
        file,
        principal,
      ),
    };
  }

  @RequirePermissions('providers.read')
  @Get('pharmacy/orders/:id/invoice/file')
  async getOrderInvoiceFile(
    @Param('id') id: string,
    @Res() res: Response,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const { buffer, contentType, fileName } = await this.pharmacyService.getOrderInvoiceFileStream(
      this.parseId(id, 'Order ID'),
      principal,
    );
    res.setHeader('Content-Type', contentType);
    res.setHeader('Content-Disposition', `inline; filename="${fileName}"`);
    res.setHeader('Cache-Control', 'private, max-age=3600');
    res.send(buffer);
  }

  @RequirePermissions('providers.update')
  @Delete('pharmacy/orders/:id/invoice')
  async removeOrderInvoice(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Order invoice removed successfully.',
      data: await this.pharmacyService.removeOrderInvoice(
        this.parseId(id, 'Order ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.update')
  @Post('pharmacy/orders/:id/send-invoice')
  async sendOrderInvoice(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Order invoice dispatched to customer via push and in-app notification.',
      data: await this.pharmacyService.sendOrderInvoice(
        this.parseId(id, 'Order ID'),
        principal,
      ),
    };
  }

  @RequirePermissions('providers.view')
  @Get('pharmacy/profile')
  async getPharmacyProfile(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      message: 'Pharmacy profile retrieved successfully.',
      data: await this.pharmacyService.getPharmacyProfile(principal),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/profile')
  async updatePharmacyProfile(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Pharmacy profile updated successfully.',
      data: await this.pharmacyService.updatePharmacyProfile(body, principal),
    };
  }

  @RequirePermissions('providers.view')
  @Get('pharmacy/settings')
  async getPharmacySettings(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      message: 'Pharmacy settings retrieved successfully.',
      data: await this.pharmacyService.getPharmacySettings(principal),
    };
  }

  @RequirePermissions('providers.update')
  @Patch('pharmacy/settings')
  async updatePharmacySettings(
    @Body() body: PharmacySettingsDto,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Pharmacy settings updated successfully.',
      data: await this.pharmacyService.updatePharmacySettings(body, principal),
    };
  }
}
