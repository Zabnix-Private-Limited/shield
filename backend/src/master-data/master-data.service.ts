import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const PLANNED_MASTER_DATA_DOMAINS = [
  'services',
  'wallet-rules',
  'benefit-rules',
  'referral-rules',
  'appointment-types',
  'consultation-types',
  'notification-templates',
  'holidays',
  'time-slots',
  'territories',
  'campaigns',
  'tags',
  'document-types',
  'blood-groups',
  'relationships',
  'genders',
  'customer-statuses',
  'provider-statuses',
  'crm-statuses',
  'lead-statuses',
  'system-settings',
] as const;

const SUPPORTED_MASTER_DATA_DOMAINS = [
  'businesses',
  'departments',
  'service-providers',
  'membership-types',
  'service-benefit-rules',
  'reward-point-rules',
  'reward-redemption-rules',
  'commercial-settings',
  'roles',
  'permissions',
  'business-types',
  'provider-types',
] as const;

type MasterDataDomain = (typeof SUPPORTED_MASTER_DATA_DOMAINS)[number];

@Injectable()
export class MasterDataService {
  constructor(private readonly prisma: PrismaService) {}

  async getCatalog() {
    const [
      businessCount,
      departmentCount,
      providerCount,
      membershipTypeCount,
      serviceBenefitRuleCount,
      rewardPointRuleCount,
      rewardRedemptionRuleCount,
      commercialSettingCount,
      roleCount,
      permissionCount,
      businessTypeCount,
      providerTypeCount,
    ] = await Promise.all([
      this.prisma.business.count(),
      this.prisma.department.count(),
      this.prisma.serviceProvider.count(),
      this.prisma.membershipType.count(),
      this.prisma.serviceBenefitRule.count(),
      this.prisma.rewardPointRule.count(),
      this.prisma.rewardRedemptionRule.count(),
      this.prisma.commercialSetting.count(),
      this.prisma.role.count(),
      this.prisma.permission.count(),
      this.prisma.business.findMany({
        distinct: ['businessType'],
        where: { businessType: { not: null } },
        select: { businessType: true },
      }),
      this.prisma.serviceProvider.findMany({
        distinct: ['providerType'],
        where: { providerType: { not: null } },
        select: { providerType: true },
      }),
    ]);

    return {
      generatedAt: new Date().toISOString(),
      availableDomains: [
        {
          key: 'businesses',
          label: 'Branches / Businesses',
          source: 'businesses',
          owner: 'Admin',
          count: businessCount,
        },
        {
          key: 'departments',
          label: 'Departments',
          source: 'departments',
          owner: 'Admin',
          count: departmentCount,
        },
        {
          key: 'service-providers',
          label: 'Service Providers',
          source: 'service_providers',
          owner: 'Admin',
          count: providerCount,
        },
        {
          key: 'membership-types',
          label: 'Membership Plans',
          source: 'membership_types',
          owner: 'Admin',
          count: membershipTypeCount,
        },
        {
          key: 'service-benefit-rules',
          label: 'Service Benefit Rules',
          source: 'service_benefit_rules',
          owner: 'Admin / Commercial',
          count: serviceBenefitRuleCount,
        },
        {
          key: 'reward-point-rules',
          label: 'Reward Rules',
          source: 'reward_point_rules',
          owner: 'Admin / Commercial',
          count: rewardPointRuleCount,
        },
        {
          key: 'reward-redemption-rules',
          label: 'Wallet Redemption Rules',
          source: 'reward_redemption_rules',
          owner: 'Admin / Commercial',
          count: rewardRedemptionRuleCount,
        },
        {
          key: 'commercial-settings',
          label: 'Commercial Settings',
          source: 'commercial_settings',
          owner: 'Admin / Commercial',
          count: commercialSettingCount,
        },
        {
          key: 'roles',
          label: 'RBAC Roles',
          source: 'roles',
          owner: 'Admin',
          count: roleCount,
        },
        {
          key: 'permissions',
          label: 'RBAC Permissions',
          source: 'permissions',
          owner: 'Admin',
          count: permissionCount,
        },
        {
          key: 'business-types',
          label: 'Derived Business Types',
          source: 'businesses.business_type',
          owner: 'Admin',
          count: businessTypeCount.length,
        },
        {
          key: 'provider-types',
          label: 'Derived Provider Types',
          source: 'service_providers.provider_type',
          owner: 'Admin',
          count: providerTypeCount.length,
        },
      ],
      plannedDomainsNotYetTableBacked: [...PLANNED_MASTER_DATA_DOMAINS],
      notes: [
        'This module is intentionally read-first and only exposes domains backed by the live schema.',
        'Service master data is not a dedicated table yet; service benefit rules currently act as the closest centralized service-rule source.',
        'System settings are currently represented only where tables already exist, such as commercial_settings and RBAC tables.',
      ],
    };
  }

  async getBootstrapSnapshot() {
    const [
      businesses,
      departments,
      serviceProviders,
      membershipTypes,
      serviceBenefitRules,
      rewardPointRules,
      rewardRedemptionRules,
      commercialSettings,
      roles,
      permissions,
      businessTypes,
      providerTypes,
    ] = await Promise.all([
      this.listBusinesses(),
      this.listDepartments(),
      this.listServiceProviders(),
      this.listMembershipTypes(),
      this.listServiceBenefitRules(),
      this.listRewardPointRules(),
      this.listRewardRedemptionRules(),
      this.listCommercialSettings(),
      this.listRoles(),
      this.listPermissions(),
      this.listBusinessTypes(),
      this.listProviderTypes(),
    ]);

    return {
      generatedAt: new Date().toISOString(),
      businesses,
      departments,
      serviceProviders,
      membershipTypes,
      serviceBenefitRules,
      rewardPointRules,
      rewardRedemptionRules,
      commercialSettings,
      roles,
      permissions,
      businessTypes,
      providerTypes,
      plannedDomainsNotYetTableBacked: [...PLANNED_MASTER_DATA_DOMAINS],
    };
  }

  async getDomainDataset(domain: string) {
    const normalizedDomain = domain.trim().toLowerCase() as MasterDataDomain;

    switch (normalizedDomain) {
      case 'businesses':
        return this.listBusinesses();
      case 'departments':
        return this.listDepartments();
      case 'service-providers':
        return this.listServiceProviders();
      case 'membership-types':
        return this.listMembershipTypes();
      case 'service-benefit-rules':
        return this.listServiceBenefitRules();
      case 'reward-point-rules':
        return this.listRewardPointRules();
      case 'reward-redemption-rules':
        return this.listRewardRedemptionRules();
      case 'commercial-settings':
        return this.listCommercialSettings();
      case 'roles':
        return this.listRoles();
      case 'permissions':
        return this.listPermissions();
      case 'business-types':
        return this.listBusinessTypes();
      case 'provider-types':
        return this.listProviderTypes();
      default:
        throw new BadRequestException(
          `Unsupported master data domain "${domain}". Supported domains: ${SUPPORTED_MASTER_DATA_DOMAINS.join(', ')}.`,
        );
    }
  }

  private async listBusinesses() {
    return this.prisma.business.findMany({
      orderBy: [{ name: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        name: true,
        businessType: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  private async listDepartments() {
    return this.prisma.department.findMany({
      orderBy: [{ businessId: 'asc' }, { name: 'asc' }],
      select: {
        id: true,
        uuid: true,
        businessId: true,
        code: true,
        name: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        business: {
          select: {
            id: true,
            code: true,
            name: true,
            status: true,
          },
        },
      },
    });
  }

  private async listServiceProviders() {
    return this.prisma.serviceProvider.findMany({
      orderBy: [{ providerType: 'asc' }, { providerName: 'asc' }],
      select: {
        id: true,
        uuid: true,
        businessId: true,
        providerName: true,
        providerType: true,
        status: true,
        business: {
          select: {
            id: true,
            code: true,
            name: true,
            businessType: true,
            status: true,
          },
        },
      },
    });
  }

  private async listMembershipTypes() {
    return this.prisma.membershipType.findMany({
      orderBy: [{ code: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        name: true,
        joiningFee: true,
        discountPercentage: true,
        creditEligible: true,
        status: true,
      },
    });
  }

  private async listServiceBenefitRules() {
    return this.prisma.serviceBenefitRule.findMany({
      orderBy: [{ serviceType: 'asc' }],
      select: {
        id: true,
        uuid: true,
        serviceType: true,
        isBenefitEligible: true,
        maxBenefitAmount: true,
        walletsAllowed: true,
        allowExternalPayment: true,
        qualifiesReferralReward: true,
        rewardPointsOnService: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  private async listRewardPointRules() {
    return this.prisma.rewardPointRule.findMany({
      orderBy: [{ actionCode: 'asc' }],
      select: {
        id: true,
        uuid: true,
        actionCode: true,
        displayName: true,
        points: true,
        requiresApproval: true,
        status: true,
        metadata: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  private async listRewardRedemptionRules() {
    return this.prisma.rewardRedemptionRule.findMany({
      orderBy: [{ code: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        pointsRequired: true,
        cashCreditAmount: true,
        minimumPoints: true,
        maximumPointsPerMonth: true,
        expiryMonths: true,
        creditLedgerType: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  private async listCommercialSettings() {
    return this.prisma.commercialSetting.findMany({
      orderBy: [{ code: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        valueType: true,
        valueText: true,
        valueNumber: true,
        valueBoolean: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  private async listRoles() {
    const roles = await this.prisma.role.findMany({
      orderBy: [{ code: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        name: true,
        description: true,
        userType: true,
        defaultScope: true,
        isSystemRole: true,
        rolePermissions: {
          select: {
            permission: {
              select: {
                id: true,
                code: true,
                name: true,
              },
            },
          },
        },
      },
    });

    return roles.map((role) => ({
      ...role,
      permissions: role.rolePermissions.map((entry) => entry.permission),
      permissionCodes: role.rolePermissions
        .map((entry) => entry.permission.code)
        .filter((value): value is string => Boolean(value)),
      rolePermissions: undefined,
    }));
  }

  private async listPermissions() {
    return this.prisma.permission.findMany({
      orderBy: [{ code: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        name: true,
        description: true,
      },
    });
  }

  private async listBusinessTypes() {
    const rows = await this.prisma.business.findMany({
      distinct: ['businessType'],
      where: { businessType: { not: null } },
      orderBy: [{ businessType: 'asc' }],
      select: {
        businessType: true,
      },
    });

    return rows
      .map((row) => row.businessType)
      .filter((value): value is string => Boolean(value));
  }

  private async listProviderTypes() {
    const rows = await this.prisma.serviceProvider.findMany({
      distinct: ['providerType'],
      where: { providerType: { not: null } },
      orderBy: [{ providerType: 'asc' }],
      select: {
        providerType: true,
      },
    });

    return rows
      .map((row) => row.providerType)
      .filter((value): value is string => Boolean(value));
  }
}
