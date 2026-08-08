import {
  Injectable,
  NotFoundException,
  BadRequestException,
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
        OR: [
          { status: 'ACTIVE' },
          {
            dataSource: 'LEGACY_XLS_20260805',
            status: 'STAGING',
            isDemoAvailable: true,
          },
        ],
      },
      include: { category: true },
      orderBy: { productName: 'asc' },
    });
  }

  private customerWellnessWhere() {
    return {
      OR: [
        { status: 'ACTIVE', dataSource: { not: 'LEGACY_XLS_20260805' } },
        { dataSource: 'LEGACY_XLS_20260805', isDemoAvailable: true },
      ],
    };
  }

  private customerWellnessProduct(product: any) {
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
      catalogueKind:
        product.dataSource === 'LEGACY_XLS_20260805' ? 'DEMO' : 'STANDARD',
      // A customer catalogue record is not an orderable offer.  There is no
      // customer cart/checkout/order-creation contract yet, so exposing this
      // explicitly prevents Flutter from inferring purchasability from a price
      // or stock field.
      purchasable: false,
      purchasabilityReason:
        'Online checkout is not available for this catalogue yet.',
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
      disclosure: 'Demo products only — not live Sahakar inventory.',
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
}
