import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import { CustomerService } from '../customer/customer.service';
import { WalletService } from '../wallet/wallet.service';
import { AppointmentService } from '../appointment/appointment.service';
import type { ShieldPrincipal } from '../auth/auth.types';
import { DocumentService } from '../document/document.service';
import { NotificationService } from '../notification/notification.service';
import { PharmacyService } from '../pharmacy/pharmacy.service';
import { PlatformPrintService } from '../platform-capabilities/platform-print.service';
import { TimelineService } from '../timeline/timeline.service';

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
    private readonly timelineService: TimelineService,
    private readonly platformPrintService: PlatformPrintService,
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

  async getPatientWorkspace(customerId: bigint, principal?: ShieldPrincipal) {
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
    const timeline = await this.timelineService.getPatientTimeline(customerId);

    if (principal?.userId) {
      await this.timelineService.recordAuditLog({
        action: 'VIEWED_PATIENT',
        entityType: 'PATIENT',
        entityId: customerId,
        userId: BigInt(principal.userId),
        newData: {
          customerId: customerId.toString(),
          roleCode: principal.roleCode,
        },
      });
    }

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
    const printing = this.platformPrintService.buildProviderPatientPrintContext({
      providerContext: principal
        ? {
            providerName: 'SHIELD Provider',
            role: principal.roleCode ?? 'Provider',
            branch: { name: 'Branch not assigned' },
            business: { name: 'SHIELD' },
          }
        : null,
      patient: patient as Record<string, any>,
      membership: membership as Record<string, any>,
      wallet: wallet as Record<string, any>,
      activeVisit: activeAppointment
        ? {
            appointmentId: activeAppointment.id.toString(),
            appointment: activeAppointment,
            status:
              activeVisitWorkspace?.statusLabel ??
              this.humanizeCode(activeAppointment.status),
            workspace: activeVisitWorkspace,
          }
        : null,
      billing: {
        summary: {
          totalInvoices: purchases.length,
          totalBilled,
          totalPayable,
          totalDiscount,
          lastInvoiceDate: purchases[0]?.purchaseDate ?? null,
          lastInvoiceNumber: purchases[0]?.invoiceNumber ?? null,
        },
      },
      timeline: timeline as Array<Record<string, any>>,
      documents: documents as Array<Record<string, any>>,
    });

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
      printing,
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
        code: 'COMPLETE_VISIT',
        title: 'Complete Visit',
        icon: 'task_alt',
        targetTab: 'today-visit',
      },
      {
        code: 'ADD_CLINICAL_NOTE',
        title: 'Add Clinical Note',
        icon: 'note_alt',
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
        code: 'UPLOAD_LAB_REPORT',
        title: 'Upload Lab Report',
        icon: 'lab_profile',
        targetTab: 'records',
      },
      {
        code: 'GENERATE_PRESCRIPTION',
        title: 'Generate Prescription',
        icon: 'medication',
        targetTab: 'prescriptions',
      },
      {
        code: 'BOOK_FOLLOW_UP',
        title: 'Book Follow-up',
        icon: 'event_repeat',
        targetTab: 'appointments',
      },
      {
        code: 'GENERATE_INVOICE',
        title: 'Generate Invoice',
        icon: 'receipt_long',
        targetTab: 'payments',
      },
      {
        code: 'RECORD_PAYMENT',
        title: 'Record Payment',
        icon: 'payments',
        targetTab: 'today-visit',
      },
      {
        code: 'SEND_NOTIFICATION',
        title: 'Send Notification',
        icon: 'notifications',
        targetTab: 'overview',
      },
      {
        code: 'PRINT_PRESCRIPTION',
        title: 'Print Prescription',
        icon: 'print',
        targetTab: 'prescriptions',
      },
      {
        code: 'PRINT_INVOICE',
        title: 'Print Invoice',
        icon: 'print',
        targetTab: 'payments',
      },
      {
        code: 'PRINT_VISIT_SUMMARY',
        title: 'Print Visit Summary',
        icon: 'print',
        targetTab: 'today-visit',
      },
    ];
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
