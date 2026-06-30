import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import { CustomerService } from '../customer/customer.service';
import { WalletService } from '../wallet/wallet.service';
import { AppointmentService } from '../appointment/appointment.service';
import { DocumentService } from '../document/document.service';
import { NotificationService } from '../notification/notification.service';
import { PharmacyService } from '../pharmacy/pharmacy.service';

@Injectable()
export class ServiceProviderService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly customerService: CustomerService,
    private readonly walletService: WalletService,
    private readonly appointmentService: AppointmentService,
    private readonly documentService: DocumentService,
    private readonly notificationService: NotificationService,
    private readonly pharmacyService: PharmacyService,
  ) {}

  async create(data: any) {
    return this.prisma.serviceProvider.create({
      data: {
        uuid: randomUUID(),
        providerName: data.providerName,
        providerType: data.providerType,
        status: data.status || 'ACTIVE',
        businessId: data.businessId ? BigInt(data.businessId) : null,
      },
      include: {
        business: true,
      },
    });
  }

  async findAll() {
    return this.prisma.serviceProvider.findMany({
      include: {
        business: true,
      },
      orderBy: {
        id: 'asc',
      },
    });
  }

  async findOne(id: bigint) {
    const provider = await this.prisma.serviceProvider.findUnique({
      where: { id },
      include: {
        business: true,
      },
    });
    if (!provider) {
      throw new NotFoundException(`Service Provider with ID ${id} not found`);
    }
    return provider;
  }

  async update(id: bigint, data: any) {
    await this.findOne(id);
    return this.prisma.serviceProvider.update({
      where: { id },
      data: {
        providerName: data.providerName,
        providerType: data.providerType,
        status: data.status,
        businessId: data.businessId ? BigInt(data.businessId) : null,
      },
      include: {
        business: true,
      },
    });
  }

  async remove(id: bigint) {
    await this.findOne(id);
    return this.prisma.serviceProvider.delete({
      where: { id },
    });
  }

  async getPerformance(id: bigint) {
    await this.findOne(id);

    const [
      totalAppointments,
      completedAppointments,
      cancelledAppointments,
      totalPurchases,
      billingAggregate,
      uniquePatientsAppointments,
      uniquePatientsPurchases,
    ] = await Promise.all([
      this.prisma.appointment.count({ where: { providerId: id } }),
      this.prisma.appointment.count({ where: { providerId: id, status: 'COMPLETED' } }),
      this.prisma.appointment.count({ where: { providerId: id, status: 'CANCELLED' } }),
      this.prisma.purchase.count({ where: { providerId: id } }),
      this.prisma.purchase.aggregate({
        where: { providerId: id },
        _sum: { payableAmount: true, totalAmount: true },
      }),
      this.prisma.appointment.findMany({
        where: { providerId: id },
        distinct: ['customerId'],
        select: { customerId: true },
      }),
      this.prisma.purchase.findMany({
        where: { providerId: id },
        distinct: ['customerId'],
        select: { customerId: true },
      }),
    ]);

    // Compute unique patients union
    const patientIds = new Set<string>();
    uniquePatientsAppointments.forEach((item) => {
      if (item.customerId) patientIds.add(item.customerId.toString());
    });
    uniquePatientsPurchases.forEach((item) => {
      if (item.customerId) patientIds.add(item.customerId.toString());
    });

    const revenue = Number(billingAggregate._sum.payableAmount || 0);
    const totalBilled = Number(billingAggregate._sum.totalAmount || 0);

    return {
      providerId: id.toString(),
      totalAppointments,
      completedAppointments,
      cancelledAppointments,
      totalPurchases,
      revenue,
      totalBilled,
      uniquePatients: patientIds.size,
      completionRate: totalAppointments > 0 ? (completedAppointments / totalAppointments) * 100 : 0,
    };
  }

  async getAnalytics() {
    const providers = await this.prisma.serviceProvider.findMany({
      include: {
        business: true,
      },
    });

    const analytics = await Promise.all(
      providers.map(async (provider) => {
        const perf = await this.getPerformance(provider.id);
        return {
          id: provider.id.toString(),
          name: provider.providerName,
          type: provider.providerType,
          status: provider.status,
          branch: provider.business?.name || 'Central Group',
          appointments: perf.totalAppointments,
          completedAppointments: perf.completedAppointments,
          revenue: perf.revenue,
          uniquePatients: perf.uniquePatients,
        };
      }),
    );

    // Group-level summary
    const typeSummary: Record<string, { count: number; appointments: number; revenue: number }> = {};
    let totalRevenue = 0;
    let totalAppointments = 0;

    for (const item of analytics) {
      const type = item.type || 'UNKNOWN';
      if (!typeSummary[type]) {
        typeSummary[type] = { count: 0, appointments: 0, revenue: 0 };
      }
      typeSummary[type].count += 1;
      typeSummary[type].appointments += item.appointments;
      typeSummary[type].revenue += item.revenue;

      totalRevenue += item.revenue;
      totalAppointments += item.appointments;
    }

    return {
      generatedAt: new Date().toISOString(),
      totalRevenue,
      totalAppointments,
      providerCount: providers.length,
      byType: Object.entries(typeSummary).map(([type, stats]) => ({
        type,
        ...stats,
      })),
      providers: analytics,
    };
  }

  async getPatientWorkspace(customerId: bigint) {
    const [
      patient,
      membership,
      wallet,
      documents,
      appointments,
      notifications,
      purchases,
    ] = await Promise.all([
      this.customerService.findOne(customerId),
      this.customerService.getCustomerPortalMembership(customerId),
      this.walletService.getCustomerWalletBundle(customerId),
      this.documentService.list(customerId),
      this.appointmentService.list(customerId),
      this.notificationService.list(customerId),
      this.pharmacyService.listPurchases(customerId),
    ]);

    const activeAppointment = this.resolvePrimaryVisitAppointment(appointments);
    const activeVisitWorkspace = activeAppointment
      ? await this.appointmentService.getConsultationWorkspace(activeAppointment.id)
      : null;
    const timeline = this.buildPatientTimeline({
      wallet,
      documents,
      appointments,
      notifications,
      purchases,
      activeVisitWorkspace,
    });

    const totalBilled = purchases.reduce(
      (sum, purchase) => sum + Number(purchase.totalAmount || 0),
      0,
    );
    const totalPayable = purchases.reduce(
      (sum, purchase) => sum + Number(purchase.payableAmount || 0),
      0,
    );
    const totalDiscount = purchases.reduce(
      (sum, purchase) => sum + Number(purchase.discountAmount || 0),
      0,
    );
    const openAppointments = appointments.filter(
      (appointment) =>
        !this.isCompletedAppointmentStatus(appointment.status) &&
        !this.isCancelledAppointmentStatus(appointment.status),
    );
    const completedAppointments = appointments.filter((appointment) =>
      this.isCompletedAppointmentStatus(appointment.status),
    );
    const unreadNotifications = notifications.filter(
      (notification) =>
        (notification.status || '').toString().toUpperCase() !== 'READ',
    );

    return {
      patient,
      membership,
      wallet,
      activeVisit: activeAppointment
        ? {
            appointmentId: activeAppointment.id.toString(),
            appointment: activeAppointment,
            status: activeVisitWorkspace?.statusLabel ?? this.humanizeCode(activeAppointment.status),
            workspace: activeVisitWorkspace,
          }
        : null,
      timeline,
      documents: {
        items: documents,
        total: documents.length,
        groupedCounts: {
          prescriptions: documents.filter((document) =>
            this.matchesAnyCode(document.documentType, ['PRESCRIPTION']),
          ).length,
          labReports: documents.filter((document) =>
            this.matchesAnyCode(document.documentType, ['LAB_REPORT']),
          ).length,
          invoices: documents.filter((document) =>
            this.matchesAnyCode(document.documentType, ['INVOICE', 'PHARMACY_BILL']),
          ).length,
          other: documents.filter(
            (document) =>
              !this.matchesAnyCode(document.documentType, [
                'PRESCRIPTION',
                'LAB_REPORT',
                'INVOICE',
                'PHARMACY_BILL',
              ]),
          ).length,
        },
      },
      billing: {
        items: purchases,
        summary: {
          totalInvoices: purchases.length,
          totalBilled,
          totalPayable,
          totalDiscount,
          lastInvoiceDate: purchases[0]?.purchaseDate ?? null,
        },
      },
      notifications: {
        items: notifications,
        unreadCount: unreadNotifications.length,
      },
      appointments: {
        items: appointments,
        summary: {
          total: appointments.length,
          active: openAppointments.length,
          completed: completedAppointments.length,
          upcoming: openAppointments.filter(
            (appointment) =>
              appointment.appointmentDate != null &&
              new Date(appointment.appointmentDate).getTime() > Date.now(),
          ).length,
        },
      },
      analytics: {
        totalDocuments: documents.length,
        totalTimelineEvents: timeline.length,
        totalNotifications: notifications.length,
        totalPurchases: purchases.length,
        totalWalletTransactions: Array.isArray(wallet.recentTransactions)
          ? wallet.recentTransactions.length
          : 0,
        pendingAppointments: openAppointments.length,
        completedAppointments: completedAppointments.length,
      },
      actions: this.buildWorkspaceActions(!!activeAppointment),
    };
  }

  private resolvePrimaryVisitAppointment(appointments: Array<any>) {
    const incomplete = appointments
      .filter(
        (appointment) =>
          !this.isCompletedAppointmentStatus(appointment.status) &&
          !this.isCancelledAppointmentStatus(appointment.status),
      )
      .sort(
        (left, right) =>
          new Date(left.appointmentDate).getTime() -
          new Date(right.appointmentDate).getTime(),
      );

    if (incomplete.length > 0) {
      return incomplete[0];
    }

    const completed = [...appointments].sort(
      (left, right) =>
        new Date(right.appointmentDate).getTime() -
        new Date(left.appointmentDate).getTime(),
    );

    return completed[0] ?? null;
  }

  private buildWorkspaceActions(hasActiveVisit: boolean) {
    return [
      {
        code: hasActiveVisit ? 'CONTINUE_VISIT' : 'START_VISIT',
        title: hasActiveVisit ? 'Continue Visit' : 'Start Visit',
        icon: hasActiveVisit ? 'play_circle' : 'play_arrow',
        targetTab: 'today-visit',
      },
      {
        code: 'BOOK_APPOINTMENT',
        title: 'Book Appointment',
        icon: 'event',
        targetTab: 'appointments',
      },
      {
        code: 'UPLOAD_DOCUMENT',
        title: 'Upload Document',
        icon: 'upload_file',
        targetTab: 'documents',
      },
      {
        code: 'GENERATE_PRESCRIPTION',
        title: 'Generate Prescription',
        icon: 'medication',
        targetTab: 'prescriptions',
      },
      {
        code: 'GENERATE_INVOICE',
        title: 'Generate Invoice',
        icon: 'receipt_long',
        targetTab: 'payments',
      },
      {
        code: 'SEND_NOTIFICATION',
        title: 'Send Notification',
        icon: 'notifications',
        targetTab: 'overview',
      },
    ];
  }

  private buildPatientTimeline(input: {
    wallet: any;
    documents: Array<any>;
    appointments: Array<any>;
    notifications: Array<any>;
    purchases: Array<any>;
    activeVisitWorkspace: any;
  }) {
    const items: Array<Record<string, unknown>> = [];
    const visitTimeline = Array.isArray(input.activeVisitWorkspace?.timeline)
      ? input.activeVisitWorkspace.timeline
      : [];

    for (const entry of visitTimeline) {
      items.push({
        kind: entry.code ?? 'VISIT',
        category: 'VISIT',
        title: entry.title ?? 'Visit update',
        subtitle: entry.subtitle ?? '',
        timestamp: entry.timestamp ?? new Date().toISOString(),
        icon: entry.icon ?? 'medical_services',
        color: entry.color ?? 'blue',
        actor: entry.actor ?? entry.providerName ?? 'Provider',
        linkedRecordId: entry.referenceId?.toString() ?? null,
        quickNavigationTarget: {
          tab: 'today-visit',
        },
      });
    }

    for (const appointment of input.appointments) {
      items.push({
        kind: 'APPOINTMENT',
        category: 'APPOINTMENT',
        title: this.humanizeCode(appointment.appointmentType || 'APPOINTMENT'),
        subtitle: this.humanizeCode(appointment.status || 'SCHEDULED'),
        timestamp: appointment.appointmentDate,
        icon: 'event',
        color: 'blue',
        actor: appointment.provider?.providerName ?? 'Provider',
        linkedRecordId: appointment.id?.toString() ?? null,
        quickNavigationTarget: {
          tab: 'appointments',
        },
      });
    }

    for (const document of input.documents) {
      items.push({
        kind: 'DOCUMENT',
        category: 'DOCUMENT',
        title: document.fileName ?? 'Document uploaded',
        subtitle: this.humanizeCode(document.documentType || document.status || 'DOCUMENT'),
        timestamp: document.createdAt,
        icon: 'description',
        color: 'teal',
        actor: document.uploadedByUser?.firstName
          ? `${document.uploadedByUser.firstName} ${document.uploadedByUser.lastName ?? ''}`.trim()
          : 'Provider',
        linkedRecordId: document.id?.toString() ?? null,
        quickNavigationTarget: {
          tab: 'documents',
        },
      });
    }

    const transactions = Array.isArray(input.wallet?.recentTransactions)
      ? input.wallet.recentTransactions
      : [];
    for (const transaction of transactions) {
      const amount = Number(transaction.amount || 0);
      items.push({
        kind: (transaction.sub_ledger_type || '').toString().toUpperCase() === 'REWARD_POINTS'
          ? 'REWARD'
          : 'WALLET',
        category: 'WALLET',
        title:
          transaction.remarks ||
          (amount >= 0 ? 'Wallet credited' : 'Wallet debited'),
        subtitle: this.humanizeCode(transaction.sub_ledger_type || 'CASH'),
        timestamp: transaction.created_at,
        icon: 'account_balance_wallet',
        color: 'green',
        actor: 'SHIELD Wallet',
        amount,
        linkedRecordId: transaction.id?.toString() ?? null,
        quickNavigationTarget: {
          tab: 'wallet',
        },
      });
    }

    for (const purchase of input.purchases) {
      items.push({
        kind: 'BILLING',
        category: 'BILLING',
        title: purchase.invoiceNumber || 'Invoice generated',
        subtitle: `Collected ${Number(purchase.payableAmount || 0).toFixed(2)}`,
        timestamp: purchase.purchaseDate,
        icon: 'receipt_long',
        color: 'amber',
        actor: purchase.provider?.providerName ?? 'Billing desk',
        amount: Number(purchase.payableAmount || 0),
        linkedRecordId: purchase.id?.toString() ?? null,
        quickNavigationTarget: {
          tab: 'payments',
        },
      });
    }

    for (const notification of input.notifications) {
      items.push({
        kind: 'NOTIFICATION',
        category: 'NOTIFICATION',
        title: notification.title || 'Notification sent',
        subtitle: notification.message || '',
        timestamp: notification.sentAt ?? new Date().toISOString(),
        icon: 'notifications',
        color: 'indigo',
        actor: 'SHIELD',
        linkedRecordId: notification.id?.toString() ?? null,
        quickNavigationTarget: {
          tab: 'overview',
        },
      });
    }

    return items.sort(
      (left, right) =>
        new Date(String(right.timestamp)).getTime() -
        new Date(String(left.timestamp)).getTime(),
    );
  }

  private isCompletedAppointmentStatus(status: string | null | undefined) {
    return (status || '').toString().toUpperCase() === 'COMPLETED';
  }

  private isCancelledAppointmentStatus(status: string | null | undefined) {
    return (status || '').toString().toUpperCase() === 'CANCELLED';
  }

  private matchesAnyCode(value: string | null | undefined, codes: Array<string>) {
    const normalized = (value || '').toString().trim().toUpperCase();
    return codes.includes(normalized);
  }

  private humanizeCode(value: string | null | undefined) {
    const normalized = (value || '').toString().trim();
    if (!normalized) {
      return '';
    }

    return normalized
      .replace(/_/g, ' ')
      .toLowerCase()
      .replace(/\b\w/g, (character) => character.toUpperCase());
  }
}
