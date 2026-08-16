import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import type { ShieldPrincipal } from '../auth/auth.types';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { PricingService } from '../pricing/pricing.service';
import { ReferralService } from '../referral/referral.service';
import { WalletService } from '../wallet/wallet.service';
import { WALLET_LEDGER_TYPES } from '../pricing/pricing.types';

@Injectable()
export class PharmacyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly providerScopeService: ProviderScopeService,
    private readonly pricingService: PricingService,
    private readonly referralService: ReferralService,
    private readonly walletService: WalletService,
  ) {}

  async createProduct(data: {
    productName: string;
    brand: string;
    productCode: string;
    unit?: string;
  }) {
    return this.prisma.product.create({
      data: {
        uuid: randomUUID(),
        productName: data.productName,
        brand: data.brand,
        productCode: data.productCode,
        unit: data.unit || 'Nos',
      },
    });
  }

  async getProduct(id: bigint) {
    const prod = await this.prisma.product.findUnique({
      where: { id },
    });
    if (!prod) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    return prod;
  }

  async searchProducts(query?: string) {
    const whereClause: any = {};
    if (query) {
      whereClause.OR = [
        { productName: { contains: query, mode: 'insensitive' } },
        { brand: { contains: query, mode: 'insensitive' } },
      ];
    }
    return this.prisma.product.findMany({
      where: whereClause,
      take: 20,
    });
  }

  async listWellnessProducts() {
    return this.prisma.product.findMany({
      where: {
        status: 'ACTIVE',
      },
      include: { category: true },
      orderBy: { productName: 'asc' },
    });
  }

  private customerWellnessWhere() {
    return {
      status: 'ACTIVE',
    };
  }

  private getAuthoritativeUnitPrice(product: any): number | null {
    const price =
      product?.sellingPrice != null
        ? Number(product.sellingPrice)
        : product?.mrp != null
          ? Number(product.mrp)
          : null;
    if (price == null || !Number.isFinite(price) || price <= 0) {
      return null;
    }
    return price;
  }

  private isCustomerOrderable(product: any): boolean {
    const status = product?.status ?? 'ACTIVE';
    if (status !== 'ACTIVE') return false;
    const unitPrice = this.getAuthoritativeUnitPrice(product);
    return unitPrice !== null && unitPrice > 0;
  }

  private customerWellnessProduct(product: any) {
    const isOrderable = this.isCustomerOrderable(product);

    return {
      id: product.id.toString(),
      productCode: product.productCode,
      productName: product.productName,
      brand: product.brand,
      unit: product.unit,
      mrp: product.mrp == null ? null : Number(product.mrp),
      sellingPrice:
        product.sellingPrice == null ? null : Number(product.sellingPrice),
      category: product.category
        ? {
            id: product.category.id.toString(),
            name: this.customerCategoryName(product.category.name),
          }
        : null,
      catalogueKind: 'STANDARD',
      purchasable: isOrderable,
      purchasabilityReason: isOrderable
        ? null
        : 'Product price is unavailable or invalid for online checkout.',
    };
  }

  private customerCategoryName(name?: string | null) {
    if (name === 'DIAGNOSTIC DEVICES & MONITORING EQUIPMENT-MDE') {
      return 'Diagnostic devices';
    }
    if (name === 'VITAMINS & SUPPLEMENTS-HW') {
      return 'Vitamins & supplements';
    }
    return name;
  }

  async listCustomerWellnessProducts(options: {
    query?: string;
    categoryId?: string;
    page?: string;
    pageSize?: string;
  }) {
    const requestedPage = Number(options.page);
    const requestedPageSize = Number(options.pageSize);
    const page =
      Number.isSafeInteger(requestedPage) && requestedPage > 0
        ? requestedPage
        : 1;
    const pageSize =
      Number.isSafeInteger(requestedPageSize) && requestedPageSize > 0
        ? Math.min(50, requestedPageSize)
        : 24;
    const filters: any[] = [this.customerWellnessWhere()];
    const query = options.query?.trim();
    if (query) {
      filters.push({
        OR: [
          { productName: { contains: query, mode: 'insensitive' } },
          { brand: { contains: query, mode: 'insensitive' } },
          { productCode: { contains: query, mode: 'insensitive' } },
        ],
      });
    }
    if (options.categoryId && /^\d+$/.test(options.categoryId)) {
      filters.push({ categoryId: BigInt(options.categoryId) });
    }
    const where = { AND: filters };
    const [total, products, categories] = await this.prisma.$transaction([
      this.prisma.product.count({ where }),
      this.prisma.product.findMany({
        where,
        include: { category: true },
        orderBy: { productName: 'asc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.productCategory.findMany({
        where: { products: { some: this.customerWellnessWhere() } },
        orderBy: { name: 'asc' },
      }),
    ]);
    return {
      items: products.map((product) => this.customerWellnessProduct(product)),
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
      categories: categories.map((category) => ({
        id: category.id.toString(),
        name: this.customerCategoryName(category.name),
      })),
      disclosure: null,
    };
  }

  async getCustomerWellnessProduct(id: bigint) {
    const product = await this.prisma.product.findFirst({
      where: { AND: [{ id }, this.customerWellnessWhere()] },
      include: { category: true },
    });
    if (!product) throw new NotFoundException('Wellness product not found.');
    return this.customerWellnessProduct(product);
  }

  private customerPrescriptionRequest(value: any) {
    return {
      id: value.id.toString(),
      uuid: value.uuid,
      status: value.status,
      customerNotes: value.customerNotes ?? null,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      prescription: {
        id: value.document.id.toString(),
        title: value.document.fileName ?? 'Prescription',
        fileName: value.document.fileName ?? 'Prescription',
        status: value.document.status ?? 'UPLOADED',
      },
      pharmacy: {
        id: value.provider.id.toString(),
        name: value.provider.providerName ?? 'Pharmacy',
        businessName: value.provider.business?.name ?? null,
      },
    };
  }

  async createCustomerPrescriptionRequest(data: {
    customerId: bigint;
    documentId: bigint;
    providerId: bigint;
    customerNotes?: string;
  }) {
    const [document, provider] = await Promise.all([
      this.prisma.document.findFirst({
        where: {
          id: data.documentId,
          customerId: data.customerId,
          documentType: { equals: 'PRESCRIPTION', mode: 'insensitive' },
          status: { not: 'DELETED' },
        },
      }),
      this.prisma.serviceProvider.findFirst({
        where: {
          id: data.providerId,
          status: 'ACTIVE',
          providerType: { equals: 'PHARMACY', mode: 'insensitive' },
        },
      }),
    ]);
    if (!document) {
      throw new NotFoundException('Prescription document not found.');
    }
    if (!provider) {
      throw new BadRequestException('The selected pharmacy is not available.');
    }

    const duplicate = await this.prisma.prescriptionPharmacyRequest.findFirst({
      where: {
        documentId: data.documentId,
        providerId: data.providerId,
        status: 'SUBMITTED',
      },
      select: { id: true },
    });
    if (duplicate) {
      throw new BadRequestException(
        'This prescription has already been submitted to the selected pharmacy.',
      );
    }

    const request = await this.prisma.$transaction(async (tx) => {
      const created = await tx.prescriptionPharmacyRequest.create({
        data: {
          uuid: randomUUID(),
          customerId: data.customerId,
          documentId: data.documentId,
          providerId: data.providerId,
          status: 'SUBMITTED',
          customerNotes: data.customerNotes,
        },
        include: { document: true, provider: { include: { business: true } } },
      });
      await tx.auditLog.create({
        data: {
          action: 'CUSTOMER_PRESCRIPTION_PHARMACY_SUBMITTED',
          entityType: 'PRESCRIPTION_PHARMACY_REQUEST',
          entityId: created.id,
          newData: {
            customerId: data.customerId.toString(),
            documentId: data.documentId.toString(),
            providerId: data.providerId.toString(),
            status: 'SUBMITTED',
          },
        },
      });
      return created;
    });
    return this.customerPrescriptionRequest(request);
  }

  async listCustomerPrescriptionRequests(customerId: bigint) {
    const requests = await this.prisma.prescriptionPharmacyRequest.findMany({
      where: { customerId },
      include: { document: true, provider: { include: { business: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return requests.map((request) => this.customerPrescriptionRequest(request));
  }

  async createPurchase(data: {
    customerId: bigint;
    providerId: bigint;
    invoiceNumber: string;
    items: Array<{ productId: bigint; quantity: number; unitPrice: number }>;
    staffUserId?: bigint;
  }) {
    let totalAmount = 0;
    for (const item of data.items) {
      totalAmount += item.quantity * item.unitPrice;
    }

    // 2. Fetch customer, membership, and wallet
    const customer = await this.prisma.customer.findUnique({
      where: { id: data.customerId },
      include: {
        membership: { include: { membershipType: true } },
        wallet: true,
      },
    });

    if (!customer) {
      throw new NotFoundException(
        `Customer with ID ${data.customerId} not found`,
      );
    }
    if (!customer.wallet) {
      throw new BadRequestException(
        'Customer does not have a wallet configured.',
      );
    }

    const evaluation = await this.pricingService.evaluateServicePrice({
      customerId: customer.id,
      serviceType: 'PHARMACY',
      originalAmount: totalAmount,
      persistAudit: true,
      referenceType: 'PURCHASE',
    });

    await this.walletService.ensureSufficientCashBalance(
      customer.id,
      evaluation.finalPayableAmount,
    );

    return this.prisma
      .$transaction(async (tx) => {
        const purchase = await tx.purchase.create({
          data: {
            uuid: randomUUID(),
            customerId: customer.id,
            providerId: data.providerId,
            invoiceNumber: data.invoiceNumber,
            totalAmount,
            discountAmount: Number(
              (
                evaluation.benefitApplied +
                evaluation.membershipDiscountApplied +
                evaluation.rewardPointCreditValue
              ).toFixed(2),
            ),
            payableAmount: evaluation.finalPayableAmount,
            purchaseDate: new Date(),
          },
        });

        for (const item of data.items) {
          await tx.purchaseItem.create({
            data: {
              purchaseId: purchase.id,
              productId: item.productId,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.quantity * item.unitPrice,
            },
          });
        }

        await tx.cashWalletTransaction.create({
          data: {
            uuid: randomUUID(),
            walletId: customer.wallet!.id,
            transactionType: 'PURCHASE',
            amount: evaluation.finalPayableAmount,
            remarks: `Pharmacy purchase (Invoice: ${data.invoiceNumber})`,
            createdBy: data.staffUserId,
            referenceType: 'PURCHASE',
            referenceId: purchase.id,
            metadata: {
              customerVisibleLines: evaluation.customerVisibleLines,
            },
          },
        });

        return purchase;
      })
      .then(async (purchase) => {
        await this.referralService.qualifyRewardFromTransaction({
          customerId: customer.id,
          serviceType: 'PHARMACY',
          referenceType: 'PURCHASE',
          referenceId: purchase.id,
          performedBy: data.staffUserId,
        });

        return purchase;
      });
  }

  async listPurchases(customerId?: bigint, principal?: ShieldPrincipal) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    }
    return this.prisma.purchase.findMany({
      where: this.providerScopeService.scopePurchaseWhere(
        whereClause,
        principal,
      ),
      include: {
        customer: true,
        provider: true,
        purchaseItems: {
          include: {
            product: true,
          },
        },
      },
      orderBy: { purchaseDate: 'desc' },
    });
  }

  private customerOrderProjection(purchase: any) {
    return {
      id: purchase.id.toString(),
      invoiceNumber: purchase.invoiceNumber ?? null,
      orderStatus: purchase.orderStatus,
      paymentStatus: purchase.paymentStatus ?? null,
      totalAmount:
        purchase.totalAmount == null ? null : Number(purchase.totalAmount),
      payableAmount:
        purchase.payableAmount == null ? null : Number(purchase.payableAmount),
      purchaseDate: purchase.purchaseDate ?? null,
      providerName:
        purchase.provider?.business?.name ??
        purchase.provider?.providerName ??
        null,
      items: (purchase.purchaseItems ?? []).map((item: any) => ({
        id: item.id.toString(),
        productId: item.productId == null ? null : item.productId.toString(),
        name: item.itemName ?? item.product?.productName ?? 'Product',
        quantity: item.quantity == null ? null : Number(item.quantity),
        unitPrice: item.unitPrice == null ? null : Number(item.unitPrice),
        lineTotal: item.totalPrice == null ? null : Number(item.totalPrice),
      })),
    };
  }

  private customerOrderInclude() {
    return {
      provider: { include: { business: true } },
      purchaseItems: {
        include: {
          product: {
            select: { productName: true },
          },
        },
      },
    } as const;
  }

  async listCustomerOrders(customerId: bigint) {
    const purchases = await this.prisma.purchase.findMany({
      where: { customerId },
      include: this.customerOrderInclude(),
      orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
    });
    return purchases.map((purchase) => this.customerOrderProjection(purchase));
  }

  async getCustomerOrder(customerId: bigint, orderId: bigint) {
    const purchase = await this.prisma.purchase.findFirst({
      where: { id: orderId, customerId },
      include: this.customerOrderInclude(),
    });
    if (!purchase) throw new NotFoundException('Order not found.');
    return this.customerOrderProjection(purchase);
  }

  private static readonly _orderInFlightPromises = new Map<string, Promise<any>>();

  async createCustomerOrder(data: {
    customerId: bigint;
    providerId: bigint;
    items: Array<{ productId: bigint; quantity: number }>;
    deliveryAddress?: string;
    customerNotes?: string;
    idempotencyKey?: string;
  }) {
    if (!data.items || data.items.length === 0) {
      throw new BadRequestException('Order items must not be empty.');
    }

    const provider = await this.prisma.serviceProvider.findUnique({
      where: { id: data.providerId },
    });

    if (!provider || provider.status !== 'ACTIVE' || provider.providerType !== 'PHARMACY') {
      throw new BadRequestException('Selected provider is unavailable or is not an active pharmacy.');
    }

    const idempotencyKey = (data.idempotencyKey ?? '').trim();
    const flightKey = idempotencyKey ? `${data.customerId}:${idempotencyKey}` : null;

    if (flightKey && PharmacyService._orderInFlightPromises.has(flightKey)) {
      return PharmacyService._orderInFlightPromises.get(flightKey);
    }

    const executeOrder = async () => {
      const invoiceNumber = idempotencyKey
        ? `ORD-KEY-${idempotencyKey.slice(0, 40)}`
        : `ORD-${Date.now()}-${randomUUID().slice(0, 6)}`;

      if (idempotencyKey) {
        const existing = await this.prisma.purchase.findFirst({
          where: {
            customerId: data.customerId,
            invoiceNumber,
          },
          include: this.customerOrderInclude(),
        });
        if (existing) {
          return this.customerOrderProjection(existing);
        }
      }

      const productIds = data.items.map((i) => BigInt(i.productId));
      const products = await this.prisma.product.findMany({
        where: {
          id: { in: productIds },
          ...this.customerWellnessWhere(),
        },
      });
      const productMap = new Map(products.map((p) => [p.id.toString(), p]));

      let calculatedTotal = 0;
      const itemsMapped = data.items.map((item) => {
        const prod = productMap.get(item.productId.toString());
        if (!prod || !this.isCustomerOrderable(prod)) {
          throw new BadRequestException(
            `Product ID ${item.productId} is unavailable, inactive, or missing a valid orderable price.`,
          );
        }
        const rawQty = Number(item.quantity);
        if (
          !Number.isFinite(rawQty) ||
          rawQty <= 0 ||
          !Number.isInteger(rawQty) ||
          rawQty > 1000
        ) {
          throw new BadRequestException(
            `Invalid item quantity for product ID ${item.productId}.`,
          );
        }
        const unitPrice = this.getAuthoritativeUnitPrice(prod)!;
        calculatedTotal += unitPrice * rawQty;
        return {
          productId: prod.id,
          quantity: rawQty,
          unitPrice,
        };
      });

      const deliveryAddress = String(data.deliveryAddress ?? '').trim() || undefined;
      const customerNotes = String(data.customerNotes ?? '').trim() || undefined;

      try {
        const purchase = await this.prisma.purchase.create({
          data: {
            uuid: randomUUID(),
            customerId: data.customerId,
            providerId: data.providerId,
            invoiceNumber,
            purchaseKind: 'CUSTOMER_ORDER',
            orderStatus: 'PLACED',
            paymentStatus: 'PENDING',
            totalAmount: calculatedTotal,
            discountAmount: 0,
            payableAmount: calculatedTotal,
            purchaseDate: new Date(),
            billingSnapshot: {
              deliveryAddress,
              customerNotes,
              idempotencyKey: idempotencyKey || null,
            },
            purchaseItems: {
              create: itemsMapped.map((item) => ({
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                totalPrice: item.quantity * item.unitPrice,
              })),
            },
          },
          include: this.customerOrderInclude(),
        });

        return this.customerOrderProjection(purchase);
      } catch (error: any) {
        if (
          idempotencyKey &&
          (error?.code === 'P2002' || String(error?.message).includes('unique'))
        ) {
          const existing = await this.prisma.purchase.findFirst({
            where: {
              customerId: data.customerId,
              invoiceNumber,
            },
            include: this.customerOrderInclude(),
          });
          if (existing) {
            return this.customerOrderProjection(existing);
          }
        }
        throw error;
      }
    };

    const orderPromise = executeOrder();

    if (flightKey) {
      PharmacyService._orderInFlightPromises.set(flightKey, orderPromise);
      orderPromise.finally(() => {
        PharmacyService._orderInFlightPromises.delete(flightKey);
      });
    }

    return orderPromise;
  }

  async listPharmacyOrders(principal?: ShieldPrincipal) {
    const whereClause = this.providerScopeService.scopePurchaseWhere(
      { purchaseKind: 'CUSTOMER_ORDER' },
      principal,
    );
    const purchases = await this.prisma.purchase.findMany({
      where: whereClause,
      include: this.customerOrderInclude(),
      orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
      take: 50,
    });
    return purchases.map((purchase) => this.customerOrderProjection(purchase));
  }

  async updateOrderStatus(
    orderId: bigint,
    status: string,
    principal?: ShieldPrincipal,
  ) {
    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    await this.providerScopeService.assertProviderCanAccessPurchase(
      orderId,
      principal,
    );

    const allowedStatuses = [
      'PLACED',
      'REQUESTED',
      'ACCEPTED',
      'PROCESSING',
      'READY',
      'COMPLETED',
      'REJECTED',
      'CANCELLED',
    ];
    const normalizedStatus = status.trim().toUpperCase();
    if (!allowedStatuses.includes(normalizedStatus)) {
      throw new BadRequestException(`Invalid order status ${status}.`);
    }

    const updated = await this.prisma.purchase.update({
      where: { id: orderId },
      data: {
        orderStatus: normalizedStatus,
      },
      include: this.customerOrderInclude(),
    });

    return this.customerOrderProjection(updated);
  }
}
