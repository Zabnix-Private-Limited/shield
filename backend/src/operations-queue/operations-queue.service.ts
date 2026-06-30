import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  ProviderWorkflowProfileCode,
  ProviderWorkspaceMetadataService,
} from './provider-workspace-metadata.service';

type ProviderWorkspaceQuery = {
  providerId?: bigint;
  providerType?: string;
  businessId?: bigint;
  limit?: number;
};

type CrmQueueQuery = {
  assignedTo?: bigint;
  customerId?: bigint;
  limit?: number;
};

type AdminQueueQuery = {
  businessId?: bigint;
  limit?: number;
};

type QueueItem = {
  kind: string;
  id: string;
  customerId: string | null;
  workflowType: string;
  workflowLabel: string;
  title: string;
  subtitle: string;
  meta: string;
  status: string;
  statusLabel: string;
  stageCode: string;
  stageLabel: string;
  primaryActionLabel: string;
  secondaryActionLabel: string;
  primaryTargetSection: string;
  secondaryTargetSection: string;
  primaryTargetTab: string;
  secondaryTargetTab: string;
};

@Injectable()
export class OperationsQueueService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly providerWorkspaceMetadataService: ProviderWorkspaceMetadataService,
  ) {}

  async getProviderWorkspace(query: ProviderWorkspaceQuery) {
    const limit = this.normalizeLimit(query.limit, 8);
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

    const [
      appointmentsToday,
      pendingAppointments,
      completedToday,
      openAppointments,
      recentPurchases,
      purchaseAggregate,
      appointmentCustomerRows,
      purchaseCustomerRows,
      allBusinesses,
      allDepartments,
      providerTypes,
    ] = await Promise.all([
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
      this.prisma.appointment.count({
        where: {
          ...providerWhere,
          status: 'COMPLETED',
          appointmentDate: { gte: startOfToday, lte: endOfToday },
        },
      }),
      this.prisma.appointment.findMany({
        where: {
          ...providerWhere,
          status: { notIn: ['COMPLETED', 'CANCELLED'] },
        },
        include: {
          customer: true,
          provider: {
            include: {
              business: true,
            },
          },
        },
        orderBy: [{ appointmentDate: 'asc' }, { id: 'asc' }],
        take: limit,
      }),
      this.prisma.purchase.findMany({
        where: purchaseWhere,
        include: {
          customer: true,
          provider: {
            include: {
              business: true,
            },
          },
        },
        orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
        take: limit,
      }),
      this.prisma.purchase.aggregate({
        where: purchaseWhere,
        _sum: {
          payableAmount: true,
        },
      }),
      this.prisma.appointment.findMany({
        where: {
          ...providerWhere,
          customerId: { not: null },
        },
        distinct: ['customerId'],
        select: { customerId: true },
        take: 30,
      }),
      this.prisma.purchase.findMany({
        where: {
          ...purchaseWhere,
          customerId: { not: null },
        },
        distinct: ['customerId'],
        select: { customerId: true },
        take: 30,
      }),
      this.prisma.business.findMany({
        orderBy: [{ name: 'asc' }],
        select: { id: true, name: true, code: true, status: true, businessType: true },
      }),
      this.prisma.department.findMany({
        orderBy: [{ businessId: 'asc' }, { name: 'asc' }],
        select: { id: true, businessId: true, name: true, code: true, status: true },
      }),
      this.prisma.serviceProvider.findMany({
        distinct: ['providerType'],
        where: { providerType: { not: null } },
        orderBy: [{ providerType: 'asc' }],
        select: { providerType: true },
      }),
    ]);

    const patientRows = await this.prisma.appointment.findMany({
      where: {
        ...providerWhere,
        appointmentDate: { gte: startOfToday, lte: endOfToday },
      },
      distinct: ['customerId'],
      select: { customerId: true },
    });
    const customerIds = [
      ...appointmentCustomerRows,
      ...purchaseCustomerRows,
    ]
      .map((row) => row.customerId)
      .filter((value): value is bigint => value !== null);
    const uniqueCustomerIds = [...new Set(customerIds.map((id) => id.toString()))].map(
      (id) => BigInt(id),
    );
    const providerCustomers =
      uniqueCustomerIds.length == 0
        ? []
        : await this.prisma.customer.findMany({
            where: {
              id: { in: uniqueCustomerIds },
            },
            include: {
              membership: {
                include: {
                  membershipType: true,
                },
              },
              shieldCard: true,
            },
            orderBy: [{ firstName: 'asc' }, { id: 'asc' }],
            take: 30,
          });

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
    const workspaceMeta = this.providerWorkspaceMetadataService.buildWorkspaceMeta(
      workflowProfile,
      queueMetrics,
    );

    return {
      generatedAt: now.toISOString(),
      workspace: 'provider',
      scope: {
        providerId: query.providerId?.toString() ?? null,
        providerType: query.providerType ?? null,
        businessId: query.businessId?.toString() ?? null,
        matchedProviderCount: providerScope.providers.length,
      },
      workspaceMeta,
      summary: {
        providerCount: providerScope.providers.length,
        appointmentsToday,
        pendingAppointments,
        completedToday,
        uniquePatientsToday: patientRows.filter((row) => row.customerId !== null).length,
        totalRevenue: Number(purchaseAggregate._sum.payableAmount ?? 0),
      },
      filterOptions: {
        businesses: allBusinesses,
        departments: this.filterDepartmentsForBusiness(
          allDepartments,
          query.businessId,
        ),
        providerTypes: providerTypes
          .map((row) => row.providerType)
          .filter((value): value is string => Boolean(value)),
      },
      providers: providerScope.providers,
      customers: providerCustomers.map((customer) => ({
        id: customer.id.toString(),
        uuid: customer.uuid,
        customerCode: customer.customerCode,
        firstName: customer.firstName,
        lastName: customer.lastName,
        fullName:
          `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
          customer.mobile,
        mobile: customer.mobile,
        status: customer.status,
        city: customer.city,
        district: customer.district,
        membershipNumber: customer.membership?.membershipNumber ?? null,
        membershipStatus: customer.membership?.status ?? null,
        membershipPlan: customer.membership?.membershipType?.name ?? null,
        shieldCardNumber: customer.shieldCard?.cardNumber ?? null,
        displaySummary: customer.membership?.membershipType?.name
          ? `${customer.membership.membershipType.name} • ${customer.mobile}`
          : customer.mobile,
      })),
      queues: {
        appointments: openAppointments.map((appointment) =>
          this.toAppointmentQueueItem(appointment, workflowProfile),
        ),
        billing: recentPurchases.map((purchase) =>
          this.toPurchaseQueueItem(purchase, workflowProfile),
        ),
      },
    };
  }

  async getCrmQueue(query: CrmQueueQuery) {
    const limit = this.normalizeLimit(query.limit, 10);
    const now = new Date();

    const taskWhere: Prisma.CrmTaskWhereInput = {
      ...(query.customerId ? { customerId: query.customerId } : {}),
      ...(query.assignedTo ? { assignedTo: query.assignedTo } : {}),
    };
    const complaintWhere: Prisma.ComplaintWhereInput = {
      ...(query.customerId ? { customerId: query.customerId } : {}),
    };

    const [pendingTasks, overdueTasks, openComplaints, tasks, complaints, activities] =
      await Promise.all([
        this.prisma.crmTask.count({
          where: {
            ...taskWhere,
            status: 'PENDING',
          },
        }),
        this.prisma.crmTask.count({
          where: {
            ...taskWhere,
            status: { in: ['PENDING', 'IN_PROGRESS'] },
            dueDate: { lt: now },
          },
        }),
        this.prisma.complaint.count({
          where: {
            ...complaintWhere,
            status: { not: 'RESOLVED' },
          },
        }),
        this.prisma.crmTask.findMany({
          where: taskWhere,
          include: {
            customer: true,
            assignedToUser: true,
          },
          orderBy: [{ dueDate: 'asc' }, { id: 'asc' }],
          take: limit,
        }),
        this.prisma.complaint.findMany({
          where: complaintWhere,
          include: {
            customer: true,
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: limit,
        }),
        this.prisma.crmActivity.findMany({
          where: {
            ...(query.customerId ? { customerId: query.customerId } : {}),
          },
          include: {
            customer: true,
            createdByUser: true,
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: limit,
        }),
      ]);

    return {
      generatedAt: now.toISOString(),
      workspace: 'crm',
      scope: {
        assignedTo: query.assignedTo?.toString() ?? null,
        customerId: query.customerId?.toString() ?? null,
      },
      summary: {
        pendingTasks,
        overdueTasks,
        openComplaints,
        activityCount: activities.length,
      },
      queues: {
        tasks: tasks.map((task) => ({
          kind: 'crm-task',
          id: task.id.toString(),
          title: task.customer
            ? `Follow-up: ${task.customer.firstName ?? ''} ${task.customer.lastName ?? ''}`.trim()
            : `Follow-up task ${task.id.toString()}`,
          subtitle: task.notes || 'Customer follow-up task',
          meta: task.dueDate ? task.dueDate.toISOString() : 'No due date',
          status: task.status || 'PENDING',
        })),
        complaints: complaints.map((complaint) => ({
          kind: 'complaint',
          id: complaint.id.toString(),
          title: complaint.complaintType || 'Complaint',
          subtitle:
            complaint.customer
              ? `${complaint.customer.firstName ?? ''} ${complaint.customer.lastName ?? ''}`.trim()
              : 'Unassigned customer',
          meta: complaint.createdAt.toISOString(),
          status: complaint.status || 'PENDING',
        })),
        activity: activities.map((activity) => ({
          kind: 'crm-activity',
          id: activity.id.toString(),
          title: activity.activityType || 'CRM activity',
          subtitle: activity.notes || 'Customer interaction note',
          meta: activity.createdAt.toISOString(),
          status: activity.createdByUser?.firstName || 'RECORDED',
        })),
      },
    };
  }

  async getAdminQueue(query: AdminQueueQuery) {
    const limit = this.normalizeLimit(query.limit, 8);
    const now = new Date();

    const businessProviderIds = query.businessId
      ? (
          await this.prisma.serviceProvider.findMany({
            where: { businessId: query.businessId },
            select: { id: true },
          })
        ).map((provider) => provider.id)
      : [];
    const appointmentWhere: Prisma.AppointmentWhereInput =
      businessProviderIds.length > 0
        ? { providerId: { in: businessProviderIds } }
        : query.businessId
          ? { providerId: { in: [] } }
          : {};

    const [
      pendingCustomers,
      processingDocuments,
      openComplaints,
      inactiveProviders,
      pendingCustomerRows,
      processingDocumentRows,
      inactiveProviderRows,
      recentAppointments,
    ] = await Promise.all([
      this.prisma.customer.count({ where: { status: 'PENDING' } }),
      this.prisma.document.count({ where: { status: 'PROCESSING' } }),
      this.prisma.complaint.count({ where: { status: { not: 'RESOLVED' } } }),
      this.prisma.serviceProvider.count({
        where: {
          ...(query.businessId ? { businessId: query.businessId } : {}),
          status: { not: 'ACTIVE' },
        },
      }),
      this.prisma.customer.findMany({
        where: { status: 'PENDING' },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        take: limit,
      }),
      this.prisma.document.findMany({
        where: { status: 'PROCESSING' },
        include: {
          customer: true,
        },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        take: limit,
      }),
      this.prisma.serviceProvider.findMany({
        where: {
          ...(query.businessId ? { businessId: query.businessId } : {}),
          status: { not: 'ACTIVE' },
        },
        include: {
          business: true,
        },
        orderBy: [{ id: 'asc' }],
        take: limit,
      }),
      this.prisma.appointment.findMany({
        where: {
          ...appointmentWhere,
          appointmentDate: { gte: now },
        },
        include: {
          customer: true,
          provider: {
            include: {
              business: true,
            },
          },
        },
        orderBy: [{ appointmentDate: 'asc' }, { id: 'asc' }],
        take: limit,
      }),
    ]);

    return {
      generatedAt: now.toISOString(),
      workspace: 'admin',
      scope: {
        businessId: query.businessId?.toString() ?? null,
      },
      summary: {
        pendingCustomers,
        processingDocuments,
        openComplaints,
        inactiveProviders,
      },
      queues: {
        onboarding: pendingCustomerRows.map((customer) => ({
          kind: 'customer-onboarding',
          id: customer.id.toString(),
          title: `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
            customer.mobile ||
            `Customer ${customer.id.toString()}`,
          subtitle: customer.mobile || 'No mobile number',
          meta: customer.createdAt.toISOString(),
          status: customer.status || 'PENDING',
        })),
        documents: processingDocumentRows.map((document) => ({
          kind: 'document-review',
          id: document.id.toString(),
          title: document.fileName || 'Document',
          subtitle:
            document.customer
              ? `${document.customer.firstName ?? ''} ${document.customer.lastName ?? ''}`.trim()
              : 'No customer linked',
          meta: document.createdAt.toISOString(),
          status: document.status || 'PROCESSING',
        })),
        providers: inactiveProviderRows.map((provider) => ({
          kind: 'provider-readiness',
          id: provider.id.toString(),
          title: provider.providerName || `Provider ${provider.id.toString()}`,
          subtitle: provider.business?.name || 'No business linked',
          meta: provider.providerType || 'UNKNOWN',
          status: provider.status || 'INACTIVE',
        })),
        appointments: recentAppointments.map((appointment) =>
          this.toAppointmentQueueItem(appointment, 'GENERAL'),
        ),
      },
    };
  }

  private async resolveProviderScope(query: ProviderWorkspaceQuery) {
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
      include: {
        business: true,
      },
      orderBy: [{ providerType: 'asc' }, { providerName: 'asc' }],
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
          .map((provider) => this.mapProviderTypeToWorkflowProfile(provider.providerType ?? undefined))
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

  private buildProviderWorkspaceMeta(
    profile: ProviderWorkflowProfileCode,
    metrics: {
      waitingCount: number;
      activeCareCount: number;
      billingCount: number;
      appointmentsToday: number;
      pendingAppointments: number;
    },
  ) {
    const profileLabel = this.getWorkflowProfileLabel(profile);
    return {
      providerContext: {
        providerType: profile,
        workspaceTitle: this.getWorkspaceTitle(profile),
        headline: this.getWorkspaceHeadline(profile),
      },
      workflowProfile: {
        code: profile,
        title: profileLabel,
      },
      moduleRegistry: this.buildModuleRegistry(profile),
      navigationSections: this.buildNavigationSections(profile, metrics),
      queueStages: this.buildQueueStages(profile),
      dashboardHighlights: this.buildDashboardHighlights(profile),
      patientWorkspace: {
        title: 'Patient workspace',
        emptyStateMessage:
          'Select a patient to open the full care view. Visits, records, benefits, and payments stay together here.',
        tabs: [
          {
            code: 'overview',
            title: 'Summary',
            icon: 'summary',
            order: 1,
            emptyStateMessage: 'No patient summary is available yet.',
          },
          {
            code: 'timeline',
            title: 'Timeline',
            icon: 'timeline',
            order: 2,
            emptyStateMessage: 'No patient history is available yet.',
          },
          {
            code: 'appointments',
            title: 'Appointments',
            icon: 'calendar',
            order: 3,
            emptyStateMessage:
              'No appointments have been added for this patient yet.',
          },
          {
            code: 'records',
            title: 'Medical Records',
            icon: 'folder',
            order: 4,
            emptyStateMessage:
              'No medical records have been uploaded yet. Prescriptions, reports, and supporting files will appear here.',
          },
          {
            code: 'payments',
            title: 'Payments',
            icon: 'payments',
            order: 5,
            emptyStateMessage:
              'No patient billing details are available yet.',
          },
          {
            code: 'membership',
            title: 'Membership',
            icon: 'membership',
            order: 6,
            emptyStateMessage:
              'No membership details are available yet.',
          },
        ],
      },
    };
  }

  private buildNavigationSections(
    profile: ProviderWorkflowProfileCode,
    metrics: {
      waitingCount: number;
      activeCareCount: number;
      billingCount: number;
      appointmentsToday: number;
      pendingAppointments: number;
    },
  ) {
    return [
      {
        id: 'dashboard',
        title: 'Dashboard',
        icon: 'dashboard',
        route: '/portal/provider/dashboard',
        permission: 'providers.view',
        badge: metrics.activeCareCount,
        order: 1,
      },
      {
        id: 'queue',
        title: 'Live Queue',
        icon: 'queue',
        route: '/portal/provider/queue',
        permission: 'providers.view',
        badge: metrics.waitingCount + metrics.billingCount,
        order: 2,
      },
      {
        id: 'customers',
        title: 'Patients',
        icon: 'patient',
        route: '/portal/provider/customers',
        permission: 'providers.view',
        badge: 0,
        order: 3,
      },
      {
        id: 'appointments',
        title: 'Appointments',
        icon: 'calendar',
        route: '/portal/provider/appointments',
        permission: 'providers.view',
        badge: metrics.pendingAppointments,
        order: 4,
      },
      {
        id: 'documents',
        title: this.getRecordsNavigationTitle(profile),
        icon: 'folder',
        route: '/portal/provider/documents',
        permission: 'providers.view',
        badge: 0,
        order: 5,
      },
      {
        id: 'prescriptions',
        title: this.getPrescriptionsNavigationTitle(profile),
        icon: 'prescription',
        route: '/portal/provider/prescriptions',
        permission: 'providers.view',
        badge: 0,
        order: 6,
      },
      {
        id: 'profile',
        title: 'Profile',
        icon: 'profile',
        route: '/portal/provider/profile',
        permission: 'providers.view',
        badge: 0,
        order: 7,
      },
      {
        id: 'settings',
        title: 'Settings',
        icon: 'settings',
        route: '/portal/provider/settings',
        permission: 'providers.view',
        badge: 0,
        order: 8,
      },
    ];
  }

  private buildModuleRegistry(profile: ProviderWorkflowProfileCode) {
    const baseModules = [
      { id: 'dashboard', title: 'Dashboard', permission: 'providers.view' },
      { id: 'queue', title: 'Live Queue', permission: 'providers.view' },
      { id: 'patients', title: 'Patient Workspace', permission: 'providers.view' },
      { id: 'appointments', title: 'Appointments', permission: 'providers.view' },
      { id: 'documents', title: 'Medical Records', permission: 'providers.view' },
      { id: 'settings', title: 'Settings', permission: 'providers.view' },
    ];

    switch (profile) {
      case 'PHARMACY':
        return [
          ...baseModules,
          { id: 'prescriptions', title: 'Prescription Verification', permission: 'providers.view' },
          { id: 'billing', title: 'Billing', permission: 'providers.view' },
        ];
      case 'LABORATORY':
        return [
          ...baseModules,
          { id: 'samples', title: 'Sample Collection', permission: 'providers.view' },
          { id: 'reports', title: 'Lab Reports', permission: 'providers.view' },
        ];
      case 'DENTAL':
        return [
          ...baseModules,
          { id: 'treatments', title: 'Treatments', permission: 'providers.view' },
          { id: 'prescriptions', title: 'Prescriptions', permission: 'providers.view' },
        ];
      default:
        return [
          ...baseModules,
          { id: 'prescriptions', title: 'Prescriptions', permission: 'providers.view' },
        ];
    }
  }

  private buildQueueStages(profile: ProviderWorkflowProfileCode) {
    const dictionary = this.getQueueStageDictionary(profile);
    return [
      this.toQueueStageMeta('WAITING', 1, dictionary),
      this.toQueueStageMeta('ACCEPTED', 2, dictionary),
      this.toQueueStageMeta('CONSULTATION', 3, dictionary),
      this.toQueueStageMeta('WAITING_PAYMENT', 4, dictionary),
      this.toQueueStageMeta('READY_TO_COMPLETE', 5, dictionary),
      this.toQueueStageMeta('COMPLETED', 6, dictionary),
    ];
  }

  private buildDashboardHighlights(profile: ProviderWorkflowProfileCode) {
    const waitingTitle = this.getDashboardWaitingTitle(profile);
    return [
      {
        code: 'URGENT',
        title: 'Urgent',
        note: 'needs attention now',
        icon: 'priority',
        color: 'red',
        order: 1,
        metricKind: 'urgent',
        stageCodes: [] as string[],
      },
      {
        code: 'WAITING',
        title: waitingTitle,
        note: 'patients or billing items pending',
        icon: 'queue',
        color: 'orange',
        order: 2,
        metricKind: 'stage_count',
        stageCodes: ['WAITING', 'WAITING_PAYMENT'],
      },
      {
        code: 'CONSULTATION',
        title: this.getConsultationStageTitle(profile),
        note: 'care work in progress',
        icon: 'care',
        color: 'blue',
        order: 3,
        metricKind: 'stage_count',
        stageCodes: ['CONSULTATION'],
      },
      {
        code: 'READY_TO_COMPLETE',
        title: this.getReadyStageTitle(profile),
        note: 'can be finished now',
        icon: 'checklist',
        color: 'green',
        order: 4,
        metricKind: 'stage_count',
        stageCodes: ['READY_TO_COMPLETE'],
      },
    ];
  }

  private toQueueStageMeta(
    code: string,
    order: number,
    dictionary: Record<
      string,
      {
        title: string;
        icon: string;
        color: string;
        emptyStateMessage: string;
        allowedActions: string[];
      }
    >,
  ) {
    const meta = dictionary[code];
    return {
      code,
      title: meta.title,
      icon: meta.icon,
      color: meta.color,
      order,
      emptyStateMessage: meta.emptyStateMessage,
      allowedActions: meta.allowedActions,
    };
  }

  private getQueueStageDictionary(profile: ProviderWorkflowProfileCode) {
    const consultationTitle = this.getConsultationStageTitle(profile);
    const waitingTitle = this.getDashboardWaitingTitle(profile);
    const readyTitle = this.getReadyStageTitle(profile);

    return {
      WAITING: {
        title: waitingTitle,
        icon: 'queue',
        color: 'orange',
        emptyStateMessage: this.getWaitingEmptyState(profile),
        allowedActions: ['Open patient'],
      },
      ACCEPTED: {
        title: 'Accepted',
        icon: 'assignment',
        color: 'blue',
        emptyStateMessage: 'No accepted patients are queued here.',
        allowedActions: ['Open patient', this.getAcceptedPrimaryAction(profile)],
      },
      CONSULTATION: {
        title: consultationTitle,
        icon: 'care',
        color: 'blue',
        emptyStateMessage: this.getConsultationEmptyState(profile),
        allowedActions: ['Open patient', 'Continue care'],
      },
      WAITING_PAYMENT: {
        title: 'Waiting for Payment',
        icon: 'payments',
        color: 'amber',
        emptyStateMessage: 'No billing items are waiting for payment right now.',
        allowedActions: ['Open patient', 'Open billing'],
      },
      READY_TO_COMPLETE: {
        title: readyTitle,
        icon: 'checklist',
        color: 'green',
        emptyStateMessage: 'Nothing is waiting to be completed.',
        allowedActions: ['Open patient', 'Finish visit'],
      },
      COMPLETED: {
        title: 'Completed',
        icon: 'done',
        color: 'slate',
        emptyStateMessage: 'No completed items have been loaded yet.',
        allowedActions: ['Open patient', 'View summary'],
      },
    };
  }

  private getWorkflowProfileLabel(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'CLINIC':
        return 'Clinic Care Workflow';
      case 'PHARMACY':
        return 'Pharmacy Fulfillment Workflow';
      case 'DENTAL':
        return 'Dental Care Workflow';
      case 'LABORATORY':
        return 'Laboratory Workflow';
      case 'HOME_VISIT':
        return 'Home Care Workflow';
      case 'COSMETIC':
        return 'Cosmetic Care Workflow';
      case 'DIETITIAN':
        return 'Dietitian Care Workflow';
      case 'GENERAL':
      default:
        return 'Provider Care Workflow';
    }
  }

  private getWorkspaceTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Pharmacy Workspace';
      case 'DENTAL':
        return 'Dental Workspace';
      case 'LABORATORY':
        return 'Laboratory Workspace';
      case 'HOME_VISIT':
        return 'Home Care Workspace';
      case 'COSMETIC':
        return 'Cosmetic Care Workspace';
      case 'DIETITIAN':
        return 'Dietitian Workspace';
      case 'CLINIC':
        return 'Clinic Workspace';
      case 'GENERAL':
      default:
        return 'Provider Care Hub';
    }
  }

  private getWorkspaceHeadline(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Verification, dispensing, billing, and patient records in one place';
      case 'DENTAL':
        return 'Treatments, appointments, records, and follow-ups in one place';
      case 'LABORATORY':
        return 'Samples, reports, appointments, and patient history in one place';
      case 'HOME_VISIT':
        return 'Visits, notes, records, and follow-ups in one place';
      default:
        return 'Patients, appointments, records, and payments in one place';
    }
  }

  private getRecordsNavigationTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'LABORATORY':
        return 'Lab Reports';
      default:
        return 'Medical Records';
    }
  }

  private getPrescriptionsNavigationTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Prescription Review';
      case 'LABORATORY':
        return 'Reports';
      default:
        return 'Prescriptions';
    }
  }

  private getDashboardWaitingTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Waiting for Verification';
      case 'DENTAL':
        return 'Waiting for Treatment';
      case 'LABORATORY':
        return 'Waiting for Sample';
      case 'HOME_VISIT':
        return 'Waiting for Visit Start';
      default:
        return 'Waiting for Consultation';
    }
  }

  private getConsultationStageTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Dispensing';
      case 'DENTAL':
        return 'Treatment in Progress';
      case 'LABORATORY':
        return 'Sample in Progress';
      case 'HOME_VISIT':
        return 'Visit in Progress';
      case 'COSMETIC':
        return 'Session in Progress';
      case 'DIETITIAN':
        return 'Plan Review in Progress';
      default:
        return 'Consultation';
    }
  }

  private getReadyStageTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Ready for Handover';
      case 'LABORATORY':
        return 'Ready to Upload Report';
      case 'HOME_VISIT':
        return 'Ready to Close Visit';
      default:
        return 'Ready to Complete';
    }
  }

  private getWaitingEmptyState(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'No prescriptions or customers are waiting for verification right now.';
      case 'DENTAL':
        return 'No patients are waiting for treatment right now.';
      case 'LABORATORY':
        return 'No samples are waiting to be collected right now.';
      default:
        return 'No patients are waiting right now.';
    }
  }

  private getConsultationEmptyState(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'No dispensing work is in progress.';
      case 'DENTAL':
        return 'No dental treatment is in progress.';
      case 'LABORATORY':
        return 'No sample processing is in progress.';
      default:
        return 'No consultations are in progress.';
    }
  }

  private getAcceptedPrimaryAction(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Start verification';
      case 'DENTAL':
        return 'Start treatment';
      case 'LABORATORY':
        return 'Start sample collection';
      default:
        return 'Start consultation';
    }
  }

  private filterDepartmentsForBusiness(
    departments: Array<{
      id: bigint;
      businessId: bigint;
      name: string | null;
      code: string | null;
      status: string | null;
    }>,
    businessId?: bigint,
  ) {
    return departments.filter((department) =>
      businessId ? department.businessId === businessId : true,
    );
  }

  private toAppointmentQueueItem(appointment: {
    id: bigint;
    customerId: bigint | null;
    appointmentType: string | null;
    appointmentDate: Date | null;
    status: string | null;
    customer?: { firstName: string | null; lastName: string | null } | null;
    provider?:
      | {
          providerName: string | null;
          business?: { name: string | null; code?: string | null } | null;
        }
      | null;
  }, workflowProfile: ProviderWorkflowProfileCode): QueueItem {
    const customerName =
      appointment.customer
        ? `${appointment.customer.firstName ?? ''} ${appointment.customer.lastName ?? ''}`.trim()
        : '';
    const providerName = appointment.provider?.providerName || 'Provider';
    const branchName = this.getBranchDisplayName(
      appointment.provider?.business?.code,
      appointment.provider?.business?.name,
      appointment.provider?.providerName,
      appointment.appointmentType,
    );
    const stageCode = this.resolveQueueStageFromStatus(appointment.status);
    return {
      kind: 'appointment',
      id: appointment.id.toString(),
      customerId: appointment.customerId?.toString() ?? null,
      workflowType: 'APPOINTMENT',
      workflowLabel: 'Appointment',
      title: customerName || 'Patient awaiting care',
      subtitle: `${appointment.appointmentType || 'Appointment'} • ${providerName}`,
      meta: `${branchName} • ${this.formatDateTime(appointment.appointmentDate)}`,
      status: appointment.status || 'PENDING',
      statusLabel: this.getAppointmentStatusLabel(appointment.status),
      stageCode,
      stageLabel: this.providerWorkspaceMetadataService.buildQueueStageLabel(
        workflowProfile,
        stageCode,
        appointment.status,
      ),
      primaryActionLabel: this.providerWorkspaceMetadataService.buildPrimaryActionLabel(
        workflowProfile,
        stageCode,
        'APPOINTMENT',
      ),
      secondaryActionLabel: 'Open patient',
      primaryTargetSection: 'customers',
      secondaryTargetSection: 'customers',
      primaryTargetTab: this.providerWorkspaceMetadataService.buildPrimaryTargetTab(
        stageCode,
        'APPOINTMENT',
      ),
      secondaryTargetTab: 'overview',
    };
  }

  private toPurchaseQueueItem(purchase: {
    id: bigint;
    customerId: bigint | null;
    purchaseDate: Date | null;
    payableAmount: Prisma.Decimal | null;
    invoiceNumber: string | null;
    customer?: { firstName: string | null; lastName: string | null } | null;
    provider?:
      | {
          providerName: string | null;
          business?: { name: string | null } | null;
        }
      | null;
  }, workflowProfile: ProviderWorkflowProfileCode): QueueItem {
    const customerName =
      purchase.customer
        ? `${purchase.customer.firstName ?? ''} ${purchase.customer.lastName ?? ''}`.trim()
        : 'Customer not linked';
    const stageCode = Number(purchase.payableAmount ?? 0) > 0 ? 'WAITING_PAYMENT' : 'COMPLETED';
    return {
      kind: 'purchase',
      id: purchase.id.toString(),
      customerId: purchase.customerId?.toString() ?? null,
      workflowType: 'PAYMENT',
      workflowLabel: 'Payment',
      title: customerName,
      subtitle: purchase.invoiceNumber
        ? `${stageCode === 'COMPLETED' ? 'Payment completed' : 'Payment pending'} • Invoice ${purchase.invoiceNumber}`
        : `${stageCode === 'COMPLETED' ? 'Payment completed' : 'Payment pending'} • ${purchase.provider?.providerName || 'Provider'}`,
      meta: this.formatDateTime(purchase.purchaseDate),
      status: stageCode,
      statusLabel: this.formatCurrency(Number(purchase.payableAmount ?? 0)),
      stageCode,
      stageLabel: this.providerWorkspaceMetadataService.buildQueueStageLabel(
        workflowProfile,
        stageCode,
      ),
      primaryActionLabel: this.providerWorkspaceMetadataService.buildPrimaryActionLabel(
        workflowProfile,
        stageCode,
        'PAYMENT',
      ),
      secondaryActionLabel: 'Open patient',
      primaryTargetSection: 'customers',
      secondaryTargetSection: 'customers',
      primaryTargetTab: this.providerWorkspaceMetadataService.buildPrimaryTargetTab(
        stageCode,
        'PAYMENT',
      ),
      secondaryTargetTab: 'overview',
    };
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

  private getStageLabel(stageCode: string, rawStatus?: string | null) {
    switch (stageCode) {
      case 'ACCEPTED':
        return 'Accepted';
      case 'CONSULTATION':
        return 'Consultation in Progress';
      case 'WAITING_PAYMENT':
        return 'Waiting for Payment';
      case 'WAITING':
        if ((rawStatus ?? '').toUpperCase().includes('LAB')) {
          return 'Waiting for Lab Report';
        }
        return 'Waiting for Patient';
      case 'READY_TO_COMPLETE':
        return 'Ready to Complete';
      case 'COMPLETED':
        return 'Completed';
      default:
        return 'Waiting';
    }
  }

  private getPrimaryActionLabel(stageCode: string, workflowType: string) {
    if (workflowType === 'PAYMENT') {
      return stageCode === 'COMPLETED' ? 'View payment' : 'Open billing';
    }
    switch (stageCode) {
      case 'ACCEPTED':
        return 'Start consultation';
      case 'CONSULTATION':
        return 'Continue care';
      case 'WAITING':
        return 'Open patient';
      case 'READY_TO_COMPLETE':
        return 'Finish visit';
      case 'COMPLETED':
        return 'View summary';
      default:
        return 'Open patient';
    }
  }

  private getPrimaryTargetTab(stageCode: string, workflowType: string) {
    if (workflowType === 'PAYMENT') {
      return 'payments';
    }
    switch (stageCode) {
      case 'ACCEPTED':
        return 'appointments';
      case 'CONSULTATION':
        return 'timeline';
      case 'READY_TO_COMPLETE':
        return 'timeline';
      case 'COMPLETED':
        return 'timeline';
      case 'WAITING':
      default:
        return 'overview';
    }
  }

  private getAppointmentStatusLabel(status?: string | null) {
    switch ((status ?? '').trim().toUpperCase()) {
      case 'PENDING':
        return 'Waiting';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'CHECKED_IN':
        return 'Checked In';
      case 'IN_PROGRESS':
        return 'Consultation in Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status?.replaceAll('_', ' ') ?? 'Appointment';
    }
  }

  private getBranchDisplayName(
    businessCode?: string | null,
    businessName?: string | null,
    providerName?: string | null,
    appointmentType?: string | null,
  ) {
    if (businessCode === 'HYP-PERINTHALMANNA') {
      return 'Sahakar Hyper Pharmacy - Perinthalmanna';
    }
    if (businessCode === 'HYP-MANJERI') {
      return 'Sahakar Hyper Pharmacy - Manjeri';
    }
    if (businessCode === 'SHG') {
      const combined = `${providerName ?? ''} ${appointmentType ?? ''}`.toUpperCase();
      if (combined.includes('DENT')) {
        return 'SHG Dental Care';
      }
      return 'SHG Medical Centre';
    }
    return businessName?.trim() ?? 'Branch not assigned';
  }

  private formatDateTime(value?: Date | null) {
    if (!value) {
      return 'Time not scheduled';
    }
    const day = value.getDate().toString().padStart(2, '0');
    const month = value.toLocaleString('en-US', { month: 'short' });
    const year = value.getFullYear();
    let hour = value.getHours() % 12;
    if (hour === 0) {
      hour = 12;
    }
    const minute = value.getMinutes().toString().padStart(2, '0');
    const suffix = value.getHours() >= 12 ? 'PM' : 'AM';
    return `${day} ${month} ${year} • ${hour}:${minute} ${suffix}`;
  }

  private formatCurrency(value: number) {
    return `Rs ${value.toLocaleString('en-IN', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    })}`;
  }

  private normalizeLimit(limit: number | undefined, fallback: number) {
    if (!limit || Number.isNaN(limit)) {
      return fallback;
    }
    return Math.min(Math.max(limit, 1), 25);
  }
}
