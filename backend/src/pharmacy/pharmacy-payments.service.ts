import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { TimelineService } from '../timeline/timeline.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { ShieldPrincipal } from '../auth/auth.types';
import {
  RejectPaymentDto,
  SubmitManualPaymentDto,
} from './dto/pharmacy-payments.dto';
import { randomUUID } from 'crypto';

@Injectable()
export class PharmacyPaymentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly timelineService: TimelineService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  private async getPharmacyProviderId(
    principal?: ShieldPrincipal,
  ): Promise<bigint> {
    const { provider } =
      await this.providerScopeService.resolveAssignedPharmacy(principal);
    return provider.id;
  }

  private formatCustomerName(
    c?: { firstName?: string | null; lastName?: string | null } | null,
  ): string {
    if (!c) return 'Customer';
    const first = c.firstName?.trim() || '';
    const last = c.lastName?.trim() || '';
    const full = `${first} ${last}`.trim();
    return full || 'Customer';
  }

  private async getPaymentVerificationSettings(providerId: bigint): Promise<{
    requireUtrProof: boolean;
  }> {
    try {
      const rows = await this.prisma.$queryRawUnsafe<any[]>(
        `SELECT "settings" FROM "pharmacy_provider_settings" WHERE "provider_id" = $1 LIMIT 1`,
        providerId,
      );
      const settings = rows?.[0]?.settings as Record<string, unknown> | undefined;
      return {
        requireUtrProof: settings?.requireUtrProof !== false,
      };
    } catch {
      // Failing closed retains the documented default until the settings table is available.
      return { requireUtrProof: true };
    }
  }

  getBusinessDayInterval(
    timeZone = 'Asia/Kolkata',
    now = new Date(),
  ): { startUtc: Date; endUtc: Date } {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });

    const [{ value: year }, , { value: month }, , { value: day }] =
      formatter.formatToParts(now);
    const dateStr = `${year}-${month}-${day}`;

    const startLocalStr = `${dateStr}T00:00:00.000`;
    const startUtc = new Date(`${startLocalStr}+05:30`);
    const endUtc = new Date(startUtc.getTime() + 24 * 60 * 60 * 1000);

    return { startUtc, endUtc };
  }

  async getPharmacyDashboard(principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);

    const { startUtc: startOfToday, endUtc: startOfNextDay } =
      this.getBusinessDayInterval('Asia/Kolkata');

    const pharmacyDomainWhere = {
      providerId,
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

    const [
      newOrdersCount,
      preparingOrdersCount,
      readyOrdersCount,
      deliveryOrdersCount,
      completedTodayCount,
      completedTodayAggregate,
      pendingPaymentsCount,
      approvedTodayCount,
      approvedTodayAggregate,
      activeBankCount,
      activeUpiCount,
      recentOrders,
      recentPayments,
    ] = await Promise.all([
      // New Orders
      this.prisma.purchase.count({
        where: {
          ...pharmacyDomainWhere,
          orderStatus: { in: ['PLACED', 'SUBMITTED', 'REQUESTED', 'NEW'] },
        },
      }),
      // Preparing Orders (includes ACCEPTED, REVIEWING, PREPARING, PROCESSING)
      this.prisma.purchase.count({
        where: {
          ...pharmacyDomainWhere,
          orderStatus: {
            in: ['ACCEPTED', 'REVIEWING', 'PREPARING', 'PROCESSING'],
          },
        },
      }),
      // Ready Orders
      this.prisma.purchase.count({
        where: {
          ...pharmacyDomainWhere,
          orderStatus: { in: ['READY', 'READY_FOR_PICKUP'] },
        },
      }),
      // Delivery Orders
      this.prisma.purchase.count({
        where: {
          ...pharmacyDomainWhere,
          orderStatus: { in: ['OUT_FOR_DELIVERY', 'DELIVERY', 'DISPATCHED'] },
        },
      }),
      // Completed Today Count (uses ONLY orderStatusUpdatedAt within today's business interval)
      this.prisma.purchase.count({
        where: {
          ...pharmacyDomainWhere,
          orderStatus: 'COMPLETED',
          orderStatusUpdatedAt: {
            gte: startOfToday,
            lt: startOfNextDay,
          },
        },
      }),
      // Completed Today Sum
      this.prisma.purchase.aggregate({
        where: {
          ...pharmacyDomainWhere,
          orderStatus: 'COMPLETED',
          orderStatusUpdatedAt: {
            gte: startOfToday,
            lt: startOfNextDay,
          },
        },
        _sum: { payableAmount: true },
      }),
      // Pending Payment Verification Count
      this.prisma.walletRechargeIntent.count({
        where: {
          providerId,
          status: 'PENDING',
        },
      }),
      // Approved Payments Today Count
      this.prisma.walletRechargeIntent.count({
        where: {
          providerId,
          status: 'APPROVED',
          reviewedAt: {
            gte: startOfToday,
            lt: startOfNextDay,
          },
        },
      }),
      // Approved Amount Today Sum
      this.prisma.walletRechargeIntent.aggregate({
        where: {
          providerId,
          status: 'APPROVED',
          reviewedAt: {
            gte: startOfToday,
            lt: startOfNextDay,
          },
        },
        _sum: { amount: true },
      }),
      // Bank Configured check
      (this.prisma as any).serviceProviderPaymentMethod.count({
        where: {
          providerId,
          methodType: 'BANK_ACCOUNT',
          isActive: true,
          deletedAt: null,
        },
      }),
      // UPI Configured check
      (this.prisma as any).serviceProviderPaymentMethod.count({
        where: {
          providerId,
          methodType: 'UPI',
          isActive: true,
          deletedAt: null,
        },
      }),
      // Recent Orders (5)
      this.prisma.purchase.findMany({
        where: pharmacyDomainWhere,
        orderBy: [
          { orderStatusUpdatedAt: 'desc' },
          { purchaseDate: 'desc' },
          { id: 'desc' },
        ],
        take: 5,
        include: {
          customer: {
            select: {
              firstName: true,
              lastName: true,
              mobile: true,
              customerCode: true,
            },
          },
        },
      }),
      // Recent Payments (5)
      this.prisma.walletRechargeIntent.findMany({
        where: { providerId },
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: {
          customer: {
            select: {
              firstName: true,
              lastName: true,
              mobile: true,
              customerCode: true,
            },
          },
        },
      }),
    ]);

    return {
      orders: {
        new: newOrdersCount,
        preparing: preparingOrdersCount,
        ready: readyOrdersCount,
        delivery: deliveryOrdersCount,
        completedToday: completedTodayCount,
        orderValueToday: Number(
          completedTodayAggregate._sum?.payableAmount || 0,
        ),
      },
      payments: {
        pendingVerification: pendingPaymentsCount,
        approvedToday: approvedTodayCount,
        approvedAmountToday: Number(approvedTodayAggregate._sum?.amount || 0),
      },
      paymentConfiguration: {
        bankConfigured: activeBankCount > 0,
        upiConfigured: activeUpiCount > 0,
      },
      recentOrders: recentOrders.map((o) => ({
        id: o.id.toString(),
        invoiceNumber: o.invoiceNumber || `ORD-${o.id}`,
        customerName: this.formatCustomerName(o.customer),
        customerPhone: o.customer?.mobile || '',
        orderStatus: o.orderStatus,
        payableAmount: Number(o.payableAmount || 0),
        purchaseDate: o.purchaseDate,
      })),
      recentPayments: recentPayments.map((p) => ({
        id: p.id.toString(),
        customerName: this.formatCustomerName(p.customer),
        customerCode: p.customer?.customerCode || '',
        amount: Number(p.amount),
        paymentChannel: p.paymentChannel || 'BANK_TRANSFER',
        status: p.status,
        createdAt: p.createdAt,
      })),
    };
  }

  async listPayments(
    principal?: ShieldPrincipal,
    query?: { status?: string; search?: string },
  ) {
    const providerId = await this.getPharmacyProviderId(principal);
    const where: any = { providerId };

    if (query?.status && query.status.toUpperCase() !== 'ALL') {
      where.status = query.status.trim().toUpperCase();
    }

    if (query?.search?.trim()) {
      const search = query.search.trim();
      where.OR = [
        { referenceNumber: { contains: search, mode: 'insensitive' } },
        { customer: { firstName: { contains: search, mode: 'insensitive' } } },
        { customer: { lastName: { contains: search, mode: 'insensitive' } } },
        { customer: { mobile: { contains: search, mode: 'insensitive' } } },
        {
          customer: { customerCode: { contains: search, mode: 'insensitive' } },
        },
      ];
    }

    const intents = await this.prisma.walletRechargeIntent.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }],
      include: {
        customer: {
          select: {
            firstName: true,
            lastName: true,
            mobile: true,
            customerCode: true,
          },
        },
      },
    });

    const paymentItems = [];
    for (const p of intents) {
      let proofUrl: string | undefined;
      if (p.proofStoragePath) {
        proofUrl =
          (await this.storageService.createDownloadUrl(p.proofStoragePath)) ||
          undefined;
      }

      paymentItems.push({
        id: p.id.toString(),
        uuid: p.uuid,
        customerId: p.customerId.toString(),
        customerName: this.formatCustomerName(p.customer),
        customerPhone: p.customer?.mobile || '',
        customerCode: p.customer?.customerCode || '',
        walletId: p.walletId.toString(),
        amount: Number(p.amount),
        paymentChannel: p.paymentChannel || 'BANK_TRANSFER',
        referenceNumber: p.referenceNumber || p.providerReference || '',
        proofUrl,
        status: p.status,
        rejectionReason: p.rejectionReason || undefined,
        reviewedAt: p.reviewedAt || undefined,
        createdAt: p.createdAt,
      });
    }

    return { payments: paymentItems };
  }

  async getPaymentDetail(id: bigint, principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);
    const intent = await this.prisma.walletRechargeIntent.findFirst({
      where: { id, providerId },
      include: {
        customer: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            mobile: true,
            customerCode: true,
          },
        },
        wallet: true,
      },
    });

    if (!intent) {
      throw new NotFoundException(
        'Payment request not found or access denied for this pharmacy.',
      );
    }

    let proofUrl: string | undefined;
    if (intent.proofStoragePath) {
      proofUrl =
        (await this.storageService.createDownloadUrl(
          intent.proofStoragePath,
        )) || undefined;
    }

    return {
      id: intent.id.toString(),
      uuid: intent.uuid,
      customerId: intent.customerId.toString(),
      customerName: this.formatCustomerName(intent.customer),
      customerPhone: intent.customer?.mobile || '',
      customerCode: intent.customer?.customerCode || '',
      walletId: intent.walletId.toString(),
      amount: Number(intent.amount),
      paymentChannel: intent.paymentChannel || 'BANK_TRANSFER',
      referenceNumber: intent.referenceNumber || intent.providerReference || '',
      proofUrl,
      status: intent.status,
      destinationSnapshot: intent.destinationSnapshot || undefined,
      rejectionReason: intent.rejectionReason || undefined,
      reviewedAt: intent.reviewedAt || undefined,
      createdAt: intent.createdAt,
    };
  }

  async searchCustomers(query?: string, principal?: ShieldPrincipal) {
    await this.getPharmacyProviderId(principal);
    const q = (query || '').trim();

    const whereCondition =
      q.length > 0
        ? {
            OR: [
              { firstName: { contains: q, mode: 'insensitive' as const } },
              { lastName: { contains: q, mode: 'insensitive' as const } },
              { mobile: { contains: q } },
              { customerCode: { contains: q, mode: 'insensitive' as const } },
            ],
          }
        : {};

    const customers = await this.prisma.customer.findMany({
      where: whereCondition,
      take: 15,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        mobile: true,
        customerCode: true,
        wallet: { select: { id: true } },
        shieldCard: { select: { id: true, cardNumber: true, status: true } },
        membership: {
          select: {
            id: true,
            membershipNumber: true,
            status: true,
            expiryDate: true,
          },
        },
      },
    });

    return customers.map((c) => {
      const isMember = this.hasActiveRechargeEligibility(c);

      return {
        id: c.id.toString(),
        name: this.formatCustomerName(c),
        mobile: c.mobile,
        customerCode:
          c.customerCode ??
          c.shieldCard?.cardNumber ??
          c.membership?.membershipNumber ??
          'SHIELD Member',
        walletId: c.wallet?.id?.toString() ?? null,
        isMembershipHolder: isMember,
        membershipBadge: isMember
          ? 'SHIELD Privilege Member'
          : 'Non-Member (Wellness Only)',
      };
    });
  }

  async submitManualPayment(
    dto: SubmitManualPaymentDto,
    principal?: ShieldPrincipal,
  ) {
    const providerId = await this.getPharmacyProviderId(principal);
    const paymentVerification = await this.getPaymentVerificationSettings(
      providerId,
    );
    if (!dto.customerId?.trim()) {
      throw new BadRequestException('Customer ID is required.');
    }
    if (!dto.amount || dto.amount < 10000) {
      throw new BadRequestException(
        'Minimum wallet recharge amount is ₹10,000.',
      );
    }
    if (Math.floor(dto.amount) % 10000 !== 0) {
      throw new BadRequestException(
        'Wallet recharge amount must be in multiples of ₹10,000 (e.g. ₹10,000, ₹20,000, ₹30,000).',
      );
    }

    const requiresReference = [
      'BANK_TRANSFER',
      'UPI',
      'COUNTER_UPI',
      'PAID_THROUGH_AGENT',
      'CARD_POS',
    ].includes(dto.paymentChannel);
    if (
      paymentVerification.requireUtrProof &&
      requiresReference &&
      !dto.referenceNumber?.trim()
    ) {
      throw new BadRequestException(
        'A UTR, payment reference, or POS receipt number is required for this payment channel.',
      );
    }

    const customerId = BigInt(dto.customerId.trim());
    let customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      include: {
        wallet: true,
        shieldCard: true,
        membership: true,
      },
    });

    if (!customer) {
      throw new NotFoundException('Customer record not found.');
    }

    const isMembershipHolder = this.hasActiveRechargeEligibility(customer);

    if (!isMembershipHolder) {
      throw new BadRequestException(
        'Wallet recharge requires an active, unexpired SHIELD membership and an issued or active SHIELD Privilege Card. A customer code alone is not sufficient.',
      );
    }

    if (customer.wallet && customer.wallet.status !== 'ACTIVE') {
      throw new BadRequestException(
        'Wallet recharge is unavailable because this customer wallet is not active.',
      );
    }

    let wallet = customer.wallet;
    if (!wallet) {
      wallet = await this.prisma.wallet.create({
        data: {
          uuid: randomUUID(),
          customerId,
          status: 'ACTIVE',
        },
      });
    }

    let destinationSnapshot: any = null;
    if (dto.paymentMethodId?.trim()) {
      const method = await (
        this.prisma as any
      ).serviceProviderPaymentMethod.findFirst({
        where: {
          id: BigInt(dto.paymentMethodId.trim()),
          providerId,
          deletedAt: null,
        },
      });
      if (method) {
        destinationSnapshot = {
          id: method.id.toString(),
          methodType: method.methodType,
          bankName: method.bankName,
          accountHolderName: method.accountHolderName,
          accountNumber: method.accountNumber
            ? `•••• ${method.accountNumber.slice(-4)}`
            : undefined,
          ifscCode: method.ifscCode,
          upiId: method.upiId,
        };
      }
    }

    const isAutoApprove = dto.autoApprove ?? false;
    const initialStatus = isAutoApprove ? 'APPROVED' : 'PENDING';
    const now = new Date();
    const refNum =
      dto.referenceNumber?.trim() ||
      `RCP-PHARM-${Date.now().toString().slice(-6)}`;

    const created = await this.prisma.walletRechargeIntent.create({
      data: {
        uuid: randomUUID(),
        customerId,
        walletId: wallet.id,
        providerId,
        paymentMethodId: dto.paymentMethodId
          ? BigInt(dto.paymentMethodId)
          : undefined,
        paymentChannel: dto.paymentChannel || 'CASH',
        referenceNumber: refNum,
        amount: dto.amount,
        idempotencyKey: `MANUAL-${randomUUID()}`,
        status: initialStatus,
        destinationSnapshot,
        reviewedBy:
          isAutoApprove && principal?.userId
            ? BigInt(principal.userId)
            : undefined,
        reviewedAt: isAutoApprove ? now : undefined,
        creditedAt: isAutoApprove ? now : undefined,
      },
    });

    if (isAutoApprove) {
      const bonusAmount = Number((dto.amount * 0.1).toFixed(2));

      await this.prisma.cashWalletTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: 'RECHARGE',
          amount: dto.amount,
          referenceType: 'COUNTER_PAYMENT_ACCEPTED',
          referenceId: created.id,
          remarks: `Counter ${dto.paymentChannel || 'payment'} accepted and verified by Pharmacy Staff. Note: ${dto.customerNotes || 'In-person payment'}.`,
        },
      });

      await this.prisma.walletTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: 'RECHARGE',
          subLedgerType: 'CASH',
          amount: dto.amount,
          referenceType: 'COUNTER_PAYMENT_ACCEPTED',
          referenceId: created.id,
          remarks: `Counter ${dto.paymentChannel || 'payment'} accepted and verified by Pharmacy Staff. Note: ${dto.customerNotes || 'In-person payment'}.`,
        },
      });

      // 10% Extra Bonus Credit Entry
      await this.prisma.benefitLedgerTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: 'RECHARGE',
          amount: bonusAmount,
          serviceType: 'PHARMACY',
          referenceType: 'COUNTER_PAYMENT_BONUS',
          referenceId: created.id,
          remarks: `10% Extra Promotional Bonus Credit for ₹${dto.amount} Counter Wallet Recharge.`,
        },
      });
    }

    await this.timelineService.recordAuditLog({
      action: isAutoApprove
        ? 'COUNTER_PAYMENT_ACCEPTED'
        : 'MANUAL_PAYMENT_SUBMITTED',
      entityType: 'WALLET_RECHARGE_INTENT',
      entityId: created.id,
      userId: principal?.userId ? BigInt(principal.userId) : undefined,
      newData: {
        amount: dto.amount,
        bonusAmount: Number((dto.amount * 0.1).toFixed(2)),
        totalCredit: Number((dto.amount * 1.1).toFixed(2)),
        paymentChannel: dto.paymentChannel,
        referenceNumber: refNum,
        providerId: providerId.toString(),
        autoApprove: isAutoApprove,
      },
    });

    return {
      id: created.id.toString(),
      uuid: created.uuid,
      amount: Number(created.amount),
      bonusAmount: Number((dto.amount * 0.1).toFixed(2)),
      totalCredit: Number((dto.amount * 1.1).toFixed(2)),
      paymentChannel: created.paymentChannel,
      status: created.status,
      referenceNumber: refNum,
      createdAt: created.createdAt,
    };
  }

  async approvePayment(id: bigint, principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);

    return this.prisma.$transaction(async (tx) => {
      const now = new Date();

      // 1. Atomic Concurrency Claim: Only one concurrent request can transition status PENDING -> APPROVED
      const updateResult = await tx.walletRechargeIntent.updateMany({
        where: { id, providerId, status: 'PENDING' },
        data: {
          status: 'APPROVED',
          reviewedBy: principal?.userId ? BigInt(principal.userId) : undefined,
          reviewedAt: now,
          creditedAt: now,
          updatedAt: now,
        },
      });

      if (updateResult.count === 0) {
        const existing = await tx.walletRechargeIntent.findFirst({
          where: { id, providerId },
        });
        if (!existing) {
          throw new NotFoundException(
            'Payment request not found or access denied for this pharmacy.',
          );
        }
        throw new BadRequestException(
          `Payment request cannot be approved because current status is ${existing.status}.`,
        );
      }

      const intent = await tx.walletRechargeIntent.findFirst({
        where: { id },
      });

      if (!intent) {
        throw new NotFoundException(
          'Payment request not found after state claim.',
        );
      }

      const baseAmount = Number(intent.amount);
      const bonusAmount = Number((baseAmount * 0.1).toFixed(2));

      // 2. Create dynamic wallet ledger entry (Cash Wallet & Main Wallet Transactions)
      await tx.cashWalletTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: intent.walletId,
          transactionType: 'RECHARGE',
          amount: intent.amount,
          referenceType: 'MANUAL_RECHARGE_APPROVAL',
          referenceId: id,
          remarks: `Manual ${intent.paymentChannel || 'payment'} verified and approved by Pharmacy.`,
        },
      });

      await tx.walletTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: intent.walletId,
          transactionType: 'RECHARGE',
          subLedgerType: 'CASH',
          amount: intent.amount,
          referenceType: 'MANUAL_RECHARGE_APPROVAL',
          referenceId: id,
          remarks: `Manual ${intent.paymentChannel || 'payment'} verified and approved by Pharmacy.`,
        },
      });

      // 10% Extra Bonus Credit Entry
      await tx.benefitLedgerTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: intent.walletId,
          transactionType: 'RECHARGE',
          amount: bonusAmount,
          serviceType: 'PHARMACY',
          referenceType: 'MANUAL_RECHARGE_BONUS',
          referenceId: id,
          remarks: `10% Extra Promotional Bonus Credit for ₹${baseAmount} Wallet Recharge Approval.`,
        },
      });

      // 3. Log audit trail
      await this.timelineService.recordAuditLog({
        action: 'MANUAL_PAYMENT_APPROVED',
        entityType: 'WALLET_RECHARGE_INTENT',
        entityId: id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: {
          amount: Number(intent.amount),
          walletId: intent.walletId.toString(),
          providerId: providerId.toString(),
          approvedAt: now.toISOString(),
        },
      });

      return {
        id: intent.id.toString(),
        uuid: intent.uuid,
        amount: Number(intent.amount),
        status: 'APPROVED',
        reviewedAt: now,
      };
    });
  }

  async rejectPayment(
    id: bigint,
    dto: RejectPaymentDto,
    principal?: ShieldPrincipal,
  ) {
    const providerId = await this.getPharmacyProviderId(principal);
    if (!dto.rejectionReason?.trim()) {
      throw new BadRequestException('Rejection reason is required.');
    }

    return this.prisma.$transaction(async (tx) => {
      const now = new Date();

      // Atomic Concurrency Claim: Only one request can transition status PENDING -> REJECTED
      const updateResult = await tx.walletRechargeIntent.updateMany({
        where: { id, providerId, status: 'PENDING' },
        data: {
          status: 'REJECTED',
          rejectionReason: dto.rejectionReason.trim(),
          reviewedBy: principal?.userId ? BigInt(principal.userId) : undefined,
          reviewedAt: now,
          failedAt: now,
          updatedAt: now,
        },
      });

      if (updateResult.count === 0) {
        const existing = await tx.walletRechargeIntent.findFirst({
          where: { id, providerId },
        });
        if (!existing) {
          throw new NotFoundException(
            'Payment request not found or access denied for this pharmacy.',
          );
        }
        throw new BadRequestException(
          `Payment request cannot be rejected because current status is ${existing.status}.`,
        );
      }

      const intent = await tx.walletRechargeIntent.findFirst({
        where: { id },
      });

      // Audit log
      await this.timelineService.recordAuditLog({
        action: 'MANUAL_PAYMENT_REJECTED',
        entityType: 'WALLET_RECHARGE_INTENT',
        entityId: id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: {
          amount: Number(intent?.amount || 0),
          rejectionReason: dto.rejectionReason.trim(),
          providerId: providerId.toString(),
          rejectedAt: now.toISOString(),
        },
      });

      return {
        id: id.toString(),
        uuid: intent?.uuid || '',
        amount: Number(intent?.amount || 0),
        status: 'REJECTED',
        rejectionReason: dto.rejectionReason.trim(),
        reviewedAt: now,
      };
    });
  }

  private hasActiveRechargeEligibility(customer: {
    shieldCard?: { status?: string | null } | null;
    membership?: { status?: string | null; expiryDate?: Date | null } | null;
  }) {
    const membership = customer.membership;
    const card = customer.shieldCard;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const hasActiveMembership =
      membership?.status?.toUpperCase() === 'ACTIVE' &&
      (!membership.expiryDate || membership.expiryDate >= today);
    const hasIssuedCard = ['ISSUED', 'ACTIVE'].includes(
      card?.status?.toUpperCase() ?? '',
    );

    return hasActiveMembership && hasIssuedCard;
  }
}
