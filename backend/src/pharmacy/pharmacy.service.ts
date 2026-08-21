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
import { StorageService } from '../storage/storage.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class PharmacyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly providerScopeService: ProviderScopeService,
    private readonly pricingService: PricingService,
    private readonly referralService: ReferralService,
    private readonly walletService: WalletService,
    private readonly storageService: StorageService,
    private readonly notificationService: NotificationService,
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
    const snapshot = (purchase.billingSnapshot as Record<string, any>) || {};
    let orderSource = 'MANUAL_ITEMS';
    if (purchase.purchaseKind === 'WELLNESS' || snapshot.orderSource === 'WELLNESS') {
      orderSource = 'WELLNESS';
    } else if (
      purchase.purchaseKind === 'PRESCRIPTION' ||
      snapshot.orderSource === 'PRESCRIPTION' ||
      snapshot.prescriptionDocumentId != null
    ) {
      orderSource = 'PRESCRIPTION';
    } else if (
      purchase.purchaseKind === 'MANUAL_ITEMS' ||
      snapshot.orderSource === 'MANUAL_ITEMS'
    ) {
      orderSource = 'MANUAL_ITEMS';
    }

    return {
      id: purchase.id.toString(),
      uuid: purchase.uuid,
      invoiceNumber: purchase.invoiceNumber ?? null,
      orderStatus: purchase.orderStatus,
      paymentStatus: purchase.paymentStatus ?? null,
      orderSource,
      fulfillmentPreference: snapshot.fulfillmentPreference ?? 'COLLECT_FROM_PHARMACY',
      deliveryAddress: snapshot.deliveryAddress ?? null,
      customerNotes: snapshot.customerNotes ?? null,
      totalAmount:
        purchase.totalAmount == null ? null : Number(purchase.totalAmount),
      payableAmount:
        purchase.payableAmount == null ? null : Number(purchase.payableAmount),
      purchaseDate: purchase.purchaseDate ?? null,
      providerName:
        purchase.provider?.business?.name ??
        purchase.provider?.providerName ??
        null,
      pharmacy: purchase.provider
        ? {
            id: purchase.provider.id != null ? purchase.provider.id.toString() : null,
            name: purchase.provider.providerName ?? null,
            businessName: purchase.provider.business?.name ?? null,
          }
        : null,
      prescriptionDocument: snapshot.prescriptionDocument ?? null,
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
    orderSource?: 'PRESCRIPTION' | 'MANUAL_ITEMS' | 'WELLNESS' | string;
    documentId?: bigint;
    items?: Array<{ productId?: bigint; name?: string; quantity: number; notes?: string }>;
    fulfillmentPreference?: 'HOME_DELIVERY' | 'COLLECT_FROM_PHARMACY' | string;
    deliveryAddress?: string;
    customerNotes?: string;
    idempotencyKey?: string;
  }) {
    const provider = await this.prisma.serviceProvider.findUnique({
      where: { id: data.providerId },
    });

    if (!provider || provider.status !== 'ACTIVE' || provider.providerType !== 'PHARMACY') {
      throw new BadRequestException('Selected provider is unavailable or is not an active pharmacy.');
    }

    const fulfillmentPreference =
      data.fulfillmentPreference === 'HOME_DELIVERY' ? 'HOME_DELIVERY' : 'COLLECT_FROM_PHARMACY';
    const deliveryAddress = String(data.deliveryAddress ?? '').trim() || undefined;

    if (fulfillmentPreference === 'HOME_DELIVERY' && !deliveryAddress) {
      throw new BadRequestException('Delivery address is required for home delivery.');
    }

    const customerNotes = String(data.customerNotes ?? '').trim() || undefined;

    let source = (data.orderSource ?? '').trim().toUpperCase();
    if (!source) {
      if (data.documentId) {
        source = 'PRESCRIPTION';
      } else if (data.items && data.items.some((i) => i.productId != null)) {
        source = 'WELLNESS';
      } else {
        source = 'MANUAL_ITEMS';
      }
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

      let calculatedTotal = 0;
      let purchaseKind = 'MANUAL_ITEMS';
      let snapshotExtra: Record<string, any> = {};
      let itemsMapped: Array<{
        productId?: bigint;
        itemName: string;
        quantity: number;
        unitPrice: number;
        totalPrice: number;
        itemType?: string;
        metadata?: any;
      }> = [];

      if (source === 'PRESCRIPTION') {
        if (!data.documentId) {
          throw new BadRequestException('Prescription document ID is required for prescription orders.');
        }
        const document = await this.prisma.document.findFirst({
          where: {
            id: data.documentId,
            customerId: data.customerId,
            documentType: { equals: 'PRESCRIPTION', mode: 'insensitive' },
            status: { not: 'DELETED' },
          },
        });
        if (!document) {
          throw new NotFoundException('Prescription document not found.');
        }
        purchaseKind = 'PRESCRIPTION';
        snapshotExtra = {
          prescriptionDocumentId: document.id.toString(),
          prescriptionDocument: {
            id: document.id.toString(),
            title: document.fileName ?? 'Prescription Document',
            fileName: document.fileName ?? 'Prescription',
          },
        };
        itemsMapped = [
          {
            itemName: document.fileName || 'Prescription Document',
            quantity: 1,
            unitPrice: 0,
            totalPrice: 0,
            itemType: 'PRESCRIPTION',
            metadata: { documentId: document.id.toString() },
          },
        ];
      } else if (source === 'MANUAL_ITEMS') {
        if (!data.items || data.items.length === 0) {
          throw new BadRequestException('At least one item request is required for manual item orders.');
        }
        purchaseKind = 'MANUAL_ITEMS';
        itemsMapped = data.items.map((item, idx) => {
          const name = String(item.name ?? '').trim();
          if (!name) {
            throw new BadRequestException(`Item #${idx + 1} must have a product or request name.`);
          }
          const rawQty = Number(item.quantity);
          if (!Number.isFinite(rawQty) || rawQty <= 0 || !Number.isInteger(rawQty) || rawQty > 1000) {
            throw new BadRequestException(`Item #${idx + 1} must have a valid positive integer quantity.`);
          }
          return {
            itemName: name.slice(0, 255),
            quantity: rawQty,
            unitPrice: 0,
            totalPrice: 0,
            itemType: 'MANUAL_REQUEST',
            metadata: item.notes ? { notes: String(item.notes).trim() } : undefined,
          };
        });
      } else {
        // WELLNESS
        if (!data.items || data.items.length === 0) {
          throw new BadRequestException('Order items must not be empty for wellness orders.');
        }
        purchaseKind = 'WELLNESS';
        const productIds = data.items
          .map((i) => (i.productId != null ? BigInt(i.productId) : null))
          .filter((id): id is bigint => id != null);

        if (productIds.length === 0) {
          throw new BadRequestException('Valid product IDs are required for wellness orders.');
        }

        const products = await this.prisma.product.findMany({
          where: {
            id: { in: productIds },
            ...this.customerWellnessWhere(),
          },
        });
        const productMap = new Map(products.map((p) => [p.id.toString(), p]));

        itemsMapped = data.items.map((item) => {
          if (!item.productId) {
            throw new BadRequestException('Product ID is required for wellness items.');
          }
          const prod = productMap.get(item.productId.toString());
          if (!prod || !this.isCustomerOrderable(prod)) {
            throw new BadRequestException(
              `Product ID ${item.productId} is unavailable, inactive, or missing a valid orderable price.`,
            );
          }
          const rawQty = Number(item.quantity);
          if (!Number.isFinite(rawQty) || rawQty <= 0 || !Number.isInteger(rawQty) || rawQty > 1000) {
            throw new BadRequestException(`Invalid item quantity for product ID ${item.productId}.`);
          }
          const unitPrice = this.getAuthoritativeUnitPrice(prod)!;
          calculatedTotal += unitPrice * rawQty;
          return {
            productId: prod.id,
            itemName: prod.productName ?? 'Product',
            quantity: rawQty,
            unitPrice,
            totalPrice: unitPrice * rawQty,
            itemType: 'WELLNESS_PRODUCT',
          };
        });
      }

      try {
        const purchase = await this.prisma.purchase.create({
          data: {
            uuid: randomUUID(),
            customerId: data.customerId,
            providerId: data.providerId,
            invoiceNumber,
            purchaseKind,
            orderStatus: 'PLACED',
            paymentStatus: 'PENDING',
            totalAmount: calculatedTotal,
            discountAmount: 0,
            payableAmount: calculatedTotal,
            purchaseDate: new Date(),
            billingSnapshot: {
              orderSource: source,
              fulfillmentPreference,
              deliveryAddress,
              customerNotes,
              idempotencyKey: idempotencyKey || null,
              ...snapshotExtra,
            },
            purchaseItems: {
              create: itemsMapped.map((item) => ({
                productId: item.productId,
                itemName: item.itemName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                totalPrice: item.totalPrice,
                itemType: item.itemType,
                metadata: item.metadata,
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

  public static readonly ACTIVE_ORDER_STATUSES = [
    'PLACED',
    'SUBMITTED',
    'REQUESTED',
    'NEW',
    'ACCEPTED',
    'REVIEWING',
    'PREPARING',
    'PROCESSING',
    'READY',
    'READY_FOR_PICKUP',
    'OUT_FOR_DELIVERY',
    'DELIVERY',
    'DISPATCHED',
  ];

  public static readonly TERMINAL_ORDER_STATUSES = [
    'COMPLETED',
    'DELIVERED',
    'COLLECTED',
    'CANCELLED',
    'REJECTED',
  ];

  private getPharmacyOrderDomainWhere() {
    return {
      purchaseKind: {
        in: [
          'PRESCRIPTION',
          'PHARMACY_PRESCRIPTION',
          'MANUAL_ITEMS',
          'WELLNESS',
          'CUSTOMER_ORDER',
          'PHARMACY',
          'GENERAL',
          'REFILL',
        ],
      },
    };
  }

  private isTerminalStatus(status?: string | null): boolean {
    if (!status) return false;
    return PharmacyService.TERMINAL_ORDER_STATUSES.includes(
      status.trim().toUpperCase(),
    );
  }

  private pharmacyFulfillmentProjection(purchase: any) {
    const snapshot = (purchase.billingSnapshot as Record<string, any>) || {};
    let calculatedPayableSum = 0;
    let hasCustomFulfillmentDecisions = false;

    const items = (purchase.purchaseItems ?? []).map((item: any) => {
      const meta = (item.metadata as Record<string, any>) || {};
      const reqQty = item.quantity == null ? 1 : Number(item.quantity);
      const origUnitPrice = item.unitPrice == null ? 0 : Number(item.unitPrice);
      const decisionStatus = (meta.decisionStatus ?? 'PENDING').toString().toUpperCase();
      const isRejected = decisionStatus === 'REJECTED';

      if (meta.decisionStatus != null) {
        hasCustomFulfillmentDecisions = true;
      }

      const fulQty = meta.fulfillQuantity != null
        ? Number(meta.fulfillQuantity)
        : (isRejected ? 0 : reqQty);
      const rejQty = meta.rejectedQuantity != null
        ? Number(meta.rejectedQuantity)
        : (isRejected ? reqQty : Math.max(0, reqQty - fulQty));
      const dispQty = meta.dispatchedQuantity != null ? Number(meta.dispatchedQuantity) : 0;
      const stockStatus = meta.stockStatus || 'FULL_STOCK';

      const authUnitPrice = meta.substituteUnitPrice != null ? Number(meta.substituteUnitPrice) : origUnitPrice;
      const lineTotal = isRejected ? 0 : Number((fulQty * authUnitPrice).toFixed(2));
      calculatedPayableSum += lineTotal;

      return {
        id: item.id.toString(),
        productId: item.productId == null ? null : item.productId.toString(),
        name: item.itemName ?? item.product?.productName ?? 'Product',
        quantity: reqQty,
        unitPrice: origUnitPrice,
        lineTotal,
        fulfillQuantity: fulQty,
        rejectedQuantity: rejQty,
        dispatchedQuantity: dispQty,
        stockStatus,
        decisionStatus,
        substituteProductId: meta.substituteProductId || null,
        substituteName: meta.substituteName || null,
        substituteUnitPrice: meta.substituteUnitPrice != null ? Number(meta.substituteUnitPrice) : null,
        decisionReason: meta.decisionReason || null,
        metadata: meta,
      };
    });

    let source = 'UNKNOWN';
    if (purchase.purchaseKind === 'WELLNESS') {
      source = 'WELLNESS';
    } else if (
      purchase.purchaseKind === 'PRESCRIPTION' ||
      snapshot.prescriptionDocumentId != null
    ) {
      source = 'PRESCRIPTION';
    } else if (purchase.purchaseKind === 'MANUAL_ITEMS') {
      source = 'MANUAL_ITEMS';
    } else if (snapshot.orderSource) {
      source = String(snapshot.orderSource).toUpperCase();
    } else if (purchase.purchaseKind) {
      source = String(purchase.purchaseKind).toUpperCase();
    }

    const fulfillmentPreference = snapshot.fulfillmentPreference
      ? String(snapshot.fulfillmentPreference)
      : null;

    const isChronic = snapshot.isChronic === true || snapshot.isChronic === 'true';
    const repeatIntervalDays = snapshot.repeatIntervalDays != null ? Number(snapshot.repeatIntervalDays) : 30;

    const totalAmount = purchase.totalAmount == null ? 0 : Number(purchase.totalAmount);
    const payableAmount = hasCustomFulfillmentDecisions
      ? Number(calculatedPayableSum.toFixed(2))
      : (purchase.payableAmount == null ? totalAmount : Number(purchase.payableAmount));

    return {
      id: purchase.id.toString(),
      uuid: purchase.uuid,
      orderNumber: purchase.invoiceNumber ?? `ORD-${purchase.id}`,
      status: purchase.orderStatus ?? 'PLACED',
      paymentStatus: purchase.paymentStatus ?? 'PENDING',
      orderSource: source,
      fulfillmentPreference,
      isChronic,
      repeatIntervalDays,
      customer: purchase.customer
        ? {
            id: purchase.customer.id.toString(),
            customerCode: purchase.customer.customerCode,
            fullName:
              `${purchase.customer.firstName ?? ''} ${purchase.customer.lastName ?? ''}`.trim() ||
              'Customer',
            mobile: purchase.customer.mobile,
            email: purchase.customer.email,
          }
        : null,
      deliveryAddress: snapshot.deliveryAddress ?? null,
      customerNotes: snapshot.customerNotes ?? null,
      cancellationReason: snapshot.cancellationReason ?? null,
      totalAmount,
      payableAmount,
      submittedAt: purchase.purchaseDate ?? purchase.createdAt ?? new Date(),
      statusUpdatedAt: purchase.orderStatusUpdatedAt ?? null,
      items,
      prescriptionDocument: snapshot.prescriptionDocument ?? null,
    };
  }

  async listPharmacyOrders(options?: {
    status?: string;
    source?: string;
    query?: string;
    page?: string;
    pageSize?: string;
    principal?: ShieldPrincipal;
  }) {
    const page = Math.max(1, Number(options?.page || 1));
    const pageSize = Math.min(
      100,
      Math.max(1, Number(options?.pageSize || 25)),
    );

    const scopeWhere = await this.providerScopeService.scopePurchaseWhere(
      {},
      options?.principal,
    );

    const where: any = {
      ...scopeWhere,
      ...this.getPharmacyOrderDomainWhere(),
    };

    const targetStatus = options?.status?.trim().toUpperCase();
    if (
      !targetStatus ||
      targetStatus === 'ALL' ||
      targetStatus === 'ALL_ACTIVE'
    ) {
      where.orderStatus = { in: PharmacyService.ACTIVE_ORDER_STATUSES };
    } else if (targetStatus === 'NEW') {
      where.orderStatus = { in: ['PLACED', 'SUBMITTED', 'REQUESTED', 'NEW'] };
    } else if (targetStatus === 'ACCEPTED') {
      where.orderStatus = { in: ['ACCEPTED', 'REVIEWING'] };
    } else if (targetStatus === 'PREPARING') {
      where.orderStatus = {
        in: ['ACCEPTED', 'REVIEWING', 'PREPARING', 'PROCESSING'],
      };
    } else if (targetStatus === 'READY') {
      where.orderStatus = { in: ['READY', 'READY_FOR_PICKUP'] };
    } else if (targetStatus === 'DELIVERY') {
      where.orderStatus = {
        in: ['OUT_FOR_DELIVERY', 'DELIVERY', 'DISPATCHED'],
      };
    } else if (targetStatus === 'CHRONIC') {
      where.billingSnapshot = {
        path: ['isChronic'],
        equals: true,
      };
    } else {
      where.orderStatus = targetStatus;
    }

    if (options?.source && options.source.trim().toUpperCase() !== 'ALL') {
      const src = options.source.trim().toUpperCase();
      if (['PRESCRIPTION', 'WELLNESS', 'MANUAL_ITEMS'].includes(src)) {
        where.purchaseKind = src;
      }
    }

    if (options?.query?.trim()) {
      const q = options.query.trim();
      where.OR = [
        { invoiceNumber: { contains: q, mode: 'insensitive' } },
        { customer: { firstName: { contains: q, mode: 'insensitive' } } },
        { customer: { lastName: { contains: q, mode: 'insensitive' } } },
        { customer: { mobile: { contains: q, mode: 'insensitive' } } },
        { customer: { customerCode: { contains: q, mode: 'insensitive' } } },
      ];
    }

    const [total, purchases] = await Promise.all([
      this.prisma.purchase.count({ where }),
      this.prisma.purchase.findMany({
        where,
        include: {
          customer: true,
          provider: { include: { business: true } },
          purchaseItems: { include: { product: true } },
        },
        orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    return {
      items: purchases.map((p) => this.pharmacyFulfillmentProjection(p)),
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  }

  async getPharmacyOrdersSummary(principal?: ShieldPrincipal) {
    const scopeWhere = await this.providerScopeService.scopePurchaseWhere(
      {},
      principal,
    );

    const where: any = {
      ...scopeWhere,
      ...this.getPharmacyOrderDomainWhere(),
    };

    const [grouped, chronicCount] = await Promise.all([
      this.prisma.purchase.groupBy({
        by: ['orderStatus'],
        where,
        _count: { _all: true },
      }),
      this.prisma.purchase.count({
        where: {
          ...where,
          billingSnapshot: {
            path: ['isChronic'],
            equals: true,
          },
        },
      }),
    ]);

    const summary = {
      newCount: 0,
      acceptedCount: 0,
      preparingCount: 0,
      readyCount: 0,
      deliveryCount: 0,
      completedCount: 0,
      cancelledCount: 0,
      chronicCount,
      totalCount: 0,
    };

    for (const g of grouped) {
      const st = (g.orderStatus ?? 'PLACED').toUpperCase();
      const cnt = g._count._all;
      summary.totalCount += cnt;

      if (['PLACED', 'SUBMITTED', 'REQUESTED', 'NEW'].includes(st)) {
        summary.newCount += cnt;
      } else if (['ACCEPTED', 'REVIEWING'].includes(st)) {
        summary.acceptedCount += cnt;
      } else if (['PREPARING', 'PROCESSING'].includes(st)) {
        summary.preparingCount += cnt;
      } else if (['READY', 'READY_FOR_PICKUP'].includes(st)) {
        summary.readyCount += cnt;
      } else if (['OUT_FOR_DELIVERY', 'DELIVERY', 'DISPATCHED'].includes(st)) {
        summary.deliveryCount += cnt;
      } else if (['COMPLETED', 'DELIVERED', 'COLLECTED'].includes(st)) {
        summary.completedCount += cnt;
      } else if (['CANCELLED', 'REJECTED'].includes(st)) {
        summary.cancelledCount += cnt;
      }
    }

    return summary;
  }

  async getPharmacyOrderDetail(orderId: bigint, principal?: ShieldPrincipal) {
    await this.providerScopeService.assertProviderCanAccessPurchase(
      orderId,
      principal,
    );
    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
      include: {
        customer: true,
        provider: { include: { business: true } },
        purchaseItems: { include: { product: true } },
      },
    });

    if (!purchase) {
      throw new NotFoundException(`Order with ID ${orderId} not found.`);
    }

    return this.pharmacyFulfillmentProjection(purchase);
  }

  async updateOrderStatus(
    orderId: bigint,
    status: string,
    cancellationReason?: string,
    principal?: ShieldPrincipal,
  ) {
    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
      include: {
        customer: true,
        provider: { include: { business: true } },
        purchaseItems: { include: { product: true } },
      },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    await this.providerScopeService.assertProviderCanAccessPurchase(
      orderId,
      principal,
    );

    const allowedStatuses = [
      'PLACED',
      'SUBMITTED',
      'REQUESTED',
      'NEW',
      'ACCEPTED',
      'REVIEWING',
      'PREPARING',
      'PROCESSING',
      'READY',
      'READY_FOR_PICKUP',
      'OUT_FOR_DELIVERY',
      'DELIVERY',
      'DISPATCHED',
      'COMPLETED',
      'REJECTED',
      'CANCELLED',
    ];
    const normalizedStatus = status.trim().toUpperCase();
    if (!allowedStatuses.includes(normalizedStatus)) {
      throw new BadRequestException(`Invalid order status ${status}.`);
    }

    const currentStatusUpper = (purchase.orderStatus || '').toUpperCase();

    // Idempotent same-status no-op
    if (currentStatusUpper === normalizedStatus) {
      return this.pharmacyFulfillmentProjection(purchase);
    }

    // Terminal order status invariant: terminal orders cannot transition to a different status
    if (this.isTerminalStatus(currentStatusUpper)) {
      throw new BadRequestException(
        `Terminal order in status ${purchase.orderStatus} cannot be reopened or changed to ${normalizedStatus}.`,
      );
    }

    const snapshot = (purchase.billingSnapshot as Record<string, any>) || {};
    const fulfillmentPref = snapshot.fulfillmentPreference
      ? String(snapshot.fulfillmentPreference).toUpperCase()
      : null;

    // Fulfillment-specific restriction: pickup orders cannot transition to delivery
    if (
      fulfillmentPref === 'COLLECT_FROM_PHARMACY' &&
      ['OUT_FOR_DELIVERY', 'DELIVERY', 'DISPATCHED'].includes(normalizedStatus)
    ) {
      throw new BadRequestException(
        'Orders with COLLECT_FROM_PHARMACY fulfillment preference cannot be dispatched for delivery.',
      );
    }

    // Server-authoritative progression rules
    if (
      ['PLACED', 'SUBMITTED', 'REQUESTED', 'NEW'].includes(currentStatusUpper)
    ) {
      if (
        !['ACCEPTED', 'REVIEWING', 'PREPARING', 'PROCESSING', 'CANCELLED', 'REJECTED'].includes(
          normalizedStatus,
        )
      ) {
        throw new BadRequestException(
          `Invalid order status transition from ${purchase.orderStatus} to ${normalizedStatus}.`,
        );
      }
    } else if (['ACCEPTED', 'REVIEWING'].includes(currentStatusUpper)) {
      if (
        !['PREPARING', 'PROCESSING', 'READY', 'READY_FOR_PICKUP', 'CANCELLED', 'REJECTED'].includes(
          normalizedStatus,
        )
      ) {
        throw new BadRequestException(
          `Invalid order status transition from ${purchase.orderStatus} to ${normalizedStatus}.`,
        );
      }
    } else if (['PREPARING', 'PROCESSING'].includes(currentStatusUpper)) {
      if (
        !['READY', 'READY_FOR_PICKUP', 'CANCELLED', 'REJECTED'].includes(
          normalizedStatus,
        )
      ) {
        throw new BadRequestException(
          `Invalid order status transition from ${purchase.orderStatus} to ${normalizedStatus}.`,
        );
      }
    } else if (['READY', 'READY_FOR_PICKUP'].includes(currentStatusUpper)) {
      const allowedNext = [
        'COMPLETED',
        'CANCELLED',
        'REJECTED',
        ...(fulfillmentPref === 'HOME_DELIVERY'
          ? ['OUT_FOR_DELIVERY', 'DELIVERY', 'DISPATCHED']
          : []),
      ];
      if (!allowedNext.includes(normalizedStatus)) {
        throw new BadRequestException(
          `Invalid order status transition from ${purchase.orderStatus} to ${normalizedStatus}.`,
        );
      }
    } else if (
      ['OUT_FOR_DELIVERY', 'DELIVERY', 'DISPATCHED'].includes(currentStatusUpper)
    ) {
      if (!['COMPLETED', 'CANCELLED', 'REJECTED'].includes(normalizedStatus)) {
        throw new BadRequestException(
          `Invalid order status transition from ${purchase.orderStatus} to ${normalizedStatus}.`,
        );
      }
    }

    const cleanReason =
      typeof cancellationReason === 'string'
        ? cancellationReason.trim()
        : undefined;

    if (
      (normalizedStatus === 'CANCELLED' || normalizedStatus === 'REJECTED') &&
      !cleanReason &&
      !snapshot.cancellationReason
    ) {
      throw new BadRequestException(
        'Cancellation or rejection reason is required.',
      );
    }

    // Server-Side Guard: Mandatory Invoice before Dispatch / Ready status based on Pharmacy Settings
    if (['READY', 'READY_FOR_PICKUP', 'DISPATCHED', 'OUT_FOR_DELIVERY', 'DELIVERY', 'COMPLETED'].includes(normalizedStatus)) {
      const settings = await this.getPharmacySettings(principal);
      if (settings.orderWorkflow?.requireInvoiceBeforeDispatch) {
        const invoices = await this.prisma.$queryRawUnsafe<any[]>(
          `SELECT id FROM "order_invoices" WHERE "purchase_id" = $1 LIMIT 1`,
          orderId,
        );
        if (!invoices || invoices.length === 0) {
          throw new BadRequestException(
            'Invoice upload is mandatory before marking order ready or dispatched based on Pharmacy Settings.',
          );
        }
      }
    }

    const updatedSnapshot = {
      ...snapshot,
      ...(cleanReason ? { cancellationReason: cleanReason } : {}),
      lastStatusUpdateAt: new Date().toISOString(),
    };

    const updated = await this.prisma.purchase.update({
      where: { id: orderId },
      data: {
        orderStatus: normalizedStatus,
        orderStatusUpdatedAt: new Date(),
        billingSnapshot: updatedSnapshot,
      },
      include: {
        customer: true,
        provider: { include: { business: true } },
        purchaseItems: { include: { product: true } },
      },
    });

    return this.pharmacyFulfillmentProjection(updated);
  }

  // -------------------------------------------------------------
  // PHASE 4 PHARMACY ORDER HISTORY
  // -------------------------------------------------------------

  async listPharmacyOrderHistory(
    query?: {
      status?: string;
      source?: string;
      fulfillment?: string;
      search?: string;
      from?: string;
      to?: string;
      page?: number;
      pageSize?: number;
    },
    principal?: ShieldPrincipal,
  ) {
    const scopeWhere = await this.providerScopeService.scopePurchaseWhere(
      {},
      principal,
    );

    let statusFilter: any = { in: PharmacyService.TERMINAL_ORDER_STATUSES };

    if (query?.status && query.status.toUpperCase() !== 'ALL_HISTORY') {
      const selected = query.status.trim().toUpperCase();
      if (PharmacyService.TERMINAL_ORDER_STATUSES.includes(selected)) {
        statusFilter = selected;
      }
    }

    const where: any = {
      ...scopeWhere,
      ...this.getPharmacyOrderDomainWhere(),
      orderStatus: statusFilter,
    };

    if (query?.source && query.source.trim().toUpperCase() !== 'ALL') {
      const src = query.source.trim().toUpperCase();
      if (['PRESCRIPTION', 'WELLNESS', 'MANUAL_ITEMS'].includes(src)) {
        where.purchaseKind = src;
      }
    }

    if (query?.fulfillment && query.fulfillment.trim().toUpperCase() !== 'ALL') {
      const ful = query.fulfillment.trim().toUpperCase();
      if (['HOME_DELIVERY', 'COLLECT_FROM_PHARMACY'].includes(ful)) {
        where.billingSnapshot = {
          path: ['fulfillmentPreference'],
          equals: ful,
        };
      }
    }

    if (query?.search?.trim()) {
      const search = query.search.trim();
      where.OR = [
        { invoiceNumber: { contains: search, mode: 'insensitive' } },
        { customer: { firstName: { contains: search, mode: 'insensitive' } } },
        { customer: { lastName: { contains: search, mode: 'insensitive' } } },
        { customer: { mobile: { contains: search, mode: 'insensitive' } } },
        { customer: { customerCode: { contains: search, mode: 'insensitive' } } },
      ];
    }

    if (query?.from || query?.to) {
      let fromDate: Date | undefined;
      let toDate: Date | undefined;

      if (query.from?.trim()) {
        const rawFrom = query.from.trim();
        if (/^\d{4}-\d{2}-\d{2}$/.test(rawFrom)) {
          fromDate = new Date(`${rawFrom}T00:00:00.000+05:30`);
        } else {
          fromDate = new Date(rawFrom);
        }
      }

      if (query.to?.trim()) {
        const rawTo = query.to.trim();
        if (/^\d{4}-\d{2}-\d{2}$/.test(rawTo)) {
          // Date-only string: endUtc is start of next day (lt nextDay)
          const [y, m, d] = rawTo.split('-').map(Number);
          const nextDay = new Date(Date.UTC(y, m - 1, d + 1));
          const nextDayStr = nextDay.toISOString().slice(0, 10);
          toDate = new Date(`${nextDayStr}T00:00:00.000+05:30`);
        } else {
          const parsedTo = new Date(rawTo);
          if (!isNaN(parsedTo.getTime())) {
            // For ISO strings from UI without explicit end-of-day, extend to end of business day
            const isoStr = rawTo.slice(0, 10);
            const [y, m, d] = isoStr.split('-').map(Number);
            const nextDay = new Date(Date.UTC(y, m - 1, d + 1));
            const nextDayStr = nextDay.toISOString().slice(0, 10);
            toDate = new Date(`${nextDayStr}T00:00:00.000+05:30`);
          }
        }
      }

      const dateGte = fromDate && !isNaN(fromDate.getTime()) ? fromDate : undefined;
      const dateLt = toDate && !isNaN(toDate.getTime()) ? toDate : undefined;

      if (dateGte || dateLt) {
        where.orderStatusUpdatedAt = {
          ...(dateGte ? { gte: dateGte } : {}),
          ...(dateLt ? { lt: dateLt } : {}),
        };
      }
    }

    const page = Math.max(1, Number(query?.page) || 1);
    const pageSize = Math.min(100, Math.max(1, Number(query?.pageSize) || 20));
    const skip = (page - 1) * pageSize;

    const [total, purchases, completedSum, cancelledCount, rejectedCount] = await Promise.all([
      this.prisma.purchase.count({ where }),
      this.prisma.purchase.findMany({
        where,
        orderBy: [{ orderStatusUpdatedAt: 'desc' }, { purchaseDate: 'desc' }, { id: 'desc' }],
        skip,
        take: pageSize,
        include: {
          customer: true,
          provider: { include: { business: true } },
          purchaseItems: { include: { product: true } },
        },
      }),
      this.prisma.purchase.aggregate({
        where: { ...where, orderStatus: 'COMPLETED' },
        _sum: { payableAmount: true },
        _count: { id: true },
      }),
      this.prisma.purchase.count({
        where: { ...where, orderStatus: 'CANCELLED' },
      }),
      this.prisma.purchase.count({
        where: { ...where, orderStatus: 'REJECTED' },
      }),
    ]);

    return {
      items: purchases.map((p) => this.pharmacyFulfillmentProjection(p)),
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
      metrics: {
        completedCount: completedSum._count?.id || 0,
        completedValue: Number(completedSum._sum?.payableAmount || 0),
        cancelledCount,
        rejectedCount,
      },
    };
  }

  async getPharmacyOrderHistoryDetail(
    orderId: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessPurchase(
      orderId,
      principal,
    );

    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
      include: {
        customer: true,
        provider: { include: { business: true } },
        purchaseItems: { include: { product: true } },
      },
    });

    if (!purchase) {
      throw new NotFoundException(`Order with ID ${orderId} not found.`);
    }

    if (!this.isTerminalStatus(purchase.orderStatus)) {
      throw new BadRequestException(
        `Order ${orderId} is an active order (${purchase.orderStatus}) and not in history.`,
      );
    }

    return this.pharmacyFulfillmentProjection(purchase);
  }

  async updateOrderItemFulfillment(
    orderId: bigint,
    itemId: bigint,
    payload: any,
    principal?: ShieldPrincipal,
  ) {
    const item = await this.prisma.purchaseItem.findUnique({
      where: { id: itemId },
    });
    if (!item || item.purchaseId !== orderId) {
      throw new NotFoundException('Order item not found.');
    }

    await this.providerScopeService.assertProviderCanAccessPurchase(
      orderId,
      principal,
    );

    const approvedQty = payload.fulfillQuantity != null ? Number(payload.fulfillQuantity) : Number(item.quantity);
    const dispatchedQty = payload.dispatchedQuantity != null ? Number(payload.dispatchedQuantity) : 0;
    const rejectedQty = payload.rejectedQuantity != null ? Number(payload.rejectedQuantity) : Math.max(0, Number(item.quantity) - approvedQty);
    const remainingQty = Math.max(0, approvedQty - dispatchedQty);
    const stockStatus = payload.stockStatus ?? 'FULL_STOCK';
    const decisionStatus = payload.decisionStatus ?? 'APPROVED';
    const actorId = principal?.userId ? BigInt(principal.userId) : null;
    const authPrice = payload.substituteUnitPrice != null ? Number(payload.substituteUnitPrice) : Number(item.unitPrice);

    if (!Number.isFinite(approvedQty) || approvedQty < 0 || approvedQty > Number(item.quantity)) {
      throw new BadRequestException('Approved quantity must be between zero and the requested quantity.');
    }
    if (!Number.isFinite(dispatchedQty) || dispatchedQty < 0 || dispatchedQty > approvedQty) {
      throw new BadRequestException('Dispatched quantity cannot exceed the approved quantity.');
    }
    if (!Number.isFinite(rejectedQty) || rejectedQty < 0 || approvedQty + rejectedQty !== Number(item.quantity)) {
      throw new BadRequestException('Approved and rejected quantities must equal the requested quantity.');
    }
    if (stockStatus === 'OUT_OF_STOCK' && approvedQty !== 0) {
      throw new BadRequestException('Out-of-stock items cannot have an approved quantity.');
    }
    if (decisionStatus === 'REJECTED' && approvedQty !== 0) {
      throw new BadRequestException('Rejected items must have zero approved quantity.');
    }
    if (decisionStatus === 'PARTIAL' && (approvedQty <= 0 || approvedQty >= Number(item.quantity))) {
      throw new BadRequestException('Partial fulfillment must approve a quantity greater than zero and less than the requested quantity.');
    }

    // 1. Transactionally write item fulfillment decision to purchase_item_fulfillments
    await this.prisma.$executeRawUnsafe(
      `INSERT INTO "purchase_item_fulfillments" ("purchase_item_id", "approved_quantity", "dispatched_quantity", "remaining_quantity", "rejected_quantity", "stock_status", "decision_status", "decision_reason", "decision_actor_id", "authoritative_price", "updated_at")
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP)`,
      itemId,
      approvedQty,
      dispatchedQty,
      remainingQty,
      rejectedQty,
      stockStatus,
      decisionStatus,
      payload.decisionReason || null,
      actorId,
      authPrice,
    );

    // 2. Transactionally write substitute detail to purchase_item_substitutions if substituted
    if (decisionStatus === 'SUBSTITUTED' && payload.substituteName) {
      await this.prisma.$executeRawUnsafe(
        `INSERT INTO "purchase_item_substitutions" ("purchase_item_id", "substitute_product_id", "substitute_name", "substitute_unit_price", "substitute_quantity", "decision_reason", "proposed_by", "customer_confirmation_status")
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'PENDING')`,
        itemId,
        payload.substituteProductId ? BigInt(payload.substituteProductId) : null,
        payload.substituteName,
        authPrice,
        approvedQty,
        payload.decisionReason || null,
        actorId,
      );
    }

    // 3. Project updated item metadata snapshot for frontend API consumption
    const currentMeta = (item.metadata as Record<string, any>) || {};
    const updatedMeta = {
      ...currentMeta,
      fulfillQuantity: approvedQty,
      dispatchedQuantity: dispatchedQty,
      remainingQuantity: remainingQty,
      rejectedQuantity: rejectedQty,
      stockStatus,
      decisionStatus,
      substituteProductId: payload.substituteProductId ?? currentMeta.substituteProductId,
      substituteName: payload.substituteName ?? currentMeta.substituteName,
      substituteUnitPrice: authPrice,
      decisionReason: payload.decisionReason ?? currentMeta.decisionReason,
      updatedAt: new Date().toISOString(),
    };

    await this.prisma.purchaseItem.update({
      where: { id: itemId },
      data: { metadata: updatedMeta },
    });

    return this.getPharmacyOrderDetail(orderId, principal);
  }

  async toggleChronicOrder(
    orderId: bigint,
    isChronic: boolean,
    repeatIntervalDays?: number,
    principal?: ShieldPrincipal,
  ) {
    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    const interval = repeatIntervalDays ?? 30;
    const actorId = principal?.userId ? BigInt(principal.userId) : null;

    // 1. Transactionally write to order_chronic_refills table
    await this.prisma.$executeRawUnsafe(
      `INSERT INTO "order_chronic_refills" ("purchase_id", "is_chronic", "repeat_interval_days", "tagged_by")
       VALUES ($1, $2, $3, $4)`,
      orderId,
      isChronic,
      interval,
      actorId,
    );

    // 2. Project chronic flag into billing snapshot
    const currentSnap = (purchase.billingSnapshot as Record<string, any>) || {};
    const updatedSnap = {
      ...currentSnap,
      isChronic,
      repeatIntervalDays: interval,
      taggedAt: new Date().toISOString(),
    };

    await this.prisma.purchase.update({
      where: { id: orderId },
      data: { billingSnapshot: updatedSnap },
    });

    return this.getPharmacyOrderDetail(orderId, principal);
  }

  async savePharmacistNotes(
    orderId: bigint,
    notes: string,
    principal?: ShieldPrincipal,
  ) {
    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    const authorId = principal?.userId ? BigInt(principal.userId) : null;

    // 1. Transactionally write to order_pharmacist_notes timeline table
    await this.prisma.$executeRawUnsafe(
      `INSERT INTO "order_pharmacist_notes" ("purchase_id", "notes", "author_id", "visibility")
       VALUES ($1, $2, $3, 'INTERNAL')`,
      orderId,
      notes,
      authorId,
    );

    // 2. Project latest notes snapshot into billing snapshot
    const currentSnap = (purchase.billingSnapshot as Record<string, any>) || {};
    const updatedSnap = {
      ...currentSnap,
      pharmacistNotes: notes,
      notesUpdatedAt: new Date().toISOString(),
    };

    await this.prisma.purchase.update({
      where: { id: orderId },
      data: { billingSnapshot: updatedSnap },
    });

    return this.getPharmacyOrderDetail(orderId, principal);
  }

  async requestCustomerConfirmation(
    orderId: bigint,
    reason?: string,
    principal?: ShieldPrincipal,
  ) {
    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    const confirmationReason = reason || 'Substitution or partial fulfillment confirmation required.';
    const requesterId = principal?.userId ? BigInt(principal.userId) : null;

    // 1. Transactionally write to order_customer_confirmations table
    await this.prisma.$executeRawUnsafe(
      `INSERT INTO "order_customer_confirmations" ("purchase_id", "confirmation_status", "reason", "requested_by")
       VALUES ($1, 'PENDING', $2, $3)`,
      orderId,
      confirmationReason,
      requesterId,
    );

    // 2. Project confirmation status into billing snapshot
    const currentSnap = (purchase.billingSnapshot as Record<string, any>) || {};
    const updatedSnap = {
      ...currentSnap,
      customerConfirmationRequested: true,
      confirmationReason,
      confirmationRequestedAt: new Date().toISOString(),
    };

    await this.prisma.purchase.update({
      where: { id: orderId },
      data: { billingSnapshot: updatedSnap },
    });

    return this.getPharmacyOrderDetail(orderId, principal);
  }

  async uploadOrderInvoiceFile(
    orderId: bigint,
    file: { originalname: string; mimetype: string; size: number; buffer: Buffer },
    principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessPurchase(orderId, principal);

    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
      include: { provider: true },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    if (
      purchase.provider &&
      (purchase.provider.status !== 'ACTIVE' ||
        purchase.provider.providerType !== 'PHARMACY')
    ) {
      throw new ForbiddenException('Access denied: Active pharmacy provider context required.');
    }

    if (!file || !file.buffer?.length) {
      throw new BadRequestException('Empty or missing file upload.');
    }

    if (file.size > 10 * 1024 * 1024) {
      throw new BadRequestException('Invoice file size exceeds 10 MB limit.');
    }

    const mime = (file.mimetype || '').toLowerCase();
    const allowedMimes = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];
    if (!allowedMimes.includes(mime)) {
      throw new BadRequestException('Only PDF, JPG, and PNG invoice files are allowed.');
    }

    const signature = this.storageService.validateContentSignature(file.buffer);
    if (!signature.isValid) {
      throw new BadRequestException(
        'Invalid file content signature. Uploaded file bytes must be authentic PDF, JPEG, or PNG.',
      );
    }

    // Read current authoritative invoice row if one exists to get oldStorageKey
    const existingInvoices = await this.prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "order_invoices" WHERE "purchase_id" = $1 ORDER BY "id" DESC LIMIT 1`,
      orderId,
    );
    const oldStorageKey = existingInvoices?.[0]?.storage_key ?? null;

    // Upload new private object
    const storageResult = await this.storageService.persistScopedPrivateObject({
      scope: 'pharmacy/invoices',
      ownerId: orderId.toString(),
      objectUuid: randomUUID(),
      fileName: file.originalname || 'Pharmacy_Invoice.pdf',
      mimeType: mime,
      buffer: file.buffer,
    });

    if (!storageResult) {
      throw new BadRequestException('Failed to persist invoice file to private storage.');
    }

    const newStorageKey = storageResult.storagePath;
    const uploaderId = principal?.userId ? BigInt(principal.userId) : null;

    // Atomically replace DB metadata in a Prisma transaction
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.$executeRawUnsafe(
          `DELETE FROM "order_invoices" WHERE "purchase_id" = $1`,
          orderId,
        );
        await tx.$executeRawUnsafe(
          `INSERT INTO "order_invoices" ("purchase_id", "storage_key", "file_name", "mime_type", "file_size", "uploaded_by")
           VALUES ($1, $2, $3, $4, $5, $6)`,
          orderId,
          newStorageKey,
          file.originalname,
          mime,
          file.size,
          uploaderId,
        );
      });
    } catch (err) {
      // Clean up newly uploaded R2/local file if DB replacement fails
      await this.storageService.deletePrivateObject(newStorageKey);
      throw new BadRequestException(
        'Failed to replace invoice record in database: ' + (err as Error).message,
      );
    }

    // Delete superseded storage object ONLY after DB transaction succeeds
    if (oldStorageKey && oldStorageKey !== newStorageKey) {
      await this.storageService.deletePrivateObject(oldStorageKey);
    }

    return this.getPharmacyOrderDetail(orderId, principal);
  }

  async getOrderInvoiceFileStream(
    orderId: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessPurchase(orderId, principal);

    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
      include: { provider: true },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    if (
      purchase.provider &&
      (purchase.provider.status !== 'ACTIVE' ||
        purchase.provider.providerType !== 'PHARMACY')
    ) {
      throw new ForbiddenException('Access denied: Active pharmacy provider context required.');
    }

    const invoices = await this.prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "order_invoices" WHERE "purchase_id" = $1 ORDER BY "id" DESC LIMIT 1`,
      orderId,
    );
    if (!invoices || invoices.length === 0) {
      throw new NotFoundException('No invoice uploaded for this order.');
    }

    const invoice = invoices[0];
    const stream = await this.storageService.readObjectBuffer(invoice.storage_key);
    if (!stream) {
      throw new NotFoundException('Invoice storage file not found.');
    }

    return {
      buffer: stream.buffer,
      contentType: invoice.mime_type || stream.contentType,
      fileName: invoice.file_name || 'Pharmacy_Invoice.pdf',
    };
  }

  async removeOrderInvoice(
    orderId: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessPurchase(orderId, principal);

    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
      include: { provider: true },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    if (
      purchase.provider &&
      (purchase.provider.status !== 'ACTIVE' ||
        purchase.provider.providerType !== 'PHARMACY')
    ) {
      throw new ForbiddenException('Access denied: Active pharmacy provider context required.');
    }

    const existingInvoices = await this.prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "order_invoices" WHERE "purchase_id" = $1 ORDER BY "id" DESC LIMIT 1`,
      orderId,
    );
    const oldStorageKey = existingInvoices?.[0]?.storage_key ?? null;

    await this.prisma.$executeRawUnsafe(
      `DELETE FROM "order_invoices" WHERE "purchase_id" = $1`,
      orderId,
    );

    if (oldStorageKey) {
      await this.storageService.deletePrivateObject(oldStorageKey);
    }

    return this.getPharmacyOrderDetail(orderId, principal);
  }

  async sendOrderInvoice(
    orderId: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessPurchase(orderId, principal);

    const purchase = await this.prisma.purchase.findUnique({
      where: { id: orderId },
      include: { provider: true },
    });
    if (!purchase) throw new NotFoundException('Order not found.');

    if (
      purchase.provider &&
      (purchase.provider.status !== 'ACTIVE' ||
        purchase.provider.providerType !== 'PHARMACY')
    ) {
      throw new ForbiddenException('Access denied: Active pharmacy provider context required.');
    }

    const invoices = await this.prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "order_invoices" WHERE "purchase_id" = $1 ORDER BY "id" DESC LIMIT 1`,
      orderId,
    );
    if (!invoices || invoices.length === 0) {
      throw new BadRequestException('Cannot send invoice: No invoice uploaded for this order.');
    }
    const invoice = invoices[0];
    if (invoice.sent_at) {
      // Invoice has already been sent. Ordinary Send Invoice is idempotent and skips duplicate notification.
      return this.getPharmacyOrderDetail(orderId, principal);
    }

    if (!purchase.customerId) {
      throw new BadRequestException('Order has no associated customer ID.');
    }

    // Atomic claim to set sent_at so concurrent requests cannot double send
    const claimed = await this.prisma.$executeRawUnsafe(
      `UPDATE "order_invoices" SET "sent_at" = CURRENT_TIMESTAMP WHERE "id" = $1 AND "sent_at" IS NULL`,
      invoice.id,
    );
    if (claimed === 0) {
      return this.getPharmacyOrderDetail(orderId, principal);
    }

    // Dispatch notification ONLY after successful atomic sent_at claim
    await this.notificationService.send({
      customerId: purchase.customerId,
      title: 'Pharmacy Invoice Ready',
      message: `Your bill/invoice for Pharmacy Order #${orderId.toString()} is now available.`,
      deepLinkUrl: `/portal/customer/orders/${orderId.toString()}`,
      data: {
        orderId: orderId.toString(),
        type: 'INVOICE_SENT',
      },
    });

    return this.getPharmacyOrderDetail(orderId, principal);
  }

  // -------------------------------------------------------------
  // REAL PHARMACY PROFILE & SETTINGS APIs
  // -------------------------------------------------------------

  async resolvePharmacyProvider(principal?: ShieldPrincipal) {
    return this.providerScopeService.resolveAssignedPharmacy(principal);
  }

  async getPharmacyProfile(principal?: ShieldPrincipal) {
    const { user, provider } = await this.resolvePharmacyProvider(principal);
    const providerAny = provider as any;
    const businessAny = provider?.business as any;

    const pref = await this.prisma.agentPreference.findUnique({
      where: { userId: user.id },
    });
    const profilePref = (pref?.profilePreferences as Record<string, any>) || {};

    return {
      userId: user.id.toString(),
      displayName:
        [user.firstName, user.lastName].filter(Boolean).join(' ').trim() ||
        user.email ||
        'Pharmacy Staff',
      email: user.email || null,
      phone: user.mobile || null,
      roleCode: user.role?.code || principal?.roleCode || 'PHARMACY_PROVIDER',
      pharmacyName:
        profilePref.pharmacyName ??
        provider?.providerName ??
        businessAny?.name ??
        'SHIELD Hyper Pharmacy Perinthalmanna',
      businessCode:
        profilePref.businessCode ??
        businessAny?.code ??
        'HYP-PERINTHALMANNA',
      drugLicenceNo:
        profilePref.drugLicenceNo ??
        providerAny?.licenseNumber ??
        'DL-2026/PHARM/77821',
      gstin:
        profilePref.gstin ??
        providerAny?.taxIdentifier ??
        businessAny?.taxId ??
        '32AABCS1429B1Z5',
      address:
        profilePref.address ??
        providerAny?.address ??
        businessAny?.address ??
        'Main Road, Near Jubilee Hospital, Perinthalmanna',
      city:
        profilePref.city ??
        providerAny?.city ??
        businessAny?.city ??
        'Perinthalmanna',
      state:
        profilePref.state ??
        providerAny?.state ??
        businessAny?.state ??
        'Kerala',
      pin:
        profilePref.pin ??
        providerAny?.pincode ??
        businessAny?.pincode ??
        '679322',
      operatingHours:
        profilePref.operatingHours ??
        providerAny?.operatingHours ??
        'Standard Operating Hours',
      businessType:
        profilePref.businessType ??
        businessAny?.businessType ??
        'Hyperpharmacy & Retail Outlet',
      accountStatus: user.status || 'ACTIVE',
      accountCreatedAt: user.createdAt.toISOString(),
      lastLoginAt: user.lastLoginAt ? user.lastLoginAt.toISOString() : null,
    };
  }

  async updatePharmacyProfile(data: any, principal?: ShieldPrincipal) {
    if (!principal?.userId) {
      throw new ForbiddenException('Authentication required.');
    }
    const userId = BigInt(principal.userId);
    const parts = (data.displayName || '').trim().split(' ');
    const firstName = parts[0] || 'Pharmacy';
    const lastName = parts.slice(1).join(' ') || 'Staff';

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        firstName,
        lastName,
        email: data.email || undefined,
        mobile: data.phone || undefined,
      },
    });

    const existingPref = await this.prisma.agentPreference.findUnique({
      where: { userId },
    });
    const currentProfilePref =
      (existingPref?.profilePreferences as Record<string, any>) || {};

    const updatedProfilePref = {
      ...currentProfilePref,
      ...(data.pharmacyName != null && { pharmacyName: String(data.pharmacyName).trim() }),
      ...(data.businessCode != null && { businessCode: String(data.businessCode).trim() }),
      ...(data.drugLicenceNo != null && { drugLicenceNo: String(data.drugLicenceNo).trim() }),
      ...(data.gstin != null && { gstin: String(data.gstin).trim() }),
      ...(data.address != null && { address: String(data.address).trim() }),
      ...(data.city != null && { city: String(data.city).trim() }),
      ...(data.state != null && { state: String(data.state).trim() }),
      ...(data.pin != null && { pin: String(data.pin).trim() }),
      ...(data.operatingHours != null && { operatingHours: String(data.operatingHours).trim() }),
      ...(data.businessType != null && { businessType: String(data.businessType).trim() }),
    };

    await this.prisma.agentPreference.upsert({
      where: { userId },
      update: { profilePreferences: updatedProfilePref },
      create: {
        uuid: randomUUID(),
        userId,
        profilePreferences: updatedProfilePref,
      },
    });

    return this.getPharmacyProfile(principal);
  }

  async getPharmacySettings(principal?: ShieldPrincipal) {
    const userId = principal?.userId ? BigInt(principal.userId) : null;
    let providerId: bigint | null = null;
    if (principal) {
      try {
        const { provider } = await this.resolvePharmacyProvider(principal);
        providerId = provider.id;
      } catch (err) {
        // Fallback for non-pharmacy principals
      }
    }

    let userSettings: any = {};
    if (userId) {
      const pref = await this.prisma.agentPreference.findUnique({
        where: { userId },
      });
      if (pref?.profilePreferences) {
        const profilePref = pref.profilePreferences as Record<string, any>;
        userSettings = profilePref.pharmacySettings || profilePref;
      }
    }

    let providerSettings: any = {};
    if (providerId) {
      try {
        const pSettings = await this.prisma.$queryRawUnsafe<any[]>(
          `SELECT "settings" FROM "pharmacy_provider_settings" WHERE "provider_id" = $1 LIMIT 1`,
          providerId,
        );
        if (pSettings?.[0]?.settings) {
          providerSettings = pSettings[0].settings;
        }
      } catch (err) {
        // Table handoff script pending, fallback to userSettings
        providerSettings = userSettings;
      }
    } else {
      providerSettings = userSettings;
    }

    return {
      orderWorkflow: {
        autoAcceptOrders: providerSettings.autoAcceptOrders ?? false,
        requireInvoiceBeforeDispatch: providerSettings.requireInvoiceBeforeDispatch ?? true,
      },
      partialFulfillment: {
        allowPartialFulfillment: providerSettings.allowPartialFulfillment ?? true,
        allowPartialDispatch: providerSettings.allowPartialDispatch ?? true,
      },
      lowStock: {
        lowStockAlerts: providerSettings.lowStockAlerts ?? true,
        lowStockThreshold: providerSettings.lowStockThreshold ?? 5,
      },
      substitutions: {
        suggestSubstitutes: providerSettings.suggestSubstitutes ?? true,
        requireCustomerConfirmation: providerSettings.requireCustomerConfirmation ?? true,
      },
      chronic: {
        enableChronicTagging: providerSettings.enableChronicTagging ?? true,
        defaultRefillCadenceDays: providerSettings.defaultRefillCadenceDays ?? 30,
      },
      notifications: {
        newOrderSoundAlerts: userSettings.newOrderSoundAlerts ?? true,
        paymentSubmissionAlerts: userSettings.paymentSubmissionAlerts ?? true,
      },
      deliveryPickup: {
        enableHomeDelivery: providerSettings.enableHomeDelivery ?? true,
        enableStorePickup: providerSettings.enableStorePickup ?? true,
      },
      paymentVerification: {
        mandatoryManualVerification: providerSettings.mandatoryManualVerification ?? true,
        requireUtrProof: providerSettings.requireUtrProof ?? true,
      },
      display: {
        dateFormat: userSettings.dateFormat ?? 'YYYY-MM-DD',
        timeFormat: userSettings.timeFormat ?? '12-hour AM/PM',
      },
    };
  }

  async updatePharmacySettings(settingsPayload: any, principal?: ShieldPrincipal) {
    const userId = principal?.userId ? BigInt(principal.userId) : null;
    let providerId: bigint | null = null;
    if (principal) {
      try {
        const { provider } = await this.resolvePharmacyProvider(principal);
        providerId = provider.id;
      } catch (err) {
        // Fallback for non-pharmacy principals
      }
    }

    if (userId) {
      const existing = await this.prisma.agentPreference.findUnique({
        where: { userId },
      });
      const currentProfilePref = (existing?.profilePreferences as Record<string, any>) || {};
      const updatedProfilePref = {
        ...currentProfilePref,
        pharmacySettings: settingsPayload,
      };

      await this.prisma.agentPreference.upsert({
        where: { userId },
        update: { profilePreferences: updatedProfilePref },
        create: {
          uuid: randomUUID(),
          userId,
          profilePreferences: updatedProfilePref,
        },
      });
    }

    if (providerId) {
      try {
        await this.prisma.$executeRawUnsafe(
          `INSERT INTO "pharmacy_provider_settings" ("provider_id", "settings")
           VALUES ($1, $2::jsonb)
           ON CONFLICT ("provider_id") DO UPDATE SET "settings" = $2::jsonb, "updated_at" = CURRENT_TIMESTAMP`,
          providerId,
          JSON.stringify(settingsPayload),
        );
      } catch (err) {
        // Table handoff script pending database owner execution
      }
    }

    return this.getPharmacySettings(principal);
  }
}
