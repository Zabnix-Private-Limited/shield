import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import { ReferralService } from '../referral/referral.service';
import { PricingService } from '../pricing/pricing.service';
import { WalletService } from '../wallet/wallet.service';
import { WALLET_LEDGER_TYPES } from '../pricing/pricing.types';

@Injectable()
export class CustomerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly referralService: ReferralService,
    private readonly pricingService: PricingService,
    private readonly walletService: WalletService,
  ) {}

  async create(data: any, staffUserId?: bigint) {
    const result = await this.createCustomerAggregate(data, staffUserId);
    const preloadConfig = await this.pricingService.getPreloadConfig();

    if (preloadConfig.cashPreloadEnabled && preloadConfig.cashPreloadAmount > 0) {
      await this.walletService.createLedgerEntry({
        walletId: result.walletId,
        transactionType: 'OPENING_BALANCE',
        subLedgerType: WALLET_LEDGER_TYPES.CASH,
        amount: preloadConfig.cashPreloadAmount,
        remarks: 'Admin-configured cash wallet preload',
        createdBy: staffUserId,
        metadata: {
          preloadType: 'CASH',
          source: 'COMMERCIAL_SETTING',
        },
      });
    }

    if (preloadConfig.benefitPreloadEnabled && preloadConfig.benefitPreloadAmount > 0) {
      await this.walletService.createLedgerEntry({
        walletId: result.walletId,
        transactionType: 'PRELOAD',
        subLedgerType: WALLET_LEDGER_TYPES.SHIELD_BENEFIT,
        amount: preloadConfig.benefitPreloadAmount,
        remarks: 'Admin-configured hidden SHIELD benefit preload',
        createdBy: staffUserId,
        metadata: {
          preloadType: 'BENEFIT',
          source: 'COMMERCIAL_SETTING',
        },
      });
    }

    return result.customer;
  }

  async findOne(id: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id },
      include: {
        membership: { include: { membershipType: true } },
        shieldCard: true,
        wallet: true,
        creditAccount: true,
      },
    });
    if (!customer) {
      throw new NotFoundException(`Customer with ID ${id} not found`);
    }
    return customer;
  }

  async update(id: bigint, data: any) {
    const customer = await this.findOne(id);
    return this.prisma.customer.update({
      where: { id: customer.id },
      data: {
        firstName: data.first_name,
        lastName: data.last_name,
        dob: data.dob ? new Date(data.dob) : undefined,
        gender: data.gender,
        email: data.email,
        addressLine1: data.address_line1 || data.address,
        addressLine2: data.address_line2,
        city: data.city,
        district: data.district,
        state: data.state,
        pincode: data.pincode,
        bloodGroup: data.blood_group,
      },
    });
  }

  async search(query: {
    mobile?: string;
    name?: string;
    aadhaar?: string;
    membership?: string;
  }) {
    const whereClause: any = {};

    if (query.mobile) {
      whereClause.mobile = { contains: query.mobile };
    }
    if (query.aadhaar) {
      whereClause.aadhaarNumber = { contains: query.aadhaar };
    }
    if (query.name) {
      whereClause.OR = [
        { firstName: { contains: query.name, mode: 'insensitive' } },
        { lastName: { contains: query.name, mode: 'insensitive' } },
      ];
    }
    if (query.membership) {
      whereClause.membership = {
        membershipNumber: { contains: query.membership, mode: 'insensitive' },
      };
    }

    return this.prisma.customer.findMany({
      where: whereClause,
      include: {
        membership: true,
        wallet: true,
      },
    });
  }

  async approve(id: bigint, staffUserId: bigint) {
    const customer = await this.findOne(id);

    const approvedCustomer = await this.prisma.$transaction(async (tx) => {
      const staffUser = await tx.user.findUnique({
        where: { id: staffUserId },
        include: { department: true },
      });
      let issuedBusinessId = staffUser?.department?.businessId || null;
      if (!issuedBusinessId) {
        const defaultBiz = await tx.business.findFirst({
          where: { code: 'HYP-PERINTHALMANNA' },
        });
        if (defaultBiz) {
          issuedBusinessId = defaultBiz.id;
        }
      }

      await tx.shieldCard.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          cardNumber: `SHLD-CARD-${customer.customerCode?.split('-')[1]}`,
          qrCode: `SHLD-CARD-${customer.customerCode?.split('-')[1]}-TOKEN`,
          status: 'ACTIVE',
          issuedBusinessId,
          issuedAt: new Date(),
        },
      });

      if (customer.membership) {
        await tx.membership.update({
          where: { id: customer.membership.id },
          data: {
            status: 'ACTIVE',
            activationDate: new Date(),
            expiryDate: new Date(
              new Date().setFullYear(new Date().getFullYear() + 1),
            ),
          },
        });
      }

      await tx.customerStatusHistory.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          oldStatus: customer.status,
          newStatus: 'ACTIVE',
          changedBy: staffUserId,
          remarks: 'Onboarding approved by staff user',
        },
      });

      return tx.customer.update({
        where: { id: customer.id },
        data: {
          status: 'ACTIVE',
          approvedBy: staffUserId,
        },
      });
    });

    await this.referralService.markReferralVerified(approvedCustomer.id);
    return approvedCustomer;
  }

  async suspend(id: bigint, staffUserId: bigint) {
    const customer = await this.findOne(id);

    const suspendedCustomer = await this.prisma.$transaction(async (tx) => {
      if (customer.membership) {
        await tx.membership.update({
          where: { id: customer.membership.id },
          data: { status: 'SUSPENDED' },
        });
      }

      if (customer.shieldCard) {
        await tx.shieldCard.update({
          where: { id: customer.shieldCard.id },
          data: { status: 'SUSPENDED' },
        });
      }

      await tx.customerStatusHistory.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          oldStatus: customer.status,
          newStatus: 'SUSPENDED',
          changedBy: staffUserId,
          remarks: 'Customer suspended by staff',
        },
      });

      return tx.customer.update({
        where: { id: customer.id },
        data: { status: 'SUSPENDED' },
      });
    });

    await this.referralService.rejectReferral({
      referredCustomerId: customer.id,
      reason: 'Customer onboarding or membership became inactive before qualification.',
    });

    return suspendedCustomer;
  }

  private async createCustomerAggregate(data: any, staffUserId?: bigint) {
    const customerUuid = randomUUID();
    const customerCode = `CUST-${Math.floor(100000 + Math.random() * 900000)}`;

    return this.prisma.$transaction(async (tx) => {
      let referredById: bigint | null = null;
      if (data.referred_by_code) {
        const referrer = await tx.customer.findFirst({
          where: { referralCode: data.referred_by_code },
        });
        if (referrer && referrer.mobile !== data.mobile) {
          referredById = referrer.id;
        }
      }

      const customer = await tx.customer.create({
        data: {
          uuid: customerUuid,
          customerCode,
          aadhaarNumber: data.aadhaar_number,
          firstName: data.first_name,
          lastName: data.last_name,
          dob: data.dob ? new Date(data.dob) : null,
          gender: data.gender,
          mobile: data.mobile,
          email: data.email || null,
          addressLine1: data.address_line1 || data.address,
          addressLine2: data.address_line2,
          city: data.city,
          district: data.district,
          state: data.state,
          pincode: data.pincode,
          status: 'PENDING',
          createdBy: staffUserId,
          bloodGroup: data.blood_group || null,
          agentCode: data.agent_code || 'AGT-SAHAKAR-DEFAULT',
          referralCode:
            data.referral_code ||
            `REF-${Math.floor(100000 + Math.random() * 900000)}`,
          referredById,
        },
      });

      const stdType = await tx.membershipType.findFirst({
        where: { code: 'STANDARD' },
      });

      if (stdType) {
        await tx.membership.create({
          data: {
            uuid: randomUUID(),
            customerId: customer.id,
            membershipTypeId: stdType.id,
            membershipNumber: `SHLD-${new Date().getFullYear()}-${customerCode.split('-')[1]}`,
            joiningFee: stdType.joiningFee,
            status: 'INACTIVE',
          },
        });
      }

      const wallet = await tx.wallet.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          status: 'ACTIVE',
        },
      });

      await tx.creditAccount.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          creditLimit: 3000.0,
          availableCredit: 3000.0,
          outstandingAmount: 0.0,
          status: 'ACTIVE',
        },
      });

      if (referredById) {
        await tx.referralRewardEvent.upsert({
          where: { referredCustomerId: customer.id },
          update: {
            referrerCustomerId: referredById,
            referralCode: data.referred_by_code,
            status: 'PENDING',
            rewardPoints: 0,
          },
          create: {
            uuid: randomUUID(),
            referrerCustomerId: referredById,
            referredCustomerId: customer.id,
            referralCode: data.referred_by_code,
            status: 'PENDING',
            rewardPoints: 0,
          },
        });
      }

      return { customer, walletId: wallet.id };
    });
  }
}
