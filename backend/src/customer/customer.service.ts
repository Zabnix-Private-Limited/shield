import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import { ReferralService } from '../referral/referral.service';
import { PricingService } from '../pricing/pricing.service';
import { WalletService } from '../wallet/wallet.service';
import { WALLET_LEDGER_TYPES } from '../pricing/pricing.types';

@Injectable()
export class CustomerService {
  private readonly logger = new Logger(CustomerService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly referralService: ReferralService,
    private readonly pricingService: PricingService,
    private readonly walletService: WalletService,
  ) {}

  private async recordCustomerAccountAudit(
    action: string,
    entityType: string,
    entityId: bigint | null,
    customerId: bigint,
  ) {
    await this.prisma.auditLog.create({
      data: {
        action,
        entityType,
        entityId,
        newData: { customerId: customerId.toString() },
      },
    });
  }

  private membershipApplicationView(application: any) {
    if (!application) return null;
    return {
      id: application.id.toString(),
      uuid: application.uuid,
      reference: application.reference,
      status: application.status,
      submittedAt: application.submittedAt,
      reviewedAt: application.reviewedAt,
      reason: application.reviewReason,
    };
  }

  async getCustomerMembershipApplication(customerId: bigint) {
    const application = await this.prisma.membershipApplication.findFirst({
      where: { customerId },
      orderBy: [{ submittedAt: 'desc' }, { id: 'desc' }],
    });
    return this.membershipApplicationView(application);
  }

  async getMembershipApplicationCustomerId(applicationId: bigint) {
    const application = await this.prisma.membershipApplication.findUnique({
      where: { id: applicationId },
      select: { customerId: true },
    });
    if (!application) {
      throw new NotFoundException('Membership application not found.');
    }
    return application.customerId;
  }

  async submitMembershipApplication(customerId: bigint) {
    return this.prisma.$transaction(async (tx) => {
      const customer = await tx.customer.findFirst({
        where: { id: customerId, deletedAt: null },
        include: { membership: true },
      });
      if (!customer) {
        throw new NotFoundException(`Customer with ID ${customerId} not found`);
      }
      if (customer.membership?.status?.trim().toUpperCase() === 'ACTIVE') {
        throw new ConflictException(
          'An active membership already exists for this customer.',
        );
      }
      const activeApplication = await tx.membershipApplication.findFirst({
        where: { customerId, status: { in: ['PENDING', 'APPROVED'] } },
        orderBy: [{ submittedAt: 'desc' }, { id: 'desc' }],
      });
      if (activeApplication) {
        throw new ConflictException(
          'A membership application is already being processed.',
        );
      }
      const application = await tx.membershipApplication.create({
        data: {
          uuid: randomUUID(),
          customerId,
          reference: `MAP-${new Date().getFullYear()}-${randomUUID().replace(/-/g, '').slice(0, 10).toUpperCase()}`,
          status: 'PENDING',
        },
      });
      await tx.activityEvent.create({
        data: {
          uuid: randomUUID(),
          customerId,
          activityType: 'MEMBERSHIP_APPLICATION_SUBMITTED',
          relatedEntityType: 'membership_application',
          relatedEntityId: application.id,
          status: 'PENDING',
          description: 'Customer submitted a membership application.',
        },
      });
      return this.membershipApplicationView(application);
    });
  }

  async reviewMembershipApplication(
    applicationId: bigint,
    staffUserId: bigint,
    requestedStatus?: string,
    reason?: string,
  ) {
    const status = requestedStatus?.trim().toUpperCase();
    if (status !== 'APPROVED' && status !== 'REJECTED') {
      throw new BadRequestException(
        'Review status must be APPROVED or REJECTED.',
      );
    }
    if (status === 'REJECTED' && !reason?.trim()) {
      throw new BadRequestException(
        'A customer-visible rejection reason is required.',
      );
    }
    return this.prisma.$transaction(async (tx) => {
      const application = await tx.membershipApplication.findUnique({
        where: { id: applicationId },
      });
      if (!application)
        throw new NotFoundException('Membership application not found.');
      if (application.status !== 'PENDING') {
        throw new ConflictException(
          'Only pending membership applications can be reviewed.',
        );
      }
      const reviewed = await tx.membershipApplication.update({
        where: { id: applicationId },
        data: {
          status,
          reviewReason: reason?.trim() || null,
          reviewedAt: new Date(),
          reviewedBy: staffUserId,
        },
      });
      await tx.activityEvent.create({
        data: {
          uuid: randomUUID(),
          customerId: application.customerId,
          activityType: `MEMBERSHIP_APPLICATION_${status}`,
          relatedEntityType: 'membership_application',
          relatedEntityId: applicationId,
          agentUserId: staffUserId,
          createdBy: staffUserId,
          status,
          description: `Membership application ${status.toLowerCase()} by staff.`,
        },
      });
      return this.membershipApplicationView(reviewed);
    });
  }

  async create(data: any, staffUserId?: bigint) {
    const result = await this.createCustomerAggregate(data, staffUserId);
    const preloadConfig = await this.getSafePreloadConfig();

    if (
      preloadConfig.cashPreloadEnabled &&
      preloadConfig.cashPreloadAmount > 0
    ) {
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

    if (
      preloadConfig.benefitPreloadEnabled &&
      preloadConfig.benefitPreloadAmount > 0
    ) {
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

  private async getSafePreloadConfig() {
    try {
      return await this.pricingService.getPreloadConfig();
    } catch (error) {
      this.logger.warn(
        `Customer registration preload lookup failed; continuing without preload entries: ${error}`,
      );
      return {
        cashPreloadEnabled: false,
        cashPreloadAmount: 0,
        benefitPreloadEnabled: false,
        benefitPreloadAmount: 0,
      };
    }
  }

  async findOne(id: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id },
      include: {
        membership: { include: { membershipType: true } },
        shieldCard: true,
        wallet: true,
        membershipApplications: {
          orderBy: [{ submittedAt: 'desc' }, { id: 'desc' }],
          take: 1,
        },
        creditAccount: true,
      },
    });
    if (!customer) {
      throw new NotFoundException(`Customer with ID ${id} not found`);
    }
    return customer;
  }

  async getCustomerPortalMembership(customerId: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      include: {
        membership: {
          include: {
            membershipType: true,
          },
        },
        shieldCard: {
          include: {
            issuedBusiness: true,
          },
        },
        wallet: true,
        membershipApplications: {
          orderBy: [{ submittedAt: 'desc' }, { id: 'desc' }],
          take: 1,
        },
      },
    });

    if (!customer) {
      throw new NotFoundException(`Customer with ID ${customerId} not found`);
    }

    const walletSummary = customer.wallet
      ? await this.walletService.getWalletSummary(customer.wallet.id)
      : null;
    const subscription = await this.prisma.membershipSubscription.findUnique({
      where: { customerId },
    });
    const currentAllocation = subscription
      ? await this.prisma.subscriptionMonthlyAllocation.findFirst({
          where: {
            subscriptionId: subscription.id,
            monthStart: {
              lte: new Date(
                new Date().getFullYear(),
                new Date().getMonth() + 1,
                0,
              ),
            },
          },
          orderBy: { monthStart: 'desc' },
        })
      : null;

    return {
      customerId: customer.id.toString(),
      membershipApplication: this.membershipApplicationView(
        customer.membershipApplications[0],
      ),
      membership: customer.membership
        ? {
            id: customer.membership.id.toString(),
            uuid: customer.membership.uuid,
            membershipNumber: customer.membership.membershipNumber,
            status: customer.membership.status,
            activationDate: customer.membership.activationDate,
            expiryDate: customer.membership.expiryDate,
            createdAt: customer.membership.createdAt,
            updatedAt: customer.membership.updatedAt,
            membershipType: customer.membership.membershipType
              ? {
                  id: customer.membership.membershipType.id.toString(),
                  uuid: customer.membership.membershipType.uuid,
                  code: customer.membership.membershipType.code,
                  name: customer.membership.membershipType.name,
                  joiningFee: customer.membership.membershipType.joiningFee,
                  discountPercentage:
                    customer.membership.membershipType.discountPercentage,
                  creditEligible:
                    customer.membership.membershipType.creditEligible,
                  status: customer.membership.membershipType.status,
                }
              : null,
          }
        : null,
      membershipStats: {
        totalEarnedCredits: walletSummary?.cashWallet.credited ?? 0,
        totalRedeemedCredits: walletSummary?.cashWallet.debited ?? 0,
        availableCredits: walletSummary?.cashWallet.available ?? 0,
      },
      subscription: subscription
        ? {
            planName: subscription.planName,
            status: subscription.status,
            startsOn: subscription.startsOn,
            endsOn: subscription.endsOn,
            customerContributionPaise: subscription.customerContributionPaise,
            shieldBenefitPaise: subscription.shieldBenefitPaise,
            totalEntitlementPaise: subscription.totalEntitlementPaise,
            currentAllocation: currentAllocation
              ? {
                  monthStart: currentAllocation.monthStart,
                  allocationPaise: currentAllocation.allocationPaise,
                  carryForwardPaise: currentAllocation.carryForwardPaise,
                  usedPaise: currentAllocation.usedPaise,
                  remainingPaise:
                    currentAllocation.allocationPaise +
                    currentAllocation.carryForwardPaise -
                    currentAllocation.usedPaise,
                }
              : null,
          }
        : null,
      shieldCard: customer.shieldCard
        ? {
            id: customer.shieldCard.id.toString(),
            uuid: customer.shieldCard.uuid,
            cardNumber: customer.shieldCard.cardNumber,
            qrCode: customer.shieldCard.qrCode,
            status: customer.shieldCard.status,
            issuedAt: customer.shieldCard.issuedAt,
            issuedBusiness: customer.shieldCard.issuedBusiness
              ? {
                  id: customer.shieldCard.issuedBusiness.id.toString(),
                  uuid: customer.shieldCard.issuedBusiness.uuid,
                  code: customer.shieldCard.issuedBusiness.code,
                  name: customer.shieldCard.issuedBusiness.name,
                  status: customer.shieldCard.issuedBusiness.status,
                }
              : null,
          }
        : null,
    };
  }

  async update(id: bigint, data: any) {
    const customer = await this.findOne(id);
    return this.prisma.customer.update({
      where: { id: customer.id },
      data: {
        aadhaarNumber: data.aadhaar_number,
        firstName: data.first_name,
        lastName: data.last_name,
        dob: data.dob ? new Date(data.dob) : undefined,
        gender: data.gender,
        mobile: data.mobile,
        email: data.email,
        addressLine1: data.address_line1 || data.address,
        addressLine2: data.address_line2,
        city: data.city,
        district: data.district,
        state: data.state,
        pincode: data.pincode,
        bloodGroup: data.blood_group,
        status: data.status,
      },
    });
  }

  async getCustomerSelfProfile(customerId: bigint) {
    const customer = await this.prisma.customer.findFirst({
      where: { id: customerId, deletedAt: null },
      select: {
        id: true,
        uuid: true,
        customerCode: true,
        firstName: true,
        lastName: true,
        dob: true,
        gender: true,
        mobile: true,
        email: true,
        addressLine1: true,
        addressLine2: true,
        city: true,
        district: true,
        state: true,
        pincode: true,
        bloodGroup: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    if (!customer) throw new NotFoundException('Customer not found.');
    return customer;
  }

  async updateCustomerSelfProfile(
    customerId: bigint,
    data: {
      firstName?: string;
      lastName?: string;
      dob?: string | null;
      gender?: string | null;
      email?: string | null;
      addressLine1?: string | null;
      addressLine2?: string | null;
      city?: string | null;
      district?: string | null;
      state?: string | null;
      pincode?: string | null;
      bloodGroup?: string | null;
    },
  ) {
    const cleanOptional = (value: string | null | undefined) =>
      value == null ? null : value.trim() || null;
    const firstName = cleanOptional(data.firstName);
    const lastName = cleanOptional(data.lastName);
    if (!firstName || !lastName) {
      throw new BadRequestException('First and last name are required.');
    }
    const email = cleanOptional(data.email);
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new BadRequestException('Email address is invalid.');
    }
    const dob = data.dob ? new Date(data.dob) : null;
    if (dob && (Number.isNaN(dob.getTime()) || dob > new Date())) {
      throw new BadRequestException('Date of birth must be a valid past date.');
    }
    const customer = await this.prisma.customer.update({
      where: { id: customerId },
      data: {
        firstName,
        lastName,
        dob,
        gender: cleanOptional(data.gender),
        email,
        addressLine1: cleanOptional(data.addressLine1),
        addressLine2: cleanOptional(data.addressLine2),
        city: cleanOptional(data.city),
        district: cleanOptional(data.district),
        state: cleanOptional(data.state),
        pincode: cleanOptional(data.pincode),
        bloodGroup: cleanOptional(data.bloodGroup),
      },
    });
    await this.recordCustomerAccountAudit(
      'CUSTOMER_SELF_PROFILE_UPDATED',
      'CUSTOMER_PROFILE',
      customer.id,
      customerId,
    );
    return this.getCustomerSelfProfile(customerId);
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

  async findExistingCustomerByMobile(mobile: string) {
    const normalized = mobile.replace(/\D/g, '').slice(-10);
    const customer = await this.prisma.customer.findFirst({
      where: { mobile: { endsWith: normalized }, deletedAt: null },
      include: {
        membership: true,
        shieldCard: true,
        customerContacts: { where: { isPrimary: false } },
      },
    });
    if (!customer) return null;
    const imported = await this.prisma.customerImportRow.findFirst({
      where: { matchedCustomerId: customer.id },
      orderBy: { createdAt: 'desc' },
    });
    const batch = imported
      ? await this.prisma.customerImportBatch.findUnique({
          where: { id: imported.batchId },
        })
      : null;
    const existingBusiness = batch
      ? await this.prisma.business.findUnique({
          where: { id: batch.businessId },
          select: { id: true, name: true, code: true },
        })
      : null;
    return { ...customer, existingBusiness };
  }

  async convertExistingCustomerToMembership(
    customerId: bigint,
    data: { membershipTypeCode?: string; agentCode?: string },
    staffUserId?: bigint,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const customer = await tx.customer.findFirst({
        where: { id: customerId, deletedAt: null },
        include: { membership: true, wallet: true, creditAccount: true },
      });
      if (!customer) {
        throw new NotFoundException(`Customer with ID ${customerId} not found`);
      }
      if (customer.membership) {
        throw new ConflictException(
          'Membership already exists for this customer.',
        );
      }

      const membershipType = await tx.membershipType.findFirst({
        where: data.membershipTypeCode
          ? { code: data.membershipTypeCode.trim().toUpperCase() }
          : { code: 'STANDARD' },
      });
      if (!membershipType) {
        throw new BadRequestException('A valid membership plan is required.');
      }

      const membership = await tx.membership.create({
        data: {
          uuid: randomUUID(),
          customerId,
          membershipTypeId: membershipType.id,
          membershipNumber: `SHLD-${new Date().getFullYear()}-${customer.customerCode?.split('-')[1] ?? customerId}`,
          joiningFee: membershipType.joiningFee,
          status: 'INACTIVE',
        },
      });
      const wallet =
        customer.wallet ??
        (await tx.wallet.create({
          data: { uuid: randomUUID(), customerId, status: 'ACTIVE' },
        }));
      if (!customer.creditAccount) {
        await tx.creditAccount.create({
          data: {
            uuid: randomUUID(),
            customerId,
            creditLimit: 3000.0,
            availableCredit: 3000.0,
            outstandingAmount: 0.0,
            status: 'ACTIVE',
          },
        });
      }
      const converted = await tx.customer.update({
        where: { id: customerId },
        data: {
          onboardingSource: 'EXISTING_CUSTOMER_CONVERSION',
          ...(data.agentCode ? { agentCode: data.agentCode } : {}),
          ...(staffUserId ? { createdBy: staffUserId } : {}),
        },
      });
      await tx.activityEvent.create({
        data: {
          uuid: randomUUID(),
          customerId,
          activityType: 'MEMBERSHIP_CREATED',
          relatedEntityType: 'membership',
          relatedEntityId: membership.id,
          agentUserId: staffUserId,
          status: 'RECORDED',
          description: 'Existing customer converted to a SHIELD member.',
          createdBy: staffUserId,
        },
      });
      return { customer: converted, membership, walletId: wallet.id };
    });
  }

  async saveAlternativeContact(
    customerId: bigint,
    data: {
      mobile: string;
      name?: string;
      relationship?: string;
      contactType?: 'ALTERNATIVE' | 'EMERGENCY';
    },
  ) {
    const customer = await this.findOne(customerId);
    const normalized = data.mobile.replace(/\D/g, '').slice(-10);
    const primary = customer.mobile.replace(/\D/g, '').slice(-10);
    if (normalized.length !== 10 || normalized === primary) {
      throw new BadRequestException(
        'Alternative mobile number must differ from the primary login number.',
      );
    }
    const existing = (
      await this.prisma.customerContact.findMany({
        where: { customerId, deletedAt: null },
        select: { id: true, mobile: true },
      })
    ).find(
      (contact) =>
        (contact.mobile ?? '').replace(/\D/g, '').slice(-10) === normalized,
    );
    const values = {
      name: data.name?.trim() || null,
      relation: data.relationship?.trim() || null,
      isPrimary: false,
      contactType: data.contactType ?? 'ALTERNATIVE',
    };
    return existing
      ? this.prisma.customerContact.update({
          where: { id: existing.id },
          data: values,
        })
      : this.prisma.customerContact.create({
          data: { customerId, mobile: normalized, ...values },
        });
  }

  async listAlternativeContacts(customerId: bigint) {
    return this.prisma.customerContact.findMany({
      where: {
        customerId,
        isPrimary: false,
        contactType: 'ALTERNATIVE',
        deletedAt: null,
      },
      select: {
        id: true,
        name: true,
        mobile: true,
        relation: true,
      },
      orderBy: { id: 'desc' },
    });
  }

  async removeAlternativeContact(customerId: bigint, contactId: bigint) {
    const result = await this.prisma.customerContact.deleteMany({
      where: {
        id: contactId,
        customerId,
        isPrimary: false,
        contactType: 'ALTERNATIVE',
        deletedAt: null,
      },
    });
    if (result.count === 0) {
      throw new NotFoundException('Alternative contact not found.');
    }
  }

  async listContacts(customerId: bigint) {
    return this.prisma.customerContact.findMany({
      where: { customerId, isPrimary: false, deletedAt: null },
      select: {
        id: true,
        name: true,
        mobile: true,
        relation: true,
        contactType: true,
      },
      orderBy: { id: 'desc' },
    });
  }

  async getContact(customerId: bigint, id: bigint) {
    const contact = await this.prisma.customerContact.findFirst({
      where: { id, customerId, isPrimary: false, deletedAt: null },
    });
    if (!contact) throw new NotFoundException('Contact not found.');
    return contact;
  }

  async saveContact(
    customerId: bigint,
    data: {
      id?: bigint;
      mobile?: string;
      name?: string;
      relationship?: string;
      contactType?: string;
    },
  ) {
    const contactType = data.contactType?.trim().toUpperCase();
    if (contactType !== 'ALTERNATIVE' && contactType !== 'EMERGENCY') {
      throw new BadRequestException(
        'Contact type must be ALTERNATIVE or EMERGENCY.',
      );
    }
    if (!data.mobile)
      throw new BadRequestException('Mobile number is required.');
    if (!data.id) {
      const contact = await this.saveAlternativeContact(customerId, {
        mobile: data.mobile,
        name: data.name,
        relationship: data.relationship,
        contactType,
      });
      await this.recordCustomerAccountAudit(
        'CUSTOMER_CONTACT_CREATED',
        'CUSTOMER_CONTACT',
        contact.id,
        customerId,
      );
      return contact;
    }
    const existing = await this.prisma.customerContact.findFirst({
      where: { id: data.id, customerId, isPrimary: false, deletedAt: null },
    });
    if (!existing) throw new NotFoundException('Contact not found.');
    const normalized = data.mobile.replace(/\D/g, '').slice(-10);
    const primary = (await this.findOne(customerId)).mobile
      .replace(/\D/g, '')
      .slice(-10);
    if (normalized.length !== 10 || normalized === primary) {
      throw new BadRequestException(
        'Contact mobile must differ from the primary login number.',
      );
    }
    const contact = await this.prisma.customerContact.update({
      where: { id: data.id },
      data: {
        mobile: normalized,
        name: data.name?.trim() || null,
        relation: data.relationship?.trim() || null,
        contactType,
      },
    });
    await this.recordCustomerAccountAudit(
      'CUSTOMER_CONTACT_UPDATED',
      'CUSTOMER_CONTACT',
      contact.id,
      customerId,
    );
    return contact;
  }

  async removeContact(customerId: bigint, contactId: bigint) {
    const result = await this.prisma.customerContact.updateMany({
      where: { id: contactId, customerId, isPrimary: false, deletedAt: null },
      data: { deletedAt: new Date() },
    });
    if (!result.count) throw new NotFoundException('Contact not found.');
    await this.recordCustomerAccountAudit(
      'CUSTOMER_CONTACT_REMOVED',
      'CUSTOMER_CONTACT',
      contactId,
      customerId,
    );
  }

  async listAddresses(customerId: bigint) {
    return this.prisma.customerAddress.findMany({
      where: { customerId, deletedAt: null },
      orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });
  }

  async getAddress(customerId: bigint, id: bigint) {
    const address = await this.prisma.customerAddress.findFirst({
      where: { id, customerId, deletedAt: null },
    });
    if (!address) throw new NotFoundException('Address not found.');
    return address;
  }

  async saveAddress(
    customerId: bigint,
    data: {
      id?: bigint;
      label?: string;
      addressLine1?: string;
      addressLine2?: string;
      city?: string;
      district?: string;
      state?: string;
      pincode?: string;
      isDefault?: boolean;
    },
  ) {
    const addressLine1 = data.addressLine1?.trim();
    if (!addressLine1)
      throw new BadRequestException('Address line 1 is required.');
    const values = {
      label: data.label?.trim().toUpperCase() || 'HOME',
      addressLine1,
      addressLine2: data.addressLine2?.trim() || null,
      city: data.city?.trim() || null,
      district: data.district?.trim() || null,
      state: data.state?.trim() || null,
      pincode: data.pincode?.replace(/\s/g, '').toUpperCase() || null,
      isDefault: data.isDefault === true,
    };
    const address = await this.prisma.$transaction(async (tx) => {
      if (data.id) {
        const existing = await tx.customerAddress.findFirst({
          where: { id: data.id, customerId, deletedAt: null },
        });
        if (!existing) throw new NotFoundException('Address not found.');
      }
      if (values.isDefault) {
        await tx.customerAddress.updateMany({
          where: { customerId, deletedAt: null },
          data: { isDefault: false },
        });
      }
      return data.id
        ? tx.customerAddress.update({ where: { id: data.id }, data: values })
        : tx.customerAddress.create({
            data: { uuid: randomUUID(), customerId, ...values },
          });
    });
    await this.recordCustomerAccountAudit(
      data.id ? 'CUSTOMER_ADDRESS_UPDATED' : 'CUSTOMER_ADDRESS_CREATED',
      'CUSTOMER_ADDRESS',
      address.id,
      customerId,
    );
    return address;
  }

  async removeAddress(customerId: bigint, addressId: bigint) {
    const result = await this.prisma.customerAddress.updateMany({
      where: { id: addressId, customerId, deletedAt: null },
      data: { deletedAt: new Date(), isDefault: false },
    });
    if (!result.count) throw new NotFoundException('Address not found.');
    await this.recordCustomerAccountAudit(
      'CUSTOMER_ADDRESS_REMOVED',
      'CUSTOMER_ADDRESS',
      addressId,
      customerId,
    );
  }

  async listDependents(customerId: bigint) {
    return this.prisma.customerDependent.findMany({
      where: { customerId, deletedAt: null },
      orderBy: [{ firstName: 'asc' }, { id: 'asc' }],
    });
  }

  async getDependent(customerId: bigint, id: bigint) {
    const dependent = await this.prisma.customerDependent.findFirst({
      where: { id, customerId, deletedAt: null },
    });
    if (!dependent) throw new NotFoundException('Family member not found.');
    return dependent;
  }

  async saveDependent(
    customerId: bigint,
    data: {
      id?: bigint;
      firstName?: string;
      lastName?: string;
      relation?: string;
      dob?: string;
      gender?: string;
    },
  ) {
    const firstName = data.firstName?.trim();
    const relation = data.relation?.trim();
    if (!firstName || !relation)
      throw new BadRequestException('Name and relationship are required.');
    const dob = data.dob ? new Date(data.dob) : null;
    if (dob && Number.isNaN(dob.getTime()))
      throw new BadRequestException('Date of birth is invalid.');
    const values = {
      firstName,
      lastName: data.lastName?.trim() || null,
      relation,
      dob,
      gender: data.gender?.trim().toUpperCase() || null,
    };
    if (data.id) {
      const existing = await this.prisma.customerDependent.findFirst({
        where: { id: data.id, customerId, deletedAt: null },
      });
      if (!existing) throw new NotFoundException('Family member not found.');
      const dependent = await this.prisma.customerDependent.update({
        where: { id: data.id },
        data: values,
      });
      await this.recordCustomerAccountAudit(
        'CUSTOMER_DEPENDENT_UPDATED',
        'CUSTOMER_DEPENDENT',
        dependent.id,
        customerId,
      );
      return dependent;
    }
    const dependent = await this.prisma.customerDependent.create({
      data: { uuid: randomUUID(), customerId, ...values },
    });
    await this.recordCustomerAccountAudit(
      'CUSTOMER_DEPENDENT_CREATED',
      'CUSTOMER_DEPENDENT',
      dependent.id,
      customerId,
    );
    return dependent;
  }

  async removeDependent(customerId: bigint, dependentId: bigint) {
    const result = await this.prisma.customerDependent.updateMany({
      where: { id: dependentId, customerId, deletedAt: null },
      data: { deletedAt: new Date() },
    });
    if (!result.count) throw new NotFoundException('Family member not found.');
    await this.recordCustomerAccountAudit(
      'CUSTOMER_DEPENDENT_REMOVED',
      'CUSTOMER_DEPENDENT',
      dependentId,
      customerId,
    );
  }

  async getPreferences(customerId: bigint) {
    return this.prisma.customerPreference.findUnique({ where: { customerId } });
  }

  async savePreferences(
    customerId: bigint,
    data: {
      notificationPreferences?: unknown;
      language?: string;
      theme?: string;
    },
  ) {
    const preference = await this.prisma.customerPreference.upsert({
      where: { customerId },
      create: {
        uuid: randomUUID(),
        customerId,
        notificationPreferences: data.notificationPreferences as any,
        language: data.language?.trim() || null,
        theme: data.theme?.trim() || null,
      },
      update: {
        notificationPreferences: data.notificationPreferences as any,
        language: data.language?.trim() || null,
        theme: data.theme?.trim() || null,
      },
    });
    await this.recordCustomerAccountAudit(
      'CUSTOMER_PREFERENCES_UPDATED',
      'CUSTOMER_PREFERENCE',
      preference.id,
      customerId,
    );
    return preference;
  }

  async getPreferredProvider(customerId: bigint) {
    const preference = await this.getPreferences(customerId);
    if (!preference?.preferredProviderId) return null;
    const provider = await this.prisma.serviceProvider.findUnique({
      where: { id: preference.preferredProviderId },
      include: { business: true },
    });
    return provider?.status === 'ACTIVE' ? provider : null;
  }

  async setPreferredProvider(customerId: bigint, providerId: bigint | null) {
    if (providerId) {
      const provider = await this.prisma.serviceProvider.findFirst({
        where: { id: providerId, status: 'ACTIVE', providerType: 'PHARMACY' },
      });
      if (!provider)
        throw new BadRequestException('Select an active pharmacy provider.');
    }
    const preference = await this.prisma.customerPreference.upsert({
      where: { customerId },
      create: {
        uuid: randomUUID(),
        customerId,
        preferredProviderId: providerId,
      },
      update: { preferredProviderId: providerId },
    });
    await this.recordCustomerAccountAudit(
      'CUSTOMER_PREFERRED_PROVIDER_UPDATED',
      'CUSTOMER_PREFERENCE',
      preference.id,
      customerId,
    );
    return preference;
  }

  async listEligiblePharmacies() {
    return this.prisma.serviceProvider.findMany({
      where: { status: 'ACTIVE', providerType: 'PHARMACY' },
      include: { business: true },
      orderBy: { providerName: 'asc' },
    });
  }

  private storeChangeRequestView(request: any) {
    return {
      id: request.id.toString(),
      uuid: request.uuid,
      status: request.status,
      reason: request.reason,
      reviewReason: request.reviewReason,
      submittedAt: request.submittedAt,
      reviewedAt: request.reviewedAt,
      previousProvider: request.previousProvider
        ? {
            id: request.previousProvider.id.toString(),
            name: request.previousProvider.providerName,
            type: request.previousProvider.providerType,
          }
        : null,
      requestedProvider: request.requestedProvider
        ? {
            id: request.requestedProvider.id.toString(),
            name: request.requestedProvider.providerName,
            type: request.requestedProvider.providerType,
          }
        : null,
    };
  }

  async listStoreChangeRequests(customerId: bigint) {
    const requests = await this.prisma.storeChangeRequest.findMany({
      where: { customerId },
      include: { previousProvider: true, requestedProvider: true },
      orderBy: [{ submittedAt: 'desc' }, { id: 'desc' }],
    });
    return requests.map((request) => this.storeChangeRequestView(request));
  }

  async listStoreChangeRequestsForStaff(customerIds?: bigint[]) {
    const requests = await this.prisma.storeChangeRequest.findMany({
      where: customerIds === undefined ? {} : { customerId: { in: customerIds } },
      include: { customer: true, previousProvider: true, requestedProvider: true },
      orderBy: [{ submittedAt: 'desc' }, { id: 'desc' }],
    });
    return requests.map((request) => ({
      ...this.storeChangeRequestView(request),
      customer: request.customer
        ? {
            id: request.customer.id.toString(),
            name: `${request.customer.firstName ?? ''} ${request.customer.lastName ?? ''}`.trim(),
            mobile: request.customer.mobile,
          }
        : null,
    }));
  }

  async submitStoreChangeRequest(
    customerId: bigint,
    requestedProviderId: bigint,
    reason: string,
  ) {
    const normalizedReason = reason.trim();
    if (!normalizedReason) {
      throw new BadRequestException('A store change reason is required.');
    }
    return this.prisma.$transaction(async (tx) => {
      const provider = await tx.serviceProvider.findFirst({
        where: {
          id: requestedProviderId,
          status: 'ACTIVE',
          providerType: 'PHARMACY',
        },
      });
      if (!provider) {
        throw new BadRequestException('Select an active pharmacy provider.');
      }
      const preference = await tx.customerPreference.findUnique({
        where: { customerId },
        select: { preferredProviderId: true },
      });
      if (preference?.preferredProviderId === requestedProviderId) {
        throw new ConflictException('This pharmacy is already preferred.');
      }
      const pending = await tx.storeChangeRequest.findFirst({
        where: { customerId, status: 'PENDING' },
        select: { id: true },
      });
      if (pending) {
        throw new ConflictException('A store change request is already pending.');
      }
      const request = await tx.storeChangeRequest.create({
        data: {
          uuid: randomUUID(),
          customerId,
          previousProviderId: preference?.preferredProviderId ?? null,
          requestedProviderId,
          reason: normalizedReason,
          status: 'PENDING',
        },
        include: { previousProvider: true, requestedProvider: true },
      });
      await tx.activityEvent.create({
        data: {
          uuid: randomUUID(),
          customerId,
          activityType: 'STORE_CHANGE_REQUEST_SUBMITTED',
          relatedEntityType: 'store_change_request',
          relatedEntityId: request.id,
          status: 'PENDING',
          description: 'Customer submitted a preferred pharmacy change request.',
        },
      });
      return this.storeChangeRequestView(request);
    });
  }

  async getStoreChangeRequestCustomerId(requestId: bigint) {
    const request = await this.prisma.storeChangeRequest.findUnique({
      where: { id: requestId },
      select: { customerId: true },
    });
    if (!request) throw new NotFoundException('Store change request not found.');
    return request.customerId;
  }

  async reviewStoreChangeRequest(
    requestId: bigint,
    staffUserId: bigint,
    status: string | undefined,
    reason?: string,
  ) {
    const normalizedStatus = status?.trim().toUpperCase();
    if (normalizedStatus !== 'APPROVED' && normalizedStatus !== 'REJECTED') {
      throw new BadRequestException('Review status must be APPROVED or REJECTED.');
    }
    if (normalizedStatus === 'REJECTED' && !reason?.trim()) {
      throw new BadRequestException('A rejection reason is required.');
    }
    return this.prisma.$transaction(async (tx) => {
      const request = await tx.storeChangeRequest.findUnique({
        where: { id: requestId },
        include: { previousProvider: true, requestedProvider: true },
      });
      if (!request) throw new NotFoundException('Store change request not found.');
      if (request.status !== 'PENDING') {
        throw new ConflictException('Store change request has already been reviewed.');
      }
      const reviewed = await tx.storeChangeRequest.update({
        where: { id: requestId },
        data: {
          status: normalizedStatus,
          reviewReason: reason?.trim() || null,
          reviewedBy: staffUserId,
          reviewedAt: new Date(),
        },
        include: { previousProvider: true, requestedProvider: true },
      });
      if (normalizedStatus === 'APPROVED') {
        await tx.customerPreference.upsert({
          where: { customerId: request.customerId },
          create: {
            uuid: randomUUID(),
            customerId: request.customerId,
            preferredProviderId: request.requestedProviderId,
          },
          update: { preferredProviderId: request.requestedProviderId },
        });
      }
      await tx.activityEvent.create({
        data: {
          uuid: randomUUID(),
          customerId: request.customerId,
          activityType: `STORE_CHANGE_REQUEST_${normalizedStatus}`,
          relatedEntityType: 'store_change_request',
          relatedEntityId: requestId,
          agentUserId: staffUserId,
          createdBy: staffUserId,
          status: normalizedStatus,
          description: `Store change request ${normalizedStatus.toLowerCase()} by staff.`,
        },
      });
      await tx.notification.create({
        data: {
          customerId: request.customerId,
          title: 'Preferred pharmacy request updated',
          message:
            normalizedStatus === 'APPROVED'
              ? 'Your preferred pharmacy change request was approved.'
              : `Your preferred pharmacy change request was rejected${reason?.trim() ? `: ${reason.trim()}` : '.'}`,
          channel: 'IN_APP',
          status: 'UNREAD',
          sentAt: new Date(),
        },
      });
      return this.storeChangeRequestView(reviewed);
    });
  }

  async requestPhysicalCard(customerId: bigint, requestedBy?: bigint) {
    const customer = await this.findOne(customerId);
    if (!customer.membership) {
      throw new BadRequestException(
        'Create or activate membership before requesting a physical card.',
      );
    }
    const existing = await this.prisma.cardRequest.findFirst({
      where: {
        customerId,
        status: { in: ['REQUESTED', 'APPROVED', 'PRINTING', 'READY'] },
      },
      orderBy: { requestedAt: 'desc' },
    });
    if (existing) return existing;
    const request = await this.prisma.cardRequest.create({
      data: {
        uuid: randomUUID(),
        customerId,
        membershipId: customer.membership.id,
        status: 'REQUESTED',
        requestedBy,
      },
    });
    await this.recordCustomerAccountAudit(
      'CUSTOMER_PHYSICAL_CARD_REQUESTED',
      'CARD_REQUEST',
      request.id,
      customerId,
    );
    return request;
  }

  async listPhysicalCardRequests(customerId: bigint) {
    await this.findOne(customerId);
    const requests = await this.prisma.cardRequest.findMany({
      where: { customerId },
      orderBy: [{ requestedAt: 'desc' }, { id: 'desc' }],
    });
    return requests.map((request) => ({
      id: request.id.toString(),
      uuid: request.uuid,
      status: request.status,
      requestedAt: request.requestedAt,
      reviewedAt: request.reviewedAt,
      remarks: request.remarks,
    }));
  }

  async getCardProfile(customerId: bigint) {
    const customer = await this.findOne(customerId);
    const request = await this.prisma.cardRequest.findFirst({
      where: { customerId },
      orderBy: { requestedAt: 'desc' },
    });
    return {
      membership: customer.membership,
      digitalCard: customer.shieldCard,
      physicalCardRequest: request,
      action: customer.shieldCard
        ? 'VIEW_CARD'
        : request
          ? request.status
          : customer.membership
            ? 'REQUEST_PHYSICAL_CARD'
            : 'CREATE_OR_ACTIVATE_MEMBERSHIP',
    };
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
          where: { status: 'ACTIVE' },
          orderBy: { id: 'asc' },
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
      reason:
        'Customer onboarding or membership became inactive before qualification.',
    });

    return suspendedCustomer;
  }

  async activate(id: bigint, staffUserId: bigint) {
    const customer = await this.findOne(id);

    return this.prisma.$transaction(async (tx) => {
      if (customer.membership) {
        await tx.membership.update({
          where: { id: customer.membership.id },
          data: { status: 'ACTIVE' },
        });
      }

      if (customer.shieldCard) {
        await tx.shieldCard.update({
          where: { id: customer.shieldCard.id },
          data: { status: 'ACTIVE' },
        });
      }

      await tx.customerStatusHistory.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          oldStatus: customer.status,
          newStatus: 'ACTIVE',
          changedBy: staffUserId,
          remarks: 'Customer reactivated by staff',
        },
      });

      return tx.customer.update({
        where: { id: customer.id },
        data: { status: 'ACTIVE' },
      });
    });
  }

  async softDelete(id: bigint, staffUserId: bigint) {
    const customer = await this.findOne(id);
    return this.prisma.$transaction(async (tx) => {
      await tx.customerStatusHistory.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          oldStatus: customer.status,
          newStatus: customer.status,
          changedBy: staffUserId,
          remarks: 'Customer soft deleted by staff',
        },
      });
      return tx.customer.update({
        where: { id: customer.id },
        data: {
          deletedAt: new Date(),
        },
      });
    });
  }

  async generateCard(id: bigint, staffUserId: bigint) {
    const customer = await this.findOne(id);
    if (customer.shieldCard) {
      return customer.shieldCard;
    }

    return this.prisma.$transaction(async (tx) => {
      const staffUser = await tx.user.findUnique({
        where: { id: staffUserId },
        include: { department: true },
      });
      let issuedBusinessId = staffUser?.department?.businessId || null;
      if (!issuedBusinessId) {
        const defaultBiz = await tx.business.findFirst({
          where: { status: 'ACTIVE' },
          orderBy: { id: 'asc' },
        });
        issuedBusinessId = defaultBiz?.id ?? null;
      }

      return tx.shieldCard.create({
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
    });
  }

  private async createCustomerAggregate(data: any, staffUserId?: bigint) {
    const customerUuid = randomUUID();
    const customerCode = `CUST-${Math.floor(100000 + Math.random() * 900000)}`;

    return this.prisma.$transaction(async (tx) => {
      const normalizedMobile = data.mobile?.replace(/\D/g, '').slice(-10);
      if (!normalizedMobile) {
        throw new BadRequestException(
          'A valid primary mobile number is required.',
        );
      }
      const existingCustomer = await tx.customer.findFirst({
        where: { mobile: { endsWith: normalizedMobile }, deletedAt: null },
        select: { id: true },
      });
      if (existingCustomer) {
        throw new ConflictException(
          'Customer already exists. Use existing-customer conversion instead.',
        );
      }
      let referredById: bigint | null = null;
      if (data.referred_by_code) {
        const referrer = await tx.customer.findFirst({
          where: { referralCode: data.referred_by_code },
        });
        if (referrer && referrer.mobile !== data.mobile) {
          referredById = referrer.id;
        }
      }

      const desiredStatus = (data.status ?? 'PENDING')
        .toString()
        .trim()
        .toUpperCase();
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
          status: desiredStatus || 'PENDING',
          createdBy: staffUserId,
          bloodGroup: data.blood_group || null,
          agentCode: data.agent_code || 'AGT-SAHAKAR-DEFAULT',
          referralCode:
            data.referral_code ||
            `REF-${Math.floor(100000 + Math.random() * 900000)}`,
          referredById,
        },
      });

      const requestedMembershipTypeCode = data.membership_type_code
        ?.toString()
        .trim()
        .toUpperCase();
      const requestedMembershipTypeId = data.membership_type_id
        ? BigInt(data.membership_type_id)
        : undefined;
      const stdType = await tx.membershipType.findFirst({
        where: requestedMembershipTypeId
          ? { id: requestedMembershipTypeId }
          : requestedMembershipTypeCode
            ? { code: requestedMembershipTypeCode }
            : { code: 'STANDARD' },
      });

      if (stdType) {
        await tx.membership.create({
          data: {
            uuid: randomUUID(),
            customerId: customer.id,
            membershipTypeId: stdType.id,
            membershipNumber: `SHLD-${new Date().getFullYear()}-${customerCode.split('-')[1]}`,
            joiningFee: stdType.joiningFee,
            status:
              desiredStatus === 'ACTIVE'
                ? 'ACTIVE'
                : desiredStatus === 'APPROVED'
                  ? 'ACTIVE'
                  : 'INACTIVE',
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
