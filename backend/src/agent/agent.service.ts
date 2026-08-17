import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AuthService } from '../auth/auth.service';
import { AgentScopeService } from '../auth/agent-scope.service';
import { AppointmentService } from '../appointment/appointment.service';
import { CrmService } from '../crm/crm.service';
import { CustomerService } from '../customer/customer.service';
import { DocumentService } from '../document/document.service';
import { NotificationService } from '../notification/notification.service';
import { PlatformPrintService } from '../platform-capabilities/platform-print.service';
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
    private readonly platformPrintService: PlatformPrintService,
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
          customerId: {
            in: customerIds.length > 0 ? customerIds : [BigInt(-1)],
          },
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
          customerId: {
            in: customerIds.length > 0 ? customerIds : [BigInt(-1)],
          },
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
      referralCountByCustomer.set(
        key,
        (referralCountByCustomer.get(key) ?? 0) + 1,
      );
    }

    const directCustomerIds = customerIds;
    const childCustomers = directCustomerIds.length > 0
      ? await this.prisma.customer.findMany({
          where: {
            deletedAt: null,
            referredById: { in: directCustomerIds },
          },
          include: {
            membership: true,
            shieldCard: true,
            referredBy: {
              select: { id: true, customerCode: true, firstName: true, lastName: true },
            },
          },
          orderBy: [{ createdAt: 'desc' }],
        })
      : [];

    const directActiveCount = customers.filter(
      (c) => c.membership?.status?.toUpperCase() === 'ACTIVE',
    ).length;
    const childActiveCount = childCustomers.filter(
      (c) => c.membership?.status?.toUpperCase() === 'ACTIVE',
    ).length;

    const directRegCount = customers.length;
    const childRegCount = childCustomers.length;

    const directActiveEarnings = directActiveCount * 250;
    const directRegEarnings = directRegCount * 50;
    const childActiveEarnings = childActiveCount * 100;
    const childRegEarnings = childRegCount * 30;

    const totalNetworkEarnings =
      directActiveEarnings +
      directRegEarnings +
      childActiveEarnings +
      childRegEarnings;

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
        : Number(
            ((monthlyActiveCustomers / monthlyCustomersAdded) * 100).toFixed(1),
          );

    const statusCounts: Record<string, number> = {};
    for (const c of [...customers, ...childCustomers]) {
      const st = (c.status || 'ACTIVE').toUpperCase();
      statusCounts[st] = (statusCounts[st] || 0) + 1;
    }

    const agentTreeChildren = customers.map((c) => {
      const childrenOfC = childCustomers
        .filter((child) => child.referredById === c.id)
        .map((child) => ({
          id: child.id.toString(),
          name: `${child.firstName || ''} ${child.lastName || ''}`.trim() || 'Child Customer',
          code: child.customerCode || 'N/A',
          role: 'CHILD_REFERRAL',
          status: child.status || 'ACTIVE',
          membershipStatus: child.membership?.status || 'NO_MEMBERSHIP',
          parentName: `${c.firstName || ''} ${c.lastName || ''}`.trim(),
          parentCode: c.customerCode || '',
          joinedAt: child.createdAt ? child.createdAt.toISOString() : null,
        }));

      return {
        id: c.id.toString(),
        name: `${c.firstName || ''} ${c.lastName || ''}`.trim() || 'Customer',
        code: c.customerCode || 'N/A',
        role: 'DIRECT_CUSTOMER',
        status: c.status || 'ACTIVE',
        membershipStatus: c.membership?.status || 'NO_MEMBERSHIP',
        children: childrenOfC,
        joinedAt: c.createdAt ? c.createdAt.toISOString() : null,
      };
    });

    const referralSummary = {
      directReferrals: customers.length,
      totalReferrals: customers.length + childCustomers.length,
      activeMemberships: directActiveCount + childActiveCount,
      availablePoints: referralEvents.length * 50,
      earnedPoints: totalNetworkEarnings,
      earnedEarningsFormatted: `₹${totalNetworkEarnings.toLocaleString('en-IN')}`,
      referralCode: context.agentCode,
      referralLink: `https://shield-zabnix.vercel.app/#/customer/register?ref=${context.agentCode}`,
      statuses: statusCounts,
      formulaText: `₹250 × ${directActiveCount} (Direct Active) + ₹50 × ${directRegCount} (Direct Cust) + ₹100 × ${childActiveCount} (Child Active) + ₹30 × ${childRegCount} (Child Cust)`,
      history: referralEvents.slice(0, 15).map((e) => ({
        id: e.id.toString(),
        title: 'Referral Event',
        status: e.status,
        points: e.rewardPoints,
        date: e.createdAt ? e.createdAt.toISOString() : null,
      })),
    };

    const referralTree = {
      id: context.agentCode,
      name: context.displayName || 'SHIELD Agent',
      code: context.agentCode,
      role: 'AGENT',
      status: 'ACTIVE',
      children: agentTreeChildren,
    };

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
        newReferrals: referralEvents.filter(
          (event: any) => event.createdAt >= startOfMonth,
        ).length,
        monthlyCustomersAdded,
        monthlyActiveCustomers,
        retentionRate,
        pendingDocuments,
        tasksOpen: tasks.filter(
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
        monthlyIncentives: referralEvents.filter(
          (event: any) =>
            (event.status ?? '').trim().toUpperCase() === 'REWARDED',
        ).length,
      },
      referralSummary,
      referralTree,
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
          latestAppointmentByCustomer
            .get(customer.id.toString())
            ?.toISOString() ?? null,
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

  async listCustomers(
    principal: ShieldPrincipal | undefined,
    options: {
      query?: string;
      status?: string;
      membershipStatus?: string;
      page?: number;
      pageSize?: number;
    } = {},
  ) {
    const context = await this.requireAgentContext(principal);
    const query = options.query?.trim();
    const status = options.status?.trim().toUpperCase();
    const membershipStatus = options.membershipStatus?.trim().toUpperCase();
    const page = Number.isFinite(options.page) ? Math.max(1, options.page!) : 1;
    const pageSize = Number.isFinite(options.pageSize)
      ? Math.min(100, Math.max(1, options.pageSize!))
      : 25;
    const where = {
      agentCode: context.agentCode,
      deletedAt: null,
      ...(status ? { status } : {}),
      ...(membershipStatus ? { membership: { status: membershipStatus } } : {}),
      ...(query
        ? {
            OR: [
              { firstName: { contains: query, mode: 'insensitive' as const } },
              { lastName: { contains: query, mode: 'insensitive' as const } },
              { mobile: { contains: query, mode: 'insensitive' as const } },
              { customerCode: { contains: query, mode: 'insensitive' as const } },
            ],
          }
        : {}),
    };
    const [total, customers] = await this.prisma.$transaction([
      this.prisma.customer.count({ where }),
      this.prisma.customer.findMany({
        where,
        include: { membership: true, shieldCard: true },
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    return {
      items: customers.map((customer) => ({
        id: customer.id.toString(),
        customerCode: customer.customerCode,
        fullName:
          `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
          'Customer',
        mobile: customer.mobile,
        status: customer.status ?? 'PENDING',
        cardStatus: customer.shieldCard?.status ?? 'PENDING',
        membershipStatus: customer.membership?.status ?? 'PENDING',
      })),
      page,
      pageSize,
      total,
      totalPages: Math.max(1, Math.ceil(total / pageSize)),
    };
  }

  async getCustomerWorkspace(customerId: bigint, principal?: ShieldPrincipal) {
    await this.agentScopeService.assertAgentCanAccessCustomer(
      customerId,
      principal,
    );
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
      managementActivities,
      tasks,
      contacts,
      purchases,
      consultations,
      labReports,
      dentalRecords,
      statusHistory,
      pharmacyRequests,
      addresses,
      preferences,
    ] = await Promise.all([
      this.customerService.findOne(customerId),
      this.customerService.getCustomerPortalMembership(customerId),
      this.walletService.getCustomerWalletBundle(customerId),
      this.documentService.list(customerId, principal, 12),
      this.appointmentService.list(customerId, principal, 12),
      this.notificationService.list(customerId, principal, 12),
      this.referralService.getReferralSummary(customerId),
      this.referralService.getReferralTree(customerId),
      this.crmService.listActivities(customerId),
      this.prisma.activityEvent
        .findMany({
          where: { customerId },
          orderBy: { createdAt: 'desc' },
          take: 30,
        })
        // ponytail: legacy databases lack this prepared table; remove once migration is mandatory.
        .catch(() => []),
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
      this.prisma.prescriptionPharmacyRequest.findMany({
        where: { customerId },
        include: { provider: true },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 20,
      }),
      this.prisma.customerAddress.findMany({
        where: { customerId, deletedAt: null },
        orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
      }),
      this.prisma.customerPreference.findUnique({ where: { customerId } }),
    ]);

    const preferredProvider = preferences?.preferredProviderId
      ? await this.prisma.serviceProvider.findUnique({
          where: { id: preferences.preferredProviderId },
          select: { providerName: true, providerType: true, status: true },
        })
      : null;

    const timeline = [
      ...activities.map((activity) => ({
        id: `activity:${activity.id.toString()}`,
        type: 'FOLLOW_UP',
        title: activity.activityType ?? 'Follow-up',
        description: activity.notes ?? '',
        timestamp: activity.createdAt.toISOString(),
        status: 'RECORDED',
      })),
      ...managementActivities.map((activity) => ({
        id: `management:${activity.id.toString()}`,
        type: activity.activityType,
        title: activity.activityType,
        description: activity.description,
        timestamp: activity.createdAt.toISOString(),
        status: activity.status,
      })),
      ...tasks.map((task) => ({
        id: `task:${task.id.toString()}`,
        type: 'TASK',
        title: task.status ?? 'Task',
        description: task.notes ?? '',
        timestamp: task.dueDate?.toISOString() ?? new Date(0).toISOString(),
        status: task.status ?? 'PENDING',
      })),
    ].sort((left, right) => right.timestamp.localeCompare(left.timestamp));

    const medicalRecords = [
      ...consultations.map((consultation: any) => ({
        id: `consultation:${consultation.id.toString()}`,
        category: 'Consultation',
        title: consultation.diagnosis?.trim() || 'Consultation note',
        date: consultation.appointmentId?.toString() ?? null,
        status: consultation.prescriptions?.length
          ? 'Prescription linked'
          : 'Recorded',
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

    const printing = this.buildAgentCustomerPrintContext({
      customer,
      membership,
      wallet,
      summary,
      tree,
      appointments,
      purchases,
      documents,
    });

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
      addresses: addresses.map((address) => ({
        id: address.id.toString(),
        label: address.label,
        addressLine1: address.addressLine1,
        addressLine2: address.addressLine2,
        city: address.city,
        district: address.district,
        state: address.state,
        pincode: address.pincode,
        isDefault: address.isDefault,
      })),
      preferredProvider: preferredProvider
        ? {
            name: preferredProvider.providerName,
            type: preferredProvider.providerType,
            status: preferredProvider.status,
          }
        : null,
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
      prescriptions: consultations.flatMap((consultation: any) =>
        (consultation.prescriptions ?? []).map((prescription: any) => ({
          id: prescription.id.toString(),
          consultationId: consultation.id.toString(),
          documentId: prescription.documentId?.toString() ?? null,
          issueDate: prescription.issueDate?.toISOString() ?? null,
          diagnosis: consultation.diagnosis?.trim() || null,
        })),
      ),
      pharmacyRequests: pharmacyRequests.map((request: any) => ({
        id: request.id.toString(),
        documentId: request.documentId.toString(),
        providerName: request.provider?.providerName ?? 'Pharmacy provider',
        status: request.status ?? 'SUBMITTED',
        createdAt: request.createdAt.toISOString(),
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
        { key: 'print', label: 'Print customer summary', enabled: true },
      ],
      printing,
      timeline,
    };
  }

  async getCurrentProfile(principal?: ShieldPrincipal) {
    const context = await this.resolveCurrentAgentUserContext(principal);
    const profile = await this.authService.getProfile(principal!);
    return {
      ...profile,
      settings: await this.buildCurrentAgentPreferenceResponse(context.user),
    };
  }

  async updateCurrentProfile(
    principal: ShieldPrincipal | undefined,
    data: any,
  ) {
    const context = await this.resolveCurrentAgentUserContext(principal);
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

  async getCurrentPreferences(principal?: ShieldPrincipal) {
    const context = await this.resolveCurrentAgentUserContext(principal);
    return this.buildCurrentAgentPreferenceResponse(context.user);
  }

  async updateCurrentPreferences(
    principal: ShieldPrincipal | undefined,
    data: any,
  ) {
    const context = await this.resolveCurrentAgentUserContext(principal);
    const normalized = await this.normalizeAgentPreferenceInput(
      data,
      context.user,
    );

    const user = await this.prisma.$transaction(async (tx) => {
      await tx.agentPreference.upsert({
        where: { userId: context.user.id },
        update: {
          themePreference: normalized.themePreference,
          languagePreference: normalized.languagePreference,
          timezone: normalized.timezone,
          availability: normalized.availability,
          workingHours: normalized.workingHours,
          workingArea: normalized.workingArea,
          emergencyContact: normalized.emergencyContact,
          notificationPreferences: normalized.notificationPreferences,
          dashboardLayout: normalized.dashboardLayout,
          profilePreferences: normalized.profilePreferences,
          devicePreferences: normalized.devicePreferences,
        },
        create: {
          uuid: randomUUID(),
          userId: context.user.id,
          themePreference: normalized.themePreference,
          languagePreference: normalized.languagePreference,
          timezone: normalized.timezone,
          availability: normalized.availability,
          workingHours: normalized.workingHours,
          workingArea: normalized.workingArea,
          emergencyContact: normalized.emergencyContact,
          notificationPreferences: normalized.notificationPreferences,
          dashboardLayout: normalized.dashboardLayout,
          profilePreferences: normalized.profilePreferences,
          devicePreferences: normalized.devicePreferences,
        },
      });

      if (normalized.requestedBranchId != null) {
        const existing = await tx.agentBranchAssignment.findUnique({
          where: {
            userId_businessId: {
              userId: context.user.id,
              businessId: normalized.requestedBranchId,
            },
          },
        });

        const sameAsCurrentPrimary =
          context.user.branchBusinessId != null &&
          context.user.branchBusinessId === normalized.requestedBranchId;
        const nextStatus = sameAsCurrentPrimary
          ? 'ASSIGNED'
          : 'REGIONAL_APPROVAL';

        await tx.agentBranchAssignment.upsert({
          where: {
            userId_businessId: {
              userId: context.user.id,
              businessId: normalized.requestedBranchId,
            },
          },
          update: {
            status: nextStatus,
            isPrimary: sameAsCurrentPrimary,
            approvedAt:
              nextStatus === 'ASSIGNED'
                ? (existing?.approvedAt ?? new Date())
                : (existing?.approvedAt ?? null),
            requestedAt: existing?.requestedAt ?? new Date(),
            transferredAt:
              nextStatus === 'REGIONAL_APPROVAL'
                ? new Date()
                : (existing?.transferredAt ?? null),
            inactiveAt: null,
            notes: normalized.branchNotes,
          },
          create: {
            uuid: randomUUID(),
            userId: context.user.id,
            businessId: normalized.requestedBranchId,
            status: nextStatus,
            isPrimary: sameAsCurrentPrimary,
            approvedAt: nextStatus === 'ASSIGNED' ? new Date() : null,
            transferredAt:
              nextStatus === 'REGIONAL_APPROVAL' ? new Date() : null,
            notes: normalized.branchNotes,
          },
        });

        if (sameAsCurrentPrimary) {
          await tx.agentBranchAssignment.updateMany({
            where: {
              userId: context.user.id,
              businessId: { not: normalized.requestedBranchId },
              isPrimary: true,
            },
            data: {
              isPrimary: false,
              status: 'TRANSFERRED',
              transferredAt: new Date(),
            },
          });
        }
      }

      return tx.user.findUnique({
        where: { id: context.user.id },
        include: this.agentProfileInclude(),
      });
    });

    return this.buildCurrentAgentPreferenceResponse(user);
  }

  private async requireAgentContext(principal?: ShieldPrincipal) {
    const context = await this.agentScopeService.resolveAgentContext(principal);
    if (!context) {
      throw new ForbiddenException(
        'Only SHIELD agents can access this workspace.',
      );
    }
    return context;
  }

  private agentProfileInclude() {
    return {
      role: true,
      department: true,
      branchBusiness: true,
      agentPreference: true,
      agentBranchAssignments: {
        include: {
          business: true,
        },
        orderBy: [{ requestedAt: 'desc' as const }, { id: 'desc' as const }],
      },
    };
  }

  private async resolveCurrentAgentUserContext(principal?: ShieldPrincipal) {
    const context = await this.requireAgentContext(principal);
    if (!principal?.userId) {
      throw new UnauthorizedException(
        'Authenticated agent context is required.',
      );
    }
    const user = await this.prisma.user.findUnique({
      where: { id: BigInt(principal.userId) },
      include: this.agentProfileInclude(),
    });
    if (!user) {
      throw new NotFoundException('Agent account not found.');
    }
    return {
      ...context,
      user,
    };
  }

  private async buildCurrentAgentPreferenceResponse(user: any) {
    if (!user) {
      throw new NotFoundException('Agent account not found.');
    }

    const preference = user.agentPreference;
    const activeBusinesses = await this.prisma.business.findMany({
      where: { status: 'ACTIVE' },
      orderBy: [{ name: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        name: true,
        businessType: true,
        status: true,
      },
    });

    const assignments = (user.agentBranchAssignments ?? []).map(
      (assignment: any) => ({
        id: assignment.id.toString(),
        businessId: assignment.businessId.toString(),
        status: assignment.status ?? 'PENDING',
        isPrimary: assignment.isPrimary === true,
        requestedAt: assignment.requestedAt?.toISOString() ?? null,
        approvedAt: assignment.approvedAt?.toISOString() ?? null,
        transferredAt: assignment.transferredAt?.toISOString() ?? null,
        inactiveAt: assignment.inactiveAt?.toISOString() ?? null,
        notes: assignment.notes ?? null,
        business: assignment.business
          ? {
              id: assignment.business.id.toString(),
              uuid: assignment.business.uuid,
              code: assignment.business.code,
              name: assignment.business.name,
              businessType: assignment.business.businessType,
              status: assignment.business.status,
            }
          : null,
      }),
    );

    const currentPrimary =
      assignments.find(
        (assignment: any) =>
          assignment.isPrimary === true && assignment.status === 'ASSIGNED',
      ) ?? null;
    const requestedBranch =
      assignments.find(
        (assignment: any) =>
          assignment.status === 'REGIONAL_APPROVAL' ||
          assignment.status === 'PENDING',
      ) ?? null;
    const fullName = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();

    return {
      preferenceId: preference?.id?.toString(),
      userId: user.id.toString(),
      profile: {
        id: user.id.toString(),
        firstName: user.firstName,
        lastName: user.lastName,
        mobile: user.mobile,
        email: user.email,
        employeeCode: user.employeeCode,
        status: user.status,
      },
      display: {
        fullName:
          fullName.length > 0 ? fullName : (user.email ?? 'SHIELD Agent'),
        designation: user.role?.name ?? 'SHIELD Agent',
        employeeCode: user.employeeCode,
        branch:
          user.branchBusiness == null
            ? null
            : {
                id: user.branchBusiness.id.toString(),
                code: user.branchBusiness.code,
                name: user.branchBusiness.name,
                status: user.branchBusiness.status,
                businessType: user.branchBusiness.businessType,
              },
      },
      preferences: {
        theme: preference?.themePreference ?? 'system',
        language: preference?.languagePreference ?? 'en',
        timezone: preference?.timezone ?? 'Asia/Calcutta',
        availability: this.normalizeStoredObject(preference?.availability, {
          mode: 'FIELD',
          availableForAssignments: true,
          status: 'ACTIVE',
        }),
        workingHours: this.normalizeStoredObject(preference?.workingHours, {
          startTime: '09:00',
          endTime: '18:00',
          workingDays: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
        }),
        workingArea: this.normalizeStoredObject(preference?.workingArea, {
          label: user.branchBusiness?.name ?? '',
          district: '',
          travelRadiusKm: 15,
        }),
        emergencyContact: this.normalizeStoredObject(
          preference?.emergencyContact,
          {
            name: '',
            phone: '',
            relation: '',
          },
        ),
        notifications: this.normalizeStoredObject(
          preference?.notificationPreferences,
          {
            followUpReminders: true,
            appointmentChanges: true,
            referralUpdates: true,
            membershipReminders: true,
          },
        ),
        dashboardLayout: this.normalizeStoredObject(
          preference?.dashboardLayout,
          {
            defaultView: 'overview',
          },
        ),
        profilePreferences: this.normalizeStoredObject(
          preference?.profilePreferences,
          {
            showCustomerCodes: true,
            showMembershipBadges: true,
          },
        ),
        devicePreferences: this.normalizeStoredObject(
          preference?.devicePreferences,
          {
            preferredDeviceLabel: '',
            allowPushNotifications: true,
          },
        ),
      },
      branchLifecycle: {
        currentBranch:
          currentPrimary ??
          (user.branchBusiness == null
            ? null
            : {
                businessId: user.branchBusiness.id.toString(),
                status: 'ASSIGNED',
                isPrimary: true,
                business: {
                  id: user.branchBusiness.id.toString(),
                  uuid: user.branchBusiness.uuid,
                  code: user.branchBusiness.code,
                  name: user.branchBusiness.name,
                  businessType: user.branchBusiness.businessType,
                  status: user.branchBusiness.status,
                },
              }),
        requestedBranch,
        assignments,
      },
      lookups: {
        branches: activeBusinesses.map((business) => ({
          id: business.id.toString(),
          uuid: business.uuid,
          code: business.code,
          name: business.name,
          businessType: business.businessType,
          status: business.status,
        })),
        branchStatuses: [
          'PENDING',
          'REGIONAL_APPROVAL',
          'ASSIGNED',
          'TRANSFERRED',
          'INACTIVE',
        ],
      },
      updatedAt: preference?.updatedAt?.toISOString() ?? null,
    };
  }

  private async normalizeAgentPreferenceInput(data: any, user: any) {
    const preferences = this.normalizeObject(data?.preferences);
    const requestedBranchId = this.normalizeOptionalBigInt(
      data?.requestedBranchId ??
        data?.branchLifecycle?.requestedBranch?.businessId ??
        data?.branchRequest?.businessId ??
        data?.primaryBranchId,
    );
    if (requestedBranchId != null) {
      const branch = await this.prisma.business.findUnique({
        where: { id: requestedBranchId },
        select: { id: true, status: true },
      });
      if (!branch || (branch.status ?? 'ACTIVE') !== 'ACTIVE') {
        throw new BadRequestException('Selected branch is invalid.');
      }
    }

    return {
      themePreference: this.normalizeOptionalText(
        preferences['theme'] ??
          data?.themePreference ??
          user.agentPreference?.themePreference,
      ),
      languagePreference: this.normalizeOptionalText(
        preferences['language'] ??
          data?.languagePreference ??
          user.agentPreference?.languagePreference,
      ),
      timezone: this.normalizeOptionalText(
        preferences['timezone'] ??
          data?.timezone ??
          user.agentPreference?.timezone,
      ),
      availability: this.normalizeObject(
        preferences['availability'] ??
          data?.availability ??
          user.agentPreference?.availability,
      ),
      workingHours: this.normalizeObject(
        preferences['workingHours'] ??
          data?.workingHours ??
          user.agentPreference?.workingHours,
      ),
      workingArea: this.normalizeObject(
        preferences['workingArea'] ??
          data?.workingArea ??
          user.agentPreference?.workingArea,
      ),
      emergencyContact: this.normalizeObject(
        preferences['emergencyContact'] ??
          data?.emergencyContact ??
          user.agentPreference?.emergencyContact,
      ),
      notificationPreferences: this.normalizeObject(
        preferences['notifications'] ??
          data?.notificationPreferences ??
          user.agentPreference?.notificationPreferences,
      ),
      dashboardLayout: this.normalizeObject(
        preferences['dashboardLayout'] ??
          data?.dashboardLayout ??
          user.agentPreference?.dashboardLayout,
      ),
      profilePreferences: this.normalizeObject(
        preferences['profilePreferences'] ??
          data?.profilePreferences ??
          user.agentPreference?.profilePreferences,
      ),
      devicePreferences: this.normalizeObject(
        preferences['devicePreferences'] ??
          data?.devicePreferences ??
          user.agentPreference?.devicePreferences,
      ),
      requestedBranchId,
      branchNotes: this.normalizeOptionalText(
        data?.branchNotes ??
          data?.branchLifecycle?.requestedBranch?.notes ??
          data?.branchRequest?.notes,
      ),
    };
  }

  private normalizeOptionalText(value: unknown) {
    if (value == null) {
      return null;
    }
    const normalized = value.toString().trim();
    return normalized.length === 0 ? null : normalized;
  }

  private normalizeOptionalBigInt(value: unknown) {
    if (value == null || value.toString().trim().length === 0) {
      return null;
    }
    try {
      return BigInt(value.toString());
    } catch (_) {
      throw new BadRequestException('Invalid identifier received.');
    }
  }

  private normalizeObject(
    value: unknown,
    fallback: Record<string, any> = {},
  ): Record<string, any> {
    if (value == null || typeof value !== 'object' || Array.isArray(value)) {
      return { ...fallback };
    }
    return { ...fallback, ...(value as Record<string, any>) };
  }

  private normalizeStoredObject(
    value: unknown,
    fallback: Record<string, any> = {},
  ): Record<string, any> {
    return this.normalizeObject(value, fallback);
  }

  private buildAgentCustomerPrintContext(input: {
    customer: any;
    membership: any;
    wallet: any;
    summary: any;
    tree: any;
    appointments: any[];
    purchases: any[];
    documents: any[];
  }) {
    const customer = input.customer ?? {};
    const membership = input.membership ?? {};
    const membershipSummary = membership['membership'] ?? {};
    const shieldCard = membership['shieldCard'] ?? {};
    const wallet = input.wallet ?? {};
    const referralSummary = input.summary ?? {};
    const latestAppointment = (input.appointments ?? [])
      .map((appointment: any) => ({
        ...appointment,
        appointmentDate: appointment?.appointmentDate
          ? new Date(appointment.appointmentDate)
          : null,
      }))
      .filter((appointment: any) => appointment.appointmentDate != null)
      .sort(
        (left: any, right: any) =>
          (right.appointmentDate as Date).getTime() -
          (left.appointmentDate as Date).getTime(),
      )[0];
    const latestPurchase = (input.purchases ?? [])[0] ?? null;
    const latestDocument = (input.documents ?? [])[0] ?? null;

    const templates = [
      'PATIENT_SUMMARY',
      'MEMBERSHIP_CERTIFICATE',
      'MEMBERSHIP_CARD',
      'REGISTRATION_RECEIPT',
      'REFERRAL_FORM',
      'APPOINTMENT_SLIP',
      'PAYMENT_RECEIPT',
    ]
      .map((id) => this.platformPrintService.getTemplate(id))
      .filter((template) => template != null);

    return {
      title: 'Shared print engine',
      description:
        'Reusable patient, membership, referral, appointment, and receipt print payloads.',
      templates,
      payloads: {
        PATIENT_SUMMARY: {
          customerId: customer.id?.toString(),
          documentTitle: 'Customer Summary',
          fileName: `customer-summary-${customer.customerCode ?? customer.id ?? 'record'}.pdf`,
          patient: {
            id: customer.id?.toString(),
            name:
              `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
              'SHIELD Member',
            patientId: customer.customerCode ?? customer.id?.toString() ?? '',
            mobile: customer.mobile ?? '',
            membershipNumber: membershipSummary.membershipNumber ?? '',
            shieldCardNumber: shieldCard.cardNumber ?? '',
          },
          summary: {
            status: customer.status ?? 'PENDING',
            membershipStatus: membershipSummary.status ?? 'PENDING',
            cardStatus: shieldCard.status ?? 'PENDING',
            walletBalance: wallet['cashWallet']?.['available'] ?? 0,
            rewardPoints: wallet['rewardPoints']?.['available'] ?? 0,
          },
          sections: [
            {
              title: 'Customer Snapshot',
              rows: [
                {
                  label: 'Membership',
                  value:
                    membershipSummary['membershipType']?.['name'] ??
                    membershipSummary['membershipNumber'] ??
                    'Pending',
                },
                {
                  label: 'Referral Code',
                  value: customer.referralCode ?? 'Not issued',
                },
                {
                  label: 'Direct Referrals',
                  value: `${referralSummary['directReferrals'] ?? 0}`,
                },
              ],
            },
          ],
        },
        MEMBERSHIP_CERTIFICATE: {
          customerId: customer.id?.toString(),
          documentTitle: 'Membership Certificate',
          fileName: `membership-certificate-${membershipSummary['membershipNumber'] ?? customer.customerCode ?? 'member'}.pdf`,
          patient: {
            id: customer.id?.toString(),
            name:
              `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
              'SHIELD Member',
            patientId: customer.customerCode ?? '',
            mobile: customer.mobile ?? '',
            membershipNumber: membershipSummary.membershipNumber ?? '',
          },
          summary: {
            membershipType:
              membershipSummary['membershipType']?.['name'] ?? 'Standard',
            membershipStatus: membershipSummary.status ?? 'PENDING',
            activationDate: membershipSummary.activationDate?.toString() ?? '',
            expiryDate: membershipSummary.expiryDate?.toString() ?? '',
          },
        },
        MEMBERSHIP_CARD: {
          customerId: customer.id?.toString(),
          documentTitle: 'Membership Card',
          fileName: `membership-card-${shieldCard.cardNumber ?? customer.customerCode ?? 'card'}.pdf`,
          patient: {
            id: customer.id?.toString(),
            name:
              `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
              'SHIELD Member',
            patientId: customer.customerCode ?? '',
            membershipNumber: membershipSummary.membershipNumber ?? '',
            shieldCardNumber: shieldCard.cardNumber ?? '',
          },
          summary: {
            cardStatus: shieldCard.status ?? 'PENDING',
            qrCode: shieldCard.qrCode ?? '',
          },
        },
        REGISTRATION_RECEIPT: {
          customerId: customer.id?.toString(),
          documentTitle: 'Registration Receipt',
          fileName: `registration-receipt-${customer.customerCode ?? customer.id ?? 'registration'}.pdf`,
          patient: {
            id: customer.id?.toString(),
            name:
              `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
              'SHIELD Member',
            patientId: customer.customerCode ?? '',
            mobile: customer.mobile ?? '',
          },
          summary: {
            registrationStatus: customer.status ?? 'PENDING',
            createdAt: customer.createdAt?.toString() ?? '',
            latestDocument: latestDocument?.fileName ?? 'No uploads yet',
          },
        },
        REFERRAL_FORM: {
          customerId: customer.id?.toString(),
          documentTitle: 'Referral Summary',
          fileName: `referral-summary-${customer.customerCode ?? customer.id ?? 'referral'}.pdf`,
          patient: {
            id: customer.id?.toString(),
            name:
              `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
              'SHIELD Member',
            patientId: customer.customerCode ?? '',
            mobile: customer.mobile ?? '',
            membershipNumber: membershipSummary.membershipNumber ?? '',
          },
          summary: {
            referralCode: customer.referralCode ?? '',
            directReferrals: referralSummary['directReferrals'] ?? 0,
            totalReferrals: referralSummary['totalReferrals'] ?? 0,
            availablePoints: referralSummary['availablePoints'] ?? 0,
          },
          sections: [
            {
              title: 'Referral Status',
              rows: [
                {
                  label: 'Qualified Network',
                  value: `${referralSummary['statuses']?.['QUALIFIED'] ?? 0}`,
                },
                {
                  label: 'Rewarded Referrals',
                  value: `${referralSummary['statuses']?.['REWARDED'] ?? 0}`,
                },
                {
                  label: 'Pending Referrals',
                  value: `${referralSummary['statuses']?.['PENDING'] ?? 0}`,
                },
              ],
            },
          ],
        },
        APPOINTMENT_SLIP: {
          customerId: customer.id?.toString(),
          appointmentId: latestAppointment?.id?.toString(),
          documentTitle: 'Appointment Slip',
          fileName: `appointment-slip-${latestAppointment?.id ?? customer.customerCode ?? 'appointment'}.pdf`,
          patient: {
            id: customer.id?.toString(),
            name:
              `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
              'SHIELD Member',
            patientId: customer.customerCode ?? '',
            mobile: customer.mobile ?? '',
          },
          summary: {
            appointmentType:
              latestAppointment?.appointmentType ?? 'No appointment booked',
            appointmentDate:
              latestAppointment?.appointmentDate?.toISOString() ?? '',
            appointmentStatus: latestAppointment?.status ?? 'PENDING',
          },
        },
        PAYMENT_RECEIPT: {
          customerId: customer.id?.toString(),
          documentTitle: 'Payment Receipt',
          fileName: `payment-receipt-${latestPurchase?.invoiceNumber ?? customer.customerCode ?? 'receipt'}.pdf`,
          patient: {
            id: customer.id?.toString(),
            name:
              `${customer.firstName ?? ''} ${customer.lastName ?? ''}`.trim() ||
              'SHIELD Member',
            patientId: customer.customerCode ?? '',
            mobile: customer.mobile ?? '',
          },
          summary: {
            invoiceNumber: latestPurchase?.invoiceNumber ?? 'Not issued',
            payableAmount: latestPurchase?.payableAmount ?? 0,
            paymentStatus: latestPurchase?.paymentStatus ?? 'PENDING',
            providerName: latestPurchase?.provider?.providerName ?? 'Provider',
          },
        },
      },
    };
  }

  async listCardRequests(principal?: ShieldPrincipal) {
    const context = await this.requireAgentContext(principal);
    const customers = await this.prisma.customer.findMany({
      where: {
        agentCode: context.agentCode,
        deletedAt: null,
      },
      select: {
        id: true,
        uuid: true,
        customerCode: true,
        firstName: true,
        lastName: true,
        mobile: true,
        status: true,
        membership: true,
        shieldCard: true,
      },
    });
    if (customers.length === 0) return [];
    const customerMap = new Map(customers.map((c) => [c.id.toString(), c]));

    const requests = await this.prisma.cardRequest.findMany({
      where: {
        customerId: { in: Array.from(customerMap.keys()).map((id) => BigInt(id)) },
      },
      orderBy: [{ requestedAt: 'desc' }, { id: 'desc' }],
    });

    return requests.map((req) => {
      const cust = customerMap.get(req.customerId.toString());
      return {
        id: req.id.toString(),
        uuid: req.uuid,
        status: req.status,
        requestedAt: req.requestedAt,
        reviewedAt: req.reviewedAt,
        remarks: req.remarks,
        customer: cust
          ? {
              id: cust.id.toString(),
              uuid: cust.uuid,
              customerCode: cust.customerCode,
              name: `${cust.firstName} ${cust.lastName}`.trim(),
              mobile: cust.mobile,
              membershipStatus: cust.membership?.status ?? 'NONE',
              hasDigitalCard: cust.shieldCard != null,
            }
          : null,
      };
    });
  }

  async issueCustomerCard(customerId: bigint, principal?: ShieldPrincipal) {
    await this.agentScopeService.assertAgentCanAccessCustomer(customerId, principal);
    if (principal?.principalType !== 'USER' || !principal.userId) {
      throw new UnauthorizedException('Authorized staff user context is required.');
    }
    return this.customerService.issueDigitalMembershipCard(customerId, BigInt(principal.userId));
  }
}
