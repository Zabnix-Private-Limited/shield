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

  async listWellnessDemoProducts() {
    return this.prisma.product.findMany({
      where: { isDemoAvailable: true, status: 'DEMO' },
      orderBy: { productName: 'asc' },
    });
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
