import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

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
};

@Injectable()
export class OperationsQueueService {
  constructor(private readonly prisma: PrismaService) {}

  async getProviderWorkspace(query: ProviderWorkspaceQuery) {
    const limit = this.normalizeLimit(query.limit, 8);
    const providerScope = await this.resolveProviderScope(query);
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

    return {
      generatedAt: now.toISOString(),
      workspace: 'provider',
      scope: {
        providerId: query.providerId?.toString() ?? null,
        providerType: query.providerType ?? null,
        businessId: query.businessId?.toString() ?? null,
        matchedProviderCount: providerScope.providers.length,
      },
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
          this.toAppointmentQueueItem(appointment),
        ),
        billing: recentPurchases.map((purchase) => this.toPurchaseQueueItem(purchase)),
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
          this.toAppointmentQueueItem(appointment),
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
  }): QueueItem {
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
      workflowType: 'APPOINTMENT',
      workflowLabel: 'Appointment',
      title: appointment.appointmentType || 'Appointment',
      subtitle: customerName || providerName,
      meta: `${branchName} • ${this.formatDateTime(appointment.appointmentDate)}`,
      status: appointment.status || 'PENDING',
      statusLabel: this.getAppointmentStatusLabel(appointment.status),
      stageCode,
      stageLabel: this.getStageLabel(stageCode, appointment.status),
      primaryActionLabel: this.getPrimaryActionLabel(stageCode, 'APPOINTMENT'),
      secondaryActionLabel: 'Open patient',
    };
  }

  private toPurchaseQueueItem(purchase: {
    id: bigint;
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
  }): QueueItem {
    const customerName =
      purchase.customer
        ? `${purchase.customer.firstName ?? ''} ${purchase.customer.lastName ?? ''}`.trim()
        : 'Customer not linked';
    const stageCode = Number(purchase.payableAmount ?? 0) > 0 ? 'WAITING_PAYMENT' : 'COMPLETED';
    return {
      kind: 'purchase',
      id: purchase.id.toString(),
      workflowType: 'PAYMENT',
      workflowLabel: 'Payment',
      title: purchase.invoiceNumber
        ? `Invoice ${purchase.invoiceNumber}`
        : `Invoice #${purchase.id.toString()}`,
      subtitle: `${customerName} • ${purchase.provider?.providerName || 'Provider'}`,
      meta: this.formatDateTime(purchase.purchaseDate),
      status: stageCode,
      statusLabel: this.formatCurrency(Number(purchase.payableAmount ?? 0)),
      stageCode,
      stageLabel: this.getStageLabel(stageCode, null),
      primaryActionLabel: this.getPrimaryActionLabel(stageCode, 'PAYMENT'),
      secondaryActionLabel: 'Open patient',
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
      return stageCode === 'COMPLETED' ? 'View payment' : 'Collect payment';
    }
    switch (stageCode) {
      case 'ACCEPTED':
        return 'Open patient';
      case 'CONSULTATION':
        return 'Continue care';
      case 'WAITING':
        return 'Check patient';
      case 'READY_TO_COMPLETE':
        return 'Complete visit';
      case 'COMPLETED':
        return 'View summary';
      default:
        return 'Open patient';
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
