import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class CustomerService {
  constructor(private prisma: PrismaService) {}

  async create(data: any, staffUserId?: bigint) {
    const customerUuid = randomUUID();
    const customerCode = `CUST-${Math.floor(100000 + Math.random() * 900000)}`;

    return this.prisma.$transaction(async (tx) => {
      // Look up referring customer if referred_by_code is provided
      let referredById: bigint | null = null;
      if (data.referred_by_code) {
        const referrer = await tx.customer.findFirst({
          where: { referralCode: data.referred_by_code },
        });
        if (referrer) {
          referredById = referrer.id;
        }
      }

      // 1. Create Customer
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
          email: data.email || 'Zabnixprivatelimited@gmail.com',
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
          referralCode: data.referral_code || `REF-${Math.floor(100000 + Math.random() * 900000)}`,
          referredById: referredById,
        },
      });

      // 2. Fetch standard membership type
      const stdType = await tx.membershipType.findFirst({
        where: { code: 'STANDARD' },
      });

      // 3. Create Membership
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

      // 4. Create Wallet
      await tx.wallet.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          status: 'ACTIVE',
        },
      });

      // 5. Create Credit Account
      await tx.creditAccount.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          creditLimit: 3000.00,
          availableCredit: 3000.00,
          outstandingAmount: 0.00,
          status: 'ACTIVE',
        },
      });

      return customer;
    });
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

  async search(query: { mobile?: string; name?: string; aadhaar?: string; membership?: string }) {
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

    return this.prisma.$transaction(async (tx) => {
      // Lookup the staff user's department's business or fall back to Perinthalmanna branch
      const staffUser = await tx.user.findUnique({
        where: { id: staffUserId },
        include: { department: true }
      });
      let issuedBusinessId = staffUser?.department?.businessId || null;
      if (!issuedBusinessId) {
        const defaultBiz = await tx.business.findFirst({
          where: { code: 'HYP-PERINTHALMANNA' }
        });
        if (defaultBiz) {
          issuedBusinessId = defaultBiz.id;
        }
      }

      // Create shield card on approval
      await tx.shieldCard.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          cardNumber: `SHLD-CARD-${customer.customerCode?.split('-')[1]}`,
          qrCode: `SHLD-CARD-${customer.customerCode?.split('-')[1]}-TOKEN`,
          status: 'ACTIVE',
          issuedBusinessId: issuedBusinessId,
          issuedAt: new Date(),
        },
      });

      // Update membership status to ACTIVE
      if (customer.membership) {
        await tx.membership.update({
          where: { id: customer.membership.id },
          data: {
            status: 'ACTIVE',
            activationDate: new Date(),
            expiryDate: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
          },
        });
      }

      // Credit referral points if customer was referred by someone
      if (customer.referredById) {
        const referrerWallet = await tx.wallet.findFirst({
          where: { customerId: customer.referredById }
        });
        if (referrerWallet) {
          await tx.walletTransaction.create({
            data: {
              uuid: randomUUID(),
              walletId: referrerWallet.id,
              transactionType: 'CREDIT',
              subLedgerType: 'POINTS',
              amount: 100.00,
              remarks: `Referral bonus for onboarding ${customer.firstName} ${customer.lastName}`,
              createdBy: staffUserId,
            }
          });
        }
      }

      // Create status history log
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
  }

  async suspend(id: bigint, staffUserId: bigint) {
    const customer = await this.findOne(id);

    return this.prisma.$transaction(async (tx) => {
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
  }
}
