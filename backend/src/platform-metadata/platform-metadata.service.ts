import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthService } from '../auth/auth.service';
import type { ShieldPrincipal } from '../auth/auth.types';
import { PlatformPrintService } from '../platform-capabilities/platform-print.service';
import { PlatformReportService } from '../platform-capabilities/platform-report.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  ProviderWorkflowProfileCode,
  ProviderWorkspaceMetadataService,
} from '../operations-queue/provider-workspace-metadata.service';

type ProviderPlatformMetadataQuery = {
  providerId?: bigint;
  providerType?: string;
  businessId?: bigint;
};

@Injectable()
export class PlatformMetadataService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authService: AuthService,
    private readonly providerWorkspaceMetadataService: ProviderWorkspaceMetadataService,
    private readonly platformPrintService: PlatformPrintService,
    private readonly platformReportService: PlatformReportService,
  ) {}

  async getProviderWorkspaceMetadata(
    query: ProviderPlatformMetadataQuery,
    principal?: ShieldPrincipal,
  ) {
    const providerScope = await this.resolveProviderScope(query);
    const workflowProfile = this.resolveWorkflowProfile(
      query.providerType,
      providerScope.providers,
    );
    const providerIds = providerScope.providers.map((provider) => provider.id);
    const providerWhere =
      providerIds.length > 0
        ? ({ providerId: { in: providerIds } } satisfies Prisma.AppointmentWhereInput)
        : providerScope.hasExplicitFilter
          ? ({ providerId: { in: [] } } satisfies Prisma.AppointmentWhereInput)
          : ({} satisfies Prisma.AppointmentWhereInput);
    const purchaseWhere =
      providerIds.length > 0
        ? ({ providerId: { in: providerIds } } satisfies Prisma.PurchaseWhereInput)
        : providerScope.hasExplicitFilter
          ? ({ providerId: { in: [] } } satisfies Prisma.PurchaseWhereInput)
          : ({} satisfies Prisma.PurchaseWhereInput);

    const now = new Date();
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(now);
    endOfToday.setHours(23, 59, 59, 999);

    const [appointmentsToday, pendingAppointments, openAppointments, recentPurchases] =
      await Promise.all([
        this.prisma.appointment.count({
          where: {
            ...providerWhere,
            appointmentDate: { gte: startOfToday, lte: endOfToday },
          },
        }),
        this.prisma.appointment.count({
          where: {
            ...providerWhere,
            status: { in: ['PENDING', 'CONFIRMED', 'SCHEDULED'] },
          },
        }),
        this.prisma.appointment.findMany({
          where: {
            ...providerWhere,
            status: { notIn: ['COMPLETED', 'CANCELLED'] },
          },
          select: { status: true },
          take: 50,
        }),
        this.prisma.purchase.findMany({
          where: purchaseWhere,
          select: { payableAmount: true },
          orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
          take: 50,
        }),
      ]);

    const queueMetrics = {
      waitingCount: openAppointments.filter((appointment) => {
        const stage = this.resolveQueueStageFromStatus(appointment.status);
        return stage === 'WAITING' || stage === 'ACCEPTED';
      }).length,
      activeCareCount: openAppointments.filter((appointment) => {
        const stage = this.resolveQueueStageFromStatus(appointment.status);
        return stage === 'CONSULTATION' || stage === 'READY_TO_COMPLETE';
      }).length,
      billingCount: recentPurchases.filter(
        (purchase) => Number(purchase.payableAmount ?? 0) > 0,
      ).length,
      appointmentsToday,
      pendingAppointments,
    };
    const authProfile = principal
      ? await this.authService.getProfile(principal)
      : undefined;
    const providerContext = this.buildProviderContext(
      workflowProfile,
      providerScope.providers,
      authProfile,
    );
    const permissions =
      Array.isArray(principal?.permissions) && principal!.permissions.length > 0
        ? principal!.permissions
        : ['providers.view'];

    return {
      generatedAt: now.toISOString(),
      workspace: 'provider',
      workspaceMeta: this.providerWorkspaceMetadataService.buildWorkspaceMeta(
        workflowProfile,
        queueMetrics,
        {
          providerContext,
          permissions,
        },
      ),
      reporting: this.platformReportService.listMetadata('provider'),
      printing: {
        title: 'Shared Print Engine',
        description:
          'Shared backend template registry with generate(templateId, payload).',
        templates: this.platformPrintService.listTemplates(),
      },
      realtime: {
        title: 'Shared Realtime Engine',
        description:
          'Backend-owned SSE stream for provider and future portal workspace updates.',
        endpoint: '/platform/realtime/stream',
        workspace: 'provider',
        active: true,
      },
    };
  }

  private async resolveProviderScope(query: ProviderPlatformMetadataQuery) {
    const where: Prisma.ServiceProviderWhereInput = {
      ...(query.providerId ? { id: query.providerId } : {}),
      ...(query.providerType ? { providerType: query.providerType } : {}),
      ...(query.businessId ? { businessId: query.businessId } : {}),
    };
    const hasExplicitFilter = Boolean(
      query.providerId || query.providerType || query.businessId,
    );

    const providers = await this.prisma.serviceProvider.findMany({
      where,
      select: {
        id: true,
        providerType: true,
        providerName: true,
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
      orderBy: [{ providerType: 'asc' }, { id: 'asc' }],
    });

    return { providers, hasExplicitFilter };
  }

  private resolveWorkflowProfile(
    providerType: string | undefined,
    providers: Array<{ providerType: string | null }>,
  ): ProviderWorkflowProfileCode {
    const explicit = this.mapProviderTypeToWorkflowProfile(providerType);
    if (explicit) {
      return explicit;
    }

    const detectedTypes = [
      ...new Set(
        providers
          .map((provider) =>
            this.mapProviderTypeToWorkflowProfile(provider.providerType ?? undefined),
          )
          .filter((value): value is ProviderWorkflowProfileCode => Boolean(value)),
      ),
    ];

    if (detectedTypes.length === 1) {
      return detectedTypes[0];
    }

    return 'GENERAL';
  }

  private mapProviderTypeToWorkflowProfile(
    providerType?: string,
  ): ProviderWorkflowProfileCode | undefined {
    switch ((providerType ?? '').trim().toUpperCase()) {
      case 'CLINIC':
        return 'CLINIC';
      case 'PHARMACY':
        return 'PHARMACY';
      case 'DENTAL':
        return 'DENTAL';
      case 'LAB':
      case 'LABORATORY':
        return 'LABORATORY';
      case 'HOME_VISIT':
        return 'HOME_VISIT';
      case 'COSMETIC':
        return 'COSMETIC';
      case 'DIETITIAN':
        return 'DIETITIAN';
      default:
        return undefined;
    }
  }

  private resolveQueueStageFromStatus(status?: string | null) {
    const normalized = (status ?? '').trim().toUpperCase();
    if (normalized.includes('COMPLETE') || normalized.includes('APPROVE')) {
      return 'COMPLETED';
    }
    if (normalized.includes('READY')) {
      return 'READY_TO_COMPLETE';
    }
    if (normalized.includes('WAIT')) {
      return 'WAITING';
    }
    if (
      normalized.includes('CHECKED') ||
      normalized.includes('PROCESS') ||
      normalized.includes('PROGRESS')
    ) {
      return 'CONSULTATION';
    }
    if (
      normalized.includes('CONFIRM') ||
      normalized.includes('SCHEDULED') ||
      normalized.includes('ASSIGN')
    ) {
      return 'ACCEPTED';
    }
    return 'WAITING';
  }

  private buildProviderContext(
    workflowProfile: ProviderWorkflowProfileCode,
    providers: Array<{
      id: bigint;
      providerType: string | null;
      providerName: string | null;
      status: string | null;
      business: {
        id: bigint;
        code: string | null;
        name: string | null;
        businessType: string | null;
        status: string | null;
      } | null;
    }>,
    authProfile?: Record<string, any>,
  ) {
    const display = (authProfile?.display as Record<string, any> | undefined) ?? {};
    const principal = (authProfile?.principal as Record<string, any> | undefined) ?? {};
    const profile = (authProfile?.profile as Record<string, any> | undefined) ?? {};
    const branch = (display['branch'] as Record<string, any> | undefined) ?? {};
    const primaryProvider = providers[0] ?? null;
    const primaryBusiness = primaryProvider?.business ?? null;
    const displayName =
      display['fullName']?.toString().trim() ||
      principal['displayName']?.toString().trim() ||
      `${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}`.trim() ||
      'SHIELD Provider';
    const branchName =
      branch['name']?.toString().trim() ||
      primaryBusiness?.name?.trim() ||
      principal['branchLabel']?.toString().trim() ||
      'Branch not assigned';
    const roleLabel =
      display['designation']?.toString().trim() ||
      principal['roleLabel']?.toString().trim() ||
      this.providerWorkspaceMetadataService.getWorkflowProfileLabel(workflowProfile);
    const departmentName = display['departmentName']?.toString().trim() || null;
    const branchStatus =
      branch['status']?.toString().trim() ||
      primaryBusiness?.status?.trim() ||
      'ACTIVE';

    return {
      providerName: displayName,
      role: roleLabel,
      department: departmentName,
      business: {
        name: primaryBusiness?.name?.trim() || branchName,
        type:
          primaryBusiness?.businessType?.trim() ||
          branch['businessType']?.toString().trim() ||
          null,
      },
      branch: {
        name: branchName,
        status: branchStatus,
      },
      workingHours: {
        title: 'Working Hours',
        summary:
          'Schedule details will appear here when provider availability is configured.',
      },
      availability: {
        title: 'Availability',
        status: branchStatus === 'ACTIVE' ? 'Available' : 'Unavailable',
        summary:
          'Live provider availability will derive from backend schedule configuration.',
      },
      primaryProvider: primaryProvider == null
          ? null
          : {
              name: primaryProvider.providerName?.trim() || displayName,
              status: primaryProvider.status?.trim() || 'ACTIVE',
            },
    };
  }
}
