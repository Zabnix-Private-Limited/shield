import { ForbiddenException, Injectable } from '@nestjs/common';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AuthService } from '../auth/auth.service';
import { AgentScopeService } from '../auth/agent-scope.service';
import { AppointmentService } from '../appointment/appointment.service';
import { CrmService } from '../crm/crm.service';
import { CustomerService } from '../customer/customer.service';
import { DocumentService } from '../document/document.service';
import { NotificationService } from '../notification/notification.service';
import { PrismaService } from '../prisma/prisma.service';
import { ReferralService } from '../referral/referral.service';
import { WalletService } from '../wallet/wallet.service';

@Injectable()
export class AgentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authService: AuthService,
    private readonly agentScopeService: AgentScopeService,
    private readonly customerService: CustomerService,
    private readonly walletService: WalletService,
    private readonly appointmentService: AppointmentService,
    private readonly documentService: DocumentService,
    private readonly notificationService: NotificationService,
    private readonly referralService: ReferralService,
    private readonly crmService: CrmService,
  ) {}

  async getWorkspace(principal?: ShieldPrincipal) {
    const context = await this.requireAgentContext(principal);
    const authProfile = await this.authService.getProfile(principal!);
    const today = new Date();
    const startOfToday = new Date(today);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(today);
    endOfToday.setHours(23, 59, 59, 999);
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    const customers = await this.prisma.customer.findMany({
      where: {
        agentCode: context.agentCode,
        deletedAt: null,
      },
      include: {
        membership: true,
        shieldCard: true,
      },
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      take: 24,
    });

    const customerIds = customers.map((customer) => customer.id);
    const [
      appointmentsToday,
      pendingRegistrations,
      monthlyCustomersAdded,
      monthlyActiveCustomers,
      pendingDocuments,
      tasks,
      activities,
      notifications,
      appointments,
      referralEvents,
    ] = await Promise.all([
      this.prisma.appointment.count({
        where: {
          customerId: { in: customerIds.length > 0 ? customerIds : [BigInt(-1)] },
          appointmentDate: { gte: startOfToday, lte: endOfToday },
        },
      }),
      this.prisma.customer.count({
        where: {
          agentCode: context.agentCode,
          deletedAt: null,
          status: { in: ['PENDING', 'INCOMPLETE', 'REJECTED'] },
        },
      }),
      this.prisma.customer.count({
        where: {
          agentCode: context.agentCode,
          deletedAt: null,
          createdAt: { gte: startOfMonth },
        },
      }),
      this.prisma.customer.count({
        where: {
          agentCode: context.agentCode,
          deletedAt: null,
          status: 'ACTIVE',
        },
      }),
      this.prisma.document.count({
        where: {
          customer: { agentCode: context.agentCode, deletedAt: null },
          NOT: { status: { in: ['APPROVED', 'VALIDATED'] } },
        },
      }),
      this.prisma.crmTask.findMany({
        where: {
          assignedTo: context.userId,
          customer: { agentCode: context.agentCode, deletedAt: null },
        },
        include: { customer: true },
        orderBy: [{ dueDate: 'asc' }, { id: 'desc' }],
        take: 12,
      }),
      this.prisma.crmActivity.findMany({
        where: {
          customer: { agentCode: context.agentCode, deletedAt: null },
        },
        include: { customer: true, createdByUser: true },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 10,
      }),
      this.prisma.notification.findMany({
        where: {
          customer: { agentCode: context.agentCode, deletedAt: null },
        },
        include: { customer: true },
        orderBy: [{ sentAt: 'desc' }, { id: 'desc' }],
        take: 10,
      }),
      this.prisma.appointment.findMany({
        where: {
          customerId: { in: customerIds.length > 0 ? customerIds : [BigInt(-1)] },
        },
        include: { customer: true, provider: true },
        orderBy: [{ appointmentDate: 'asc' }, { id: 'desc' }],
        take: 20,
      }),
      this.prisma.referralRewardEvent.findMany({
        where: {
          referrerCustomer: { agentCode: context.agentCode, deletedAt: null },
        },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 50,
      }),
    ]);

    const latestAppointmentByCustomer = new Map<string, Date>();
    const upcomingAppointmentByCustomer = new Map<string, Date>();
    for (const appointment of appointments) {
      if (!appointment.customerId || !appointment.appointmentDate) {
        continue;
      }
      const key = appointment.customerId.toString();
      const currentLatest = latestAppointmentByCustomer.get(key);
      if (!currentLatest || appointment.appointmentDate > currentLatest) {
        latestAppointmentByCustomer.set(key, appointment.appointmentDate);
      }
      if (appointment.appointmentDate >= today) {
        const currentUpcoming = upcomingAppointmentByCustomer.get(key);
        if (!currentUpcoming || appointment.appointmentDate < currentUpcoming) {
          upcomingAppointmentByCustomer.set(key, appointment.appointmentDate);
        }
      }
    }

    const referralCountByCustomer = new Map<string, number>();
    for (const event of referralEvents) {
      const key = event.referrerCustomerId.toString();
      referralCountByCustomer.set(key, (referralCountByCustomer.get(key) ?? 0) + 1);
    }

    const activeCustomerCount = customers.filter(
      (customer) => (customer.status ?? '').trim().toUpperCase() === 'ACTIVE',
    ).length;
    const retentionRate =
      customers.length === 0
        ? 0
        : Number(((activeCustomerCount / customers.length) * 100).toFixed(1));
    const completedFollowUps = tasks.filter(
      (task: any) => (task.status ?? '').trim().toUpperCase() === 'COMPLETED',
    ).length;
    const appointmentsGenerated = appointments.filter(
      (appointment: any) =>
        appointment.appointmentDate != null &&
        appointment.appointmentDate >= startOfMonth,
    ).length;
    const conversionRate =
      monthlyCustomersAdded === 0
        ? 0
        : Number(((monthlyActiveCustomers / monthlyCustomersAdded) * 100).toFixed(1));

    return {
      generatedAt: today.toISOString(),
      workspace: 'agent',
      agentContext: {
        agentCode: context.agentCode,
        agentName: context.displayName || 'SHIELD Agent',
        status: context.status,
      },
      summary: {
        totalCustomers: customers.length,
        todaysFollowUps: tasks.filter((task: any) => {
          if (!task.dueDate) {
            return false;
          }
          return task.dueDate >= startOfToday && task.dueDate <= endOfToday;
        }).length,
        pendingRegistrations,
        appointmentsToday,
        newReferrals:
            referralEvents.filter((event: any) => event.createdAt >= startOfMonth)
                .length,
        monthlyCustomersAdded,
        monthlyActiveCustomers,
        retentionRate,
        pendingDocuments,
        tasksOpen:
            tasks.filter(
              (task: any) =>
                  (task.status ?? '').trim().toUpperCase() !== 'COMPLETED',
            ).length,
        unreadNotifications: notifications.filter(
          (notification: any) =>
            (notification.status ?? '').trim().toUpperCase() !== 'READ',
        ).length,
      },
      performance: {
        customersAdded: monthlyCustomersAdded,
        customersActive: monthlyActiveCustomers,
        retentionRate,
        referrals: referralEvents.length,
        appointmentsGenerated,
        completedFollowUps,
        conversionRate,
        monthlyIncentives:
            referralEvents.filter(
              (event: any) =>
                  (event.status ?? '').trim().toUpperCase() === 'REWARDED',
            ).length,
      },
      customers: customers.map((customer) => ({
        id: customer.id.toString(),
        customerCode: customer.customerCode,
        fullName:
          `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
          'Customer',
        mobile: customer.mobile,
        status: customer.status ?? 'PENDING',
        cardStatus: customer.shieldCard?.status ?? 'PENDING',
        membershipStatus: customer.membership?.status ?? 'PENDING',
        referralCount: referralCountByCustomer.get(customer.id.toString()) ?? 0,
        lastVisitAt:
          latestAppointmentByCustomer.get(customer.id.toString())?.toISOString() ??
          null,
        upcomingAppointmentAt:
          upcomingAppointmentByCustomer
            .get(customer.id.toString())
            ?.toISOString() ?? null,
      })),
      tasks: tasks.map((task: any) => ({
        id: task.id.toString(),
        customerId: task.customerId?.toString() ?? null,
        customerName:
          `${task.customer?.firstName ?? ''} ${task.customer?.lastName ?? ''}`.trim() ||
          'Customer',
        dueDate: task.dueDate?.toISOString() ?? null,
        status: task.status ?? 'PENDING',
        notes: task.notes ?? '',
      })),
      notifications: notifications.map((notification: any) => ({
        id: notification.id.toString(),
        customerId: notification.customerId?.toString() ?? null,
        customerName:
          `${notification.customer?.firstName ?? ''} ${notification.customer?.lastName ?? ''}`.trim() ||
          'Customer',
        title: notification.title ?? 'Notification',
        message: notification.msg ?? '',
        status: notification.status ?? 'UNREAD',
        sentAt: notification.sentAt?.toISOString() ?? null,
      })),
      recentActivity: activities.map((activity: any) => ({
        id: activity.id.toString(),
        customerId: activity.customerId?.toString() ?? null,
        customerName:
          `${activity.customer?.firstName ?? ''} ${activity.customer?.lastName ?? ''}`.trim() ||
          'Customer',
        activityType: activity.activityType ?? 'FOLLOW_UP',
        notes: activity.notes ?? '',
        createdAt: activity.createdAt.toISOString(),
      })),
      upcomingAppointments: appointments
        .filter((appointment: any) => appointment.appointmentDate != null)
        .map((appointment: any) => ({
          id: appointment.id.toString(),
          customerId: appointment.customerId?.toString() ?? null,
          customerName:
            `${appointment.customer?.firstName ?? ''} ${appointment.customer?.lastName ?? ''}`.trim() ||
            'Customer',
          providerName: appointment.provider?.providerName ?? 'Provider',
          appointmentType: appointment.appointmentType ?? 'Appointment',
          appointmentDate: appointment.appointmentDate?.toISOString() ?? null,
          status: appointment.status ?? 'PENDING',
        })),
      authProfile,
    };
  }

  async getCustomerWorkspace(
    customerId: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessCustomer(customerId, principal);
    const tasksAssignedTo =
      principal?.userId != null ? BigInt(principal.userId) : undefined;

    const [
      customer,
      membership,
      wallet,
      documents,
      appointments,
      notifications,
      summary,
      tree,
      activities,
      tasks,
      contacts,
      purchases,
      consultations,
      labReports,
      dentalRecords,
      statusHistory,
    ] =
      await Promise.all([
        this.customerService.findOne(customerId),
        this.customerService.getCustomerPortalMembership(customerId),
        this.walletService.getCustomerWalletBundle(customerId),
        this.documentService.list(customerId, principal),
        this.appointmentService.list(customerId, principal),
        this.notificationService.list(customerId, principal),
        this.referralService.getReferralSummary(customerId),
        this.referralService.getReferralTree(customerId),
        this.crmService.listActivities(customerId),
        this.crmService.listTasks(customerId, tasksAssignedTo),
        this.prisma.customerContact.findMany({
          where: { customerId },
          orderBy: [{ isPrimary: 'desc' }, { id: 'asc' }],
        }),
        this.prisma.purchase.findMany({
          where: { customerId },
          include: {
            provider: true,
            purchaseItems: {
              include: {
                product: true,
              },
            },
          },
          orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
          take: 8,
        }),
        this.prisma.consultation.findMany({
          where: { customerId },
          include: {
            prescriptions: true,
          },
          orderBy: [{ appointmentId: 'desc' }, { id: 'desc' }],
          take: 8,
        }),
        this.prisma.labReport.findMany({
          where: { customerId },
          include: {
            document: true,
          },
          orderBy: [{ reportDate: 'desc' }, { id: 'desc' }],
          take: 8,
        }),
        this.prisma.dentalRecord.findMany({
          where: { customerId },
          orderBy: [{ id: 'desc' }],
          take: 8,
        }),
        this.prisma.customerStatusHistory.findMany({
          where: { customerId },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: 10,
        }),
      ]);

    const timeline = [
      ...activities.map((activity) => ({
        id: `activity:${activity.id.toString()}`,
        type: 'FOLLOW_UP',
        title: activity.activityType ?? 'Follow-up',
        description: activity.notes ?? '',
        timestamp: activity.createdAt.toISOString(),
        status: 'RECORDED',
      })),
      ...tasks.map((task) => ({
        id: `task:${task.id.toString()}`,
        type: 'TASK',
        title: task.status ?? 'Task',
        description: task.notes ?? '',
        timestamp:
          task.dueDate?.toISOString() ?? new Date(0).toISOString(),
        status: task.status ?? 'PENDING',
      })),
    ].sort((left, right) => right.timestamp.localeCompare(left.timestamp));

    const medicalRecords = [
      ...consultations.map((consultation: any) => ({
        id: `consultation:${consultation.id.toString()}`,
        category: 'Consultation',
        title: consultation.diagnosis?.trim() || 'Consultation note',
        date: consultation.appointmentId?.toString() ?? null,
        status: consultation.prescriptions?.length ? 'Prescription linked' : 'Recorded',
      })),
      ...labReports.map((report: any) => ({
        id: `lab:${report.id.toString()}`,
        category: 'Lab Report',
        title: report.document?.fileName ?? 'Laboratory report',
        date: report.reportDate?.toISOString() ?? null,
        status: 'Available',
      })),
      ...dentalRecords.map((record: any) => ({
        id: `dental:${record.id.toString()}`,
        category: 'Dental Record',
        title: record.treatmentName ?? 'Dental treatment',
        date: null,
        status: 'Recorded',
      })),
    ];

    return {
      generatedAt: new Date().toISOString(),
      customer,
      profile: {
        customerId: customer.id.toString(),
        customerCode: customer.customerCode,
        fullName:
          `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
          'Customer',
        mobile: customer.mobile,
        email: customer.email,
        gender: customer.gender,
        dob: customer.dob,
        status: customer.status,
        address: [customer.addressLine1, customer.addressLine2, customer.city]
          .filter(Boolean)
          .join(', '),
        agentCode: customer.agentCode,
        referralCode: customer.referralCode,
      },
      familyDetails: contacts.map((contact) => ({
        id: contact.id.toString(),
        name: contact.name ?? 'Family contact',
        relation: contact.relation ?? 'Relation not recorded',
        mobile: contact.mobile ?? '',
        isPrimary: Boolean(contact.isPrimary),
      })),
      membership,
      wallet,
      documents,
      appointments,
      notifications,
      referralSummary: summary,
      referralTree: tree,
      activities,
      tasks,
      purchases: purchases.map((purchase: any) => ({
        id: purchase.id.toString(),
        invoiceNumber: purchase.invoiceNumber,
        providerName: purchase.provider?.providerName ?? 'Provider',
        totalAmount: purchase.totalAmount,
        payableAmount: purchase.payableAmount,
        purchaseDate: purchase.purchaseDate?.toISOString() ?? null,
        paymentStatus: purchase.paymentStatus ?? 'PENDING',
        itemCount: purchase.purchaseItems?.length ?? 0,
      })),
      medicalRecords,
      statusHistory: statusHistory.map((entry) => ({
        id: entry.id.toString(),
        oldStatus: entry.oldStatus,
        newStatus: entry.newStatus,
        remarks: entry.remarks,
        createdAt: entry.createdAt.toISOString(),
      })),
      quickActions: [
        { key: 'followup', label: 'Schedule follow-up', enabled: true },
        { key: 'appointment', label: 'Book appointment', enabled: true },
        { key: 'document', label: 'Upload document', enabled: true },
        { key: 'customer', label: 'Update customer details', enabled: true },
      ],
      timeline,
    };
  }

  async getCurrentProfile(principal?: ShieldPrincipal) {
    await this.requireAgentContext(principal);
    return this.authService.getProfile(principal!);
  }

  async updateCurrentProfile(principal: ShieldPrincipal | undefined, data: any) {
    const context = await this.requireAgentContext(principal);
    const updated = await this.prisma.user.update({
      where: { id: context.userId },
      data: {
        firstName: data.first_name ?? data.firstName,
        lastName: data.last_name ?? data.lastName,
        mobile: data.mobile,
        email: data.email,
      },
    });

    return {
      id: updated.id.toString(),
      firstName: updated.firstName,
      lastName: updated.lastName,
      mobile: updated.mobile,
      email: updated.email,
      employeeCode: updated.employeeCode,
      status: updated.status,
    };
  }

  private async requireAgentContext(principal?: ShieldPrincipal) {
    const context = await this.agentScopeService.resolveAgentContext(principal);
    if (!context) {
      throw new ForbiddenException('Only SHIELD agents can access this workspace.');
    }
    return context;
  }
}
