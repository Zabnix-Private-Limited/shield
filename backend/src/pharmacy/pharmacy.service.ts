import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class PharmacyService {
  constructor(private prisma: PrismaService) {}

  async createProduct(data: { productName: string; brand: string; productCode: string; unit?: string }) {
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

  async createPurchase(data: {
    customerId: bigint;
    providerId: bigint;
    invoiceNumber: string;
    items: Array<{ productId: bigint; quantity: number; unitPrice: number }>;
    staffUserId?: bigint;
  }) {
    // 1. Calculate raw total
    let totalAmount = 0;
    for (const item of data.items) {
      totalAmount += item.quantity * item.unitPrice;
    }

    // 2. Fetch customer, membership, and wallet
    const customer = await this.prisma.customer.findUnique({
      where: { id: data.customerId },
      include: { membership: { include: { membershipType: true } }, wallet: true },
    });

    if (!customer) {
      throw new NotFoundException(`Customer with ID ${data.customerId} not found`);
    }
    if (!customer.wallet) {
      throw new BadRequestException('Customer does not have a wallet configured.');
    }

    // 3. Compute discount based on membership type discount percentage
    const discountPercent = Number(customer.membership?.membershipType?.discountPercentage || 0);
    const discountAmount = Number((totalAmount * (discountPercent / 100)).toFixed(2));
    const payableAmount = Number((totalAmount - discountAmount).toFixed(2));

    // 4. Prisma Transaction
    return this.prisma.$transaction(async (tx) => {
      // a. Create Purchase
      const purchase = await tx.purchase.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          providerId: data.providerId,
          invoiceNumber: data.invoiceNumber,
          totalAmount,
          discountAmount,
          payableAmount,
          purchaseDate: new Date(),
        },
      });

      // b. Create Purchase Items
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

      // c. Create Wallet Transaction (Debit)
      await tx.walletTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: customer.wallet!.id,
          transactionType: 'PURCHASE',
          amount: payableAmount,
          remarks: `Pharmacy purchase (Invoice: ${data.invoiceNumber})`,
          createdBy: data.staffUserId,
          referenceType: 'PURCHASE',
          referenceId: purchase.id,
        },
      });

      return purchase;
    });
  }

  async listPurchases(customerId?: bigint) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    }
    return this.prisma.purchase.findMany({
      where: whereClause,
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
