import { ForbiddenException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import type { ShieldPrincipal } from './auth.types';

type ProviderWorkspaceScopeQuery = {
  providerId?: string;
  providerType?: string;
  businessId?: string;
};

type ReportScopeFilters = {
  workspace?: string;
  providerId?: bigint;
  providerType?: string;
  businessId?: bigint;
  dateFrom?: string;
  dateTo?: string;
  status?: string;
  search?: string;
  serviceType?: string;
  customerId?: bigint;
};

@Injectable()
export class ProviderScopeService {
  constructor(private readonly prisma: PrismaService) {}

  isProviderPrincipal(principal?: ShieldPrincipal) {
    return (
      principal?.principalType === 'USER' &&
      principal.userType === 'SERVICE_PROVIDER'
    );
  }

  resolveProviderType(principal?: ShieldPrincipal) {
    switch (principal?.roleCode?.trim().toUpperCase()) {
      case 'PHARMACY_PROVIDER':
        return 'PHARMACY';
      case 'LAB_PROVIDER':
        return 'LABORATORY';
      case 'DOCTOR':
        return 'CLINIC';
      case 'HOMECARE_PROVIDER':
        return 'HOME_VISIT';
      case 'DENTAL_PROVIDER':
        return 'DENTAL';
      case 'COSMETIC_PROVIDER':
        return 'COSMETIC';
      case 'DIETITIAN':
        return 'DIETITIAN';
      default:
        return undefined;
    }
  }

  resolveBusinessId(principal?: ShieldPrincipal) {
    const businessId = principal?.branchBusinessId?.trim() ?? '';
    return businessId ? BigInt(businessId) : undefined;
  }

  resolveWorkspaceScope(
    principal: ShieldPrincipal | undefined,
    query: ProviderWorkspaceScopeQuery,
  ) {
    const providerId = query.providerId?.trim()
      ? BigInt(query.providerId.trim())
      : undefined;
    const providerType = query.providerType?.trim() || undefined;
    const businessId = query.businessId?.trim()
      ? BigInt(query.businessId.trim())
      : undefined;

    if (!this.isProviderPrincipal(principal)) {
      return {
        providerId,
        providerType,
        businessId,
      };
    }

    return {
      providerId: undefined,
      providerType: this.resolveProviderType(principal),
      businessId: this.resolveBusinessId(principal),
    };
  }

  normalizeReportFilters(
    principal: ShieldPrincipal | undefined,
    filters: ReportScopeFilters,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return filters;
    }

    return {
      ...filters,
      providerId: undefined,
      providerType: this.resolveProviderType(principal),
      businessId: this.resolveBusinessId(principal),
    };
  }

  scopeAppointmentWhere(
    where: Prisma.AppointmentWhereInput,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return where;
    }

    return {
      AND: [
        where,
        {
          provider: {
            ...(this.resolveBusinessId(principal)
              ? { businessId: this.resolveBusinessId(principal) }
              : {}),
            ...(this.resolveProviderType(principal)
              ? { providerType: this.resolveProviderType(principal) }
              : {}),
          },
        },
      ],
    } satisfies Prisma.AppointmentWhereInput;
  }

  scopePurchaseWhere(
    where: Prisma.PurchaseWhereInput,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return where;
    }

    return {
      AND: [
        where,
        {
          provider: {
            ...(this.resolveBusinessId(principal)
              ? { businessId: this.resolveBusinessId(principal) }
              : {}),
            ...(this.resolveProviderType(principal)
              ? { providerType: this.resolveProviderType(principal) }
              : {}),
          },
        },
      ],
    } satisfies Prisma.PurchaseWhereInput;
  }

  async listAccessibleCustomerIds(
    principal: ShieldPrincipal | undefined,
    candidateCustomerIds?: bigint[],
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return candidateCustomerIds ?? [];
    }

    const customerFilter =
      candidateCustomerIds != null
        ? { customerId: { in: candidateCustomerIds } }
        : {};
    const [appointments, purchases] = await Promise.all([
      this.prisma.appointment.findMany({
        where: this.scopeAppointmentWhere(customerFilter, principal),
        select: { customerId: true },
        distinct: ['customerId'],
      }),
      this.prisma.purchase.findMany({
        where: this.scopePurchaseWhere(customerFilter, principal),
        select: { customerId: true },
        distinct: ['customerId'],
      }),
    ]);

    return Array.from(
      new Set(
        [...appointments, ...purchases]
          .map((item) => item.customerId)
          .filter((customerId): customerId is bigint => customerId != null),
      ),
    );
  }

  async assertProviderCanAccessCustomer(
    customerId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return;
    }

    const customerIds = await this.listAccessibleCustomerIds(principal, [customerId]);
    if (!customerIds.some((value) => value === customerId)) {
      throw new ForbiddenException(
        'You are not authorized to access this patient record.',
      );
    }
  }

  async assertProviderCanAccessAppointment(
    appointmentId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return;
    }

    const count = await this.prisma.appointment.count({
      where: this.scopeAppointmentWhere({ id: appointmentId }, principal),
    });
    if (count === 0) {
      throw new ForbiddenException(
        'You are not authorized to access this visit.',
      );
    }
  }

  async assertProviderCanAccessDocument(
    documentId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return;
    }

    const document = await this.prisma.document.findUnique({
      where: { id: documentId },
      select: { customerId: true },
    });
    if (!document?.customerId) {
      throw new ForbiddenException(
        'You are not authorized to access this record.',
      );
    }
    await this.assertProviderCanAccessCustomer(document.customerId, principal);
  }

  async assertProviderCanAccessNotification(
    notificationId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return;
    }

    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
      select: { customerId: true },
    });
    if (!notification?.customerId) {
      throw new ForbiddenException(
        'You are not authorized to access this notification.',
      );
    }
    await this.assertProviderCanAccessCustomer(notification.customerId, principal);
  }

  async assertProviderCanAccessPurchase(
    purchaseId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return;
    }

    const count = await this.prisma.purchase.count({
      where: this.scopePurchaseWhere({ id: purchaseId }, principal),
    });
    if (count === 0) {
      throw new ForbiddenException(
        'You are not authorized to access this invoice.',
      );
    }
  }

  async assertProviderCanAccessWalletByCustomer(
    customerId: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.assertProviderCanAccessCustomer(customerId, principal);
  }

  async assertProviderCanAccessWallet(
    walletId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isProviderPrincipal(principal)) {
      return;
    }

    const wallet = await this.prisma.wallet.findUnique({
      where: { id: walletId },
      select: { customerId: true },
    });
    if (!wallet?.customerId) {
      throw new ForbiddenException(
        'You are not authorized to access this wallet.',
      );
    }
    await this.assertProviderCanAccessCustomer(wallet.customerId, principal);
  }
}
