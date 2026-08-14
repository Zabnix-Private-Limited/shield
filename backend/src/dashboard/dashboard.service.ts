import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';
import { PricingService } from '../pricing/pricing.service';

type CustomerBanner = {
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string;
  altText: string;
  ctaLabel: string;
  ctaRoute: string;
  placement: string;
  audience: string[];
  priority: number;
  status: string;
  startAt?: string;
  endAt?: string;
};

@Injectable()
export class DashboardService {
  constructor(
    private prisma: PrismaService,
    private walletService: WalletService,
    private pricingService: PricingService,
  ) {}

  async getCustomerDashboard(customerId: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      include: { membership: true, wallet: true, creditAccount: true },
    });
    if (!customer) {
      throw new NotFoundException(`Customer with ID ${customerId} not found`);
    }

    // Calculate Wallet Balance
    const walletSummary = customer.wallet
      ? await this.walletService.getWalletSummary(customer.wallet.id)
      : null;

    const totalAppointments = await this.prisma.appointment.count({
      where: { customerId },
    });
    const upcomingAppointments = await this.prisma.appointment.count({
      where: { customerId, status: 'SCHEDULED' },
    });
    const unreadNotifications = await this.prisma.notification.count({
      where: { customerId, status: 'UNREAD' },
    });

    const recentTransactions = customer.wallet
      ? await this.walletService.getTransactions(customer.wallet.id, {})
      : [];

    const recentAppointments = await this.prisma.appointment.findMany({
      where: { customerId },
      include: { provider: true },
      take: 3,
      orderBy: { appointmentDate: 'desc' },
    });

    return {
      customer: {
        id: customer.id.toString(),
        name: `${customer.firstName} ${customer.lastName}`,
        customerCode: customer.customerCode,
        status: customer.status,
      },
      membership: customer.membership
        ? {
            number: customer.membership.membershipNumber,
            status: customer.membership.status,
            expiryDate: customer.membership.expiryDate,
          }
        : null,
      wallet: {
        cashBalance: walletSummary?.cashWallet.available ?? 0,
        rewardPoints: walletSummary?.rewardPoints.available ?? 0,
        availableCredit: customer.creditAccount
          ? Number(customer.creditAccount.availableCredit)
          : 0,
      },
      counts: {
        totalAppointments,
        upcomingAppointments,
        unreadNotifications,
      },
      recentTransactions: recentTransactions.slice(0, 3),
      recentAppointments,
    };
  }

  async getCustomerPortalDashboard(customerId: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      include: {
        membership: {
          include: {
            membershipType: true,
          },
        },
        shieldCard: true,
        wallet: true,
        creditAccount: true,
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
    const recentTransactions = customer.wallet
      ? await this.walletService.getTransactions(customer.wallet.id, {})
      : [];

    const [appointments, notifications, documents, banners] = await Promise.all(
      [
        this.prisma.appointment.findMany({
          where: { customerId },
          include: { provider: true },
          orderBy: { appointmentDate: 'desc' },
          take: 6,
        }),
        this.prisma.notification.findMany({
          where: { customerId },
          orderBy: [{ sentAt: 'desc' }, { id: 'desc' }],
          take: 6,
        }),
        this.prisma.document.findMany({
          where: { customerId },
          include: {
            documentExtractions: {
              orderBy: { createdAt: 'asc' },
            },
            documentProcessingLogs: {
              orderBy: { processedAt: 'asc' },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 6,
        }),
        this.getCustomerBanners(),
      ],
    );

    return {
      customer: {
        id: customer.id.toString(),
        uuid: customer.uuid,
        customerCode: customer.customerCode,
        aadhaarNumber: customer.aadhaarNumber,
        firstName: customer.firstName,
        lastName: customer.lastName,
        dob: customer.dob,
        gender: customer.gender,
        mobile: customer.mobile,
        email: customer.email,
        addressLine1: customer.addressLine1,
        addressLine2: customer.addressLine2,
        city: customer.city,
        district: customer.district,
        state: customer.state,
        pincode: customer.pincode,
        status: customer.status,
        createdBy: customer.createdBy?.toString(),
        approvedBy: customer.approvedBy?.toString(),
        createdAt: customer.createdAt,
        updatedAt: customer.updatedAt,
        bloodGroup: customer.bloodGroup,
        agentCode: customer.agentCode,
      },
      wallet: {
        walletId: customer.wallet?.id.toString(),
        customerId: customer.id.toString(),
        balance: walletSummary?.cashWallet.available ?? 0,
        cashBalance: walletSummary?.cashWallet.available ?? 0,
        pointsBalance: walletSummary?.rewardPoints.available ?? 0,
        creditAvailable: customer.creditAccount
          ? Number(customer.creditAccount.availableCredit)
          : 0,
        status: customer.wallet?.status ?? 'ACTIVE',
      },
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
      membershipApplication: customer.membershipApplications[0]
        ? {
            id: customer.membershipApplications[0].id.toString(),
            uuid: customer.membershipApplications[0].uuid,
            reference: customer.membershipApplications[0].reference,
            status: customer.membershipApplications[0].status,
            submittedAt: customer.membershipApplications[0].submittedAt,
            reviewedAt: customer.membershipApplications[0].reviewedAt,
            reason: customer.membershipApplications[0].reviewReason,
          }
        : null,
      shieldCard: customer.shieldCard
        ? {
            id: customer.shieldCard.id.toString(),
            cardNumber: customer.shieldCard.cardNumber,
            qrCode: customer.shieldCard.qrCode,
            status: customer.shieldCard.status,
            issuedAt: customer.shieldCard.issuedAt,
          }
        : null,
      appointments,
      notifications,
      recentActivity: recentTransactions.slice(0, 4),
      documents,
      banners,
      quickActions: [
        {
          key: 'view-card',
          label: 'View card',
          route: '/portal/customer/membership',
        },
        {
          key: 'book-visit',
          label: 'Book visit',
          route: '/portal/customer/appointments',
        },
        {
          key: 'open-wallet',
          label: 'Open wallet',
          route: '/portal/customer/wallet',
        },
      ],
      services: [
        {
          key: 'pharmacy',
          label: 'Pharmacy',
          description: 'Medicines, repeats, and partner branch orders.',
        },
        {
          key: 'clinic',
          label: 'Clinic',
          description: 'Consultations and follow-up visits.',
        },
        {
          key: 'lab',
          label: 'Lab',
          description: 'Tests, reports, and health checks.',
        },
      ],
    };
  }

  private async getCustomerBanners(): Promise<CustomerBanner[]> {
    const setting = await this.prisma.commercialSetting.findUnique({
      where: { code: 'OPERATIONS_CUSTOMER_BANNERS' },
      select: { valueText: true, status: true },
    });
    if (!setting || setting.status !== 'ACTIVE' || !setting.valueText?.trim()) {
      return [];
    }

    try {
      const records = JSON.parse(setting.valueText) as unknown;
      if (!Array.isArray(records)) return [];
      const now = new Date();
      return records
        .map((record) => record as Partial<CustomerBanner>)
        .filter((record) => {
          const audience = Array.isArray(record.audience)
            ? record.audience
            : [];
          const startsAt = record.startAt ? new Date(record.startAt) : null;
          const endsAt = record.endAt ? new Date(record.endAt) : null;
          return (
            record.id &&
            record.title &&
            record.subtitle &&
            record.imageUrl &&
            record.altText &&
            record.ctaLabel &&
            record.ctaRoute?.startsWith('/portal/customer/') &&
            record.placement === 'DASHBOARD' &&
            record.status === 'PUBLISHED' &&
            (audience.includes('ALL_CUSTOMERS') ||
              audience.includes('CUSTOMER')) &&
            (!startsAt || startsAt <= now) &&
            (!endsAt || endsAt >= now)
          );
        })
        .map((record) => ({
          id: record.id!,
          title: record.title!,
          subtitle: record.subtitle!,
          imageUrl: record.imageUrl!,
          altText: record.altText!,
          ctaLabel: record.ctaLabel!,
          ctaRoute: record.ctaRoute!,
          placement: 'DASHBOARD',
          audience: Array.isArray(record.audience) ? record.audience : [],
          priority: Number(record.priority ?? 0),
          status: 'PUBLISHED',
          startAt: record.startAt,
          endAt: record.endAt,
        }))
        .sort((left, right) => right.priority - left.priority);
    } catch {
      return [];
    }
  }

  async getStaffDashboard() {
    const totalCustomers = await this.prisma.customer.count();
    const pendingOnboarding = await this.prisma.customer.count({
      where: { status: 'PENDING' },
    });
    const processingDocuments = await this.prisma.document.count({
      where: { status: 'PROCESSING' },
    });
    const scheduledAppointmentsToday = await this.prisma.appointment.count({
      where: {
        status: 'SCHEDULED',
        appointmentDate: {
          gte: new Date(new Date().setHours(0, 0, 0, 0)),
          lte: new Date(new Date().setHours(23, 59, 59, 999)),
        },
      },
    });

    return {
      totalCustomers,
      pendingOnboarding,
      processingDocuments,
      scheduledAppointmentsToday,
    };
  }

  async getCrmDashboard() {
    const pendingTasks = await this.prisma.crmTask.count({
      where: { status: 'PENDING' },
    });
    const openComplaints = await this.prisma.complaint.count({
      where: { status: 'PENDING' },
    });
    const totalActivities = await this.prisma.crmActivity.count();

    return {
      pendingTasks,
      openComplaints,
      totalActivities,
    };
  }

  async getManagementDashboard() {
    const activeCustomers = await this.prisma.customer.count({
      where: { status: 'ACTIVE' },
    });
    const completedAppointments = await this.prisma.appointment.count({
      where: { status: 'COMPLETED' },
    });

    const credits = await this.prisma.cashWalletTransaction.findMany({
      where: {
        transactionType: { in: ['CREDIT', 'RECHARGE', 'OPENING_BALANCE'] },
      },
    });
    const creditsSum = credits.reduce(
      (sum, entry) => sum + Number(entry.amount || 0),
      0,
    );

    return {
      activeCustomers,
      completedAppointments,
      totalRechargedRevenue: Number(creditsSum || 0),
    };
  }

  async getRoleSectionDashboard(
    role: string,
    section: string,
    customerId?: bigint,
  ) {
    const roleKey = role.toLowerCase();
    const normalizedRole =
      roleKey === 'super-admin'
        ? 'super-admin'
        : roleKey === 'shield-executive'
          ? 'shield-executive'
          : roleKey === 'crm-executive'
            ? 'crm-executive'
            : roleKey;
    const sectionKey = section.toLowerCase();
    const title = section
      .split('-')
      .filter(Boolean)
      .map((part) => `${part[0].toUpperCase()}${part.slice(1)}`)
      .join(' ');
    const today = new Date();
    const startOfDay = new Date(today);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(today);
    endOfDay.setHours(23, 59, 59, 999);

    const toDateLabel = (value?: Date | null) =>
      value ? value.toLocaleDateString() : '';
    const toCurrency = (value: number) => `₹${Number(value || 0).toFixed(2)}`;
    const mapCustomerTitle = (
      firstName?: string | null,
      lastName?: string | null,
    ) => [firstName, lastName].filter(Boolean).join(' ').trim() || 'Customer';

    const data: any = {
      key: sectionKey,
      title,
      summary: `Live ${title.toLowerCase()} records for the ${role} workspace.`,
      actions: [],
      metrics: [],
      queueItems: [],
      recentItems: [],
      insightItems: [],
    };

    if (normalizedRole === 'customer') {
      if (!customerId) {
        throw new NotFoundException('Customer session is required.');
      }
      const customer = await this.prisma.customer.findUnique({
        where: { id: customerId },
        include: {
          wallet: true,
          creditAccount: true,
          membership: {
            include: {
              membershipType: true,
            },
          },
        },
      });

      if (!customer) {
        throw new NotFoundException('Customer not found for session.');
      }

      const walletSummary = customer.wallet
        ? await this.walletService.getWalletSummary(customer.wallet.id)
        : null;
      const cashBalance = walletSummary?.cashWallet.available ?? 0;
      const rewardPoints = walletSummary?.rewardPoints.available ?? 0;
      const creditAvailable = customer.creditAccount
        ? Number(customer.creditAccount.availableCredit)
        : 0;

      if (sectionKey === 'dashboard' || sectionKey === 'wallet') {
        data.metrics = [
          {
            label: 'Cash Balance',
            value: toCurrency(cashBalance),
            note: 'Calculated from wallet ledgers',
          },
          {
            label: 'Reward Points',
            value: `${rewardPoints}`,
            note: 'Available reward balance',
          },
          {
            label: 'Credit Available',
            value: toCurrency(creditAvailable),
            note: 'Current usable credit line',
          },
          {
            label: 'Membership',
            value: customer.membership?.membershipNumber || 'Not issued',
            note:
              customer.membership?.membershipType?.name ||
              customer.membership?.status ||
              customer.status ||
              'Pending',
          },
        ];
      }

      if (sectionKey == 'dashboard' || sectionKey == 'appointments') {
        const appointments = await this.prisma.appointment.findMany({
          where: { customerId: customer.id },
          include: { provider: true },
          orderBy: { appointmentDate: 'desc' },
          take: 6,
        });
        data.queueItems = appointments.map((appointment) => ({
          title: appointment.appointmentType || 'Appointment',
          subtitle:
            appointment.provider?.providerName || 'Assigned provider pending',
          meta: toDateLabel(appointment.appointmentDate),
          status: appointment.status || 'SCHEDULED',
        }));
      }

      if (sectionKey == 'dashboard' || sectionKey == 'wallet') {
        const transactions = customer.wallet
          ? await this.walletService.getTransactions(customer.wallet.id, {})
          : [];
        data.recentItems = transactions.slice(0, 6).map((transaction) => ({
          title: transaction.remarks || 'Wallet transaction',
          subtitle: `Type: ${transaction.transactionType || 'ADJUSTMENT'}`,
          meta: toDateLabel(transaction.createdAt),
          status: toCurrency(Number(transaction.amount || 0)),
        }));
      }

      if (sectionKey === 'documents' || sectionKey === 'prescriptions') {
        const documentType =
          sectionKey === 'prescriptions' ? 'PRESCRIPTION' : undefined;
        const documents = await this.prisma.document.findMany({
          where: {
            customerId: customer.id,
            ...(documentType ? { documentType } : {}),
          },
          orderBy: { createdAt: 'desc' },
          take: 8,
        });
        data.queueItems = documents.map((document) => ({
          title: document.fileName || 'Document',
          subtitle: document.documentType || 'Unspecified document',
          meta: toDateLabel(document.createdAt),
          status: document.status || 'UPLOADED',
        }));
      }

      if (sectionKey === 'notifications') {
        const notifications = await this.prisma.notification.findMany({
          where: { customerId: customer.id },
          orderBy: [{ sentAt: 'desc' }, { id: 'desc' }],
          take: 8,
        });
        data.queueItems = notifications.map((notification) => ({
          title: notification.title || 'Notification',
          subtitle: notification.message || '',
          meta: toDateLabel(notification.sentAt),
          status: notification.status || 'UNREAD',
        }));
      }

      if (sectionKey === 'services') {
        const providers = await this.prisma.serviceProvider.findMany({
          where: { status: 'ACTIVE' },
          include: { business: true },
          orderBy: { id: 'asc' },
          take: 8,
        });
        const providerTypeCounts = providers.reduce<Record<string, number>>(
          (acc, provider) => {
            const key = provider.providerType || 'OTHER';
            acc[key] = (acc[key] || 0) + 1;
            return acc;
          },
          {},
        );
        data.metrics = [
          {
            label: 'Active Providers',
            value: `${providers.length}`,
            note: 'Currently available to book',
          },
          {
            label: 'Provider Types',
            value: `${Object.keys(providerTypeCounts).length}`,
            note: 'Distinct categories in the network',
          },
          {
            label: 'Upcoming Visits',
            value: `${await this.prisma.appointment.count({
              where: { customerId: customer.id, status: 'SCHEDULED' },
            })}`,
            note: 'Customer appointments still scheduled',
          },
        ];
        data.queueItems = providers.map((provider) => ({
          title: provider.providerName || 'Provider',
          subtitle: provider.business?.name || 'Business not linked',
          meta: provider.providerType || 'GENERAL',
          status: provider.status || 'ACTIVE',
        }));
      }
    } else if (sectionKey === 'tasks' || sectionKey === 'follow-ups') {
      const tasks = await this.prisma.crmTask.findMany({
        include: { customer: true },
        orderBy: { dueDate: 'asc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Pending Tasks',
          value: `${await this.prisma.crmTask.count({
            where: { status: 'PENDING' },
          })}`,
          note: 'Open CRM task load',
        },
        {
          label: 'Due Today',
          value: `${await this.prisma.crmTask.count({
            where: {
              dueDate: { gte: startOfDay, lte: endOfDay },
            },
          })}`,
          note: 'Requires follow-up today',
        },
      ];
      data.queueItems = tasks.map((task) => ({
        title: mapCustomerTitle(
          task.customer?.firstName,
          task.customer?.lastName,
        ),
        subtitle: task.notes || 'Customer follow-up task',
        meta: toDateLabel(task.dueDate),
        status: task.status || 'PENDING',
      }));
    } else if (sectionKey === 'complaints') {
      const complaints = await this.prisma.complaint.findMany({
        include: { customer: true },
        orderBy: { createdAt: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Open Complaints',
          value: `${await this.prisma.complaint.count({
            where: { status: 'PENDING' },
          })}`,
          note: 'Awaiting handling',
        },
      ];
      data.queueItems = complaints.map((complaint) => ({
        title: complaint.complaintType || 'Complaint',
        subtitle:
          complaint.description ||
          mapCustomerTitle(
            complaint.customer?.firstName,
            complaint.customer?.lastName,
          ),
        meta: toDateLabel(complaint.createdAt),
        status: complaint.status || 'PENDING',
      }));
    } else if (sectionKey === 'campaigns') {
      const [activeCustomers, inactiveCustomers, activities] =
        await Promise.all([
          this.prisma.customer.count({ where: { status: 'ACTIVE' } }),
          this.prisma.customer.count({ where: { status: 'INACTIVE' } }),
          this.prisma.crmActivity.findMany({
            include: { customer: true },
            orderBy: { createdAt: 'desc' },
            take: 8,
          }),
        ]);
      data.metrics = [
        {
          label: 'Active Customers',
          value: `${activeCustomers}`,
          note: 'Available for engagement',
        },
        {
          label: 'Inactive Customers',
          value: `${inactiveCustomers}`,
          note: 'Potential reactivation targets',
        },
      ];
      data.queueItems = activities.map((activity) => ({
        title: activity.activityType || 'CRM activity',
        subtitle:
          activity.notes ||
          mapCustomerTitle(
            activity.customer?.firstName,
            activity.customer?.lastName,
          ),
        meta: toDateLabel(activity.createdAt),
        status: activity.activityType || 'RECORDED',
      }));
    } else if (
      sectionKey === 'customers' ||
      sectionKey === 'patients' ||
      sectionKey === 'memberships' ||
      sectionKey === 'approvals' ||
      sectionKey === 'retention' ||
      sectionKey === 'support'
    ) {
      const customerWhere =
        sectionKey === 'approvals'
          ? { status: 'PENDING' }
          : sectionKey === 'retention'
            ? { status: { in: ['INACTIVE', 'SUSPENDED'] } }
            : {};
      const customers = await this.prisma.customer.findMany({
        where: customerWhere,
        include: { membership: true },
        orderBy: { createdAt: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Total Customers',
          value: `${await this.prisma.customer.count()}`,
          note: 'Current customer base',
        },
        {
          label: 'Pending Customers',
          value: `${await this.prisma.customer.count({
            where: { status: 'PENDING' },
          })}`,
          note: 'Awaiting activation or review',
        },
      ];
      data.queueItems = customers.map((customer) => ({
        title: mapCustomerTitle(customer.firstName, customer.lastName),
        subtitle: customer.mobile || customer.email || 'No contact details',
        meta:
          customer.membership?.membershipNumber || customer.customerCode || '',
        status: customer.status || 'PENDING',
      }));
    } else if (
      sectionKey === 'appointments' ||
      sectionKey === 'consultations' ||
      sectionKey === 'home-visits' ||
      sectionKey === 'treatments' ||
      sectionKey === 'book-appointment'
    ) {
      const appointmentWhere =
        sectionKey === 'home-visits'
          ? { appointmentType: 'HOME_VISIT' }
          : sectionKey === 'consultations'
            ? { appointmentType: { in: ['CONSULTATION', 'DOCTOR'] } }
            : {};
      const appointments = await this.prisma.appointment.findMany({
        where: appointmentWhere,
        include: { customer: true, provider: true },
        orderBy: { appointmentDate: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Scheduled Today',
          value: `${await this.prisma.appointment.count({
            where: {
              status: 'SCHEDULED',
              appointmentDate: { gte: startOfDay, lte: endOfDay },
            },
          })}`,
          note: 'Scheduled for today',
        },
        {
          label: 'Completed',
          value: `${await this.prisma.appointment.count({
            where: { status: 'COMPLETED' },
          })}`,
          note: 'All-time completed visits',
        },
      ];
      data.queueItems = appointments.map((appointment) => ({
        title: mapCustomerTitle(
          appointment.customer?.firstName,
          appointment.customer?.lastName,
        ),
        subtitle:
          appointment.provider?.providerName ||
          appointment.appointmentType ||
          'Appointment',
        meta: toDateLabel(appointment.appointmentDate),
        status: appointment.status || 'SCHEDULED',
      }));
    } else if (
      sectionKey === 'documents' ||
      sectionKey === 'reports' ||
      sectionKey === 'bills' ||
      sectionKey === 'prescriptions' ||
      sectionKey === 'history'
    ) {
      const typeWhere =
        sectionKey === 'prescriptions'
          ? { documentType: 'PRESCRIPTION' }
          : sectionKey === 'bills'
            ? { documentType: { in: ['PHARMACY_BILL', 'INVOICE'] } }
            : sectionKey === 'reports'
              ? { documentType: { in: ['LAB_REPORT', 'DENTAL_REPORT'] } }
              : {};
      const documents = await this.prisma.document.findMany({
        where: typeWhere,
        include: { customer: true },
        orderBy: { createdAt: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Total Documents',
          value: `${await this.prisma.document.count()}`,
          note: 'Records stored in the system',
        },
        {
          label: 'Processing',
          value: `${await this.prisma.document.count({
            where: { status: 'PROCESSING' },
          })}`,
          note: 'Still under processing',
        },
      ];
      data.queueItems = documents.map((document) => ({
        title: document.fileName || 'Document',
        subtitle: mapCustomerTitle(
          document.customer?.firstName,
          document.customer?.lastName,
        ),
        meta: document.documentType || 'UNSPECIFIED',
        status: document.status || 'UPLOADED',
      }));
    } else if (sectionKey === 'verification' || sectionKey === 'qr-scan') {
      const cards = await this.prisma.shieldCard.findMany({
        include: { customer: true, issuedBusiness: true },
        orderBy: { issuedAt: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Issued Cards',
          value: `${await this.prisma.shieldCard.count()}`,
          note: 'Cards available for verification',
        },
        {
          label: 'Active Cards',
          value: `${await this.prisma.shieldCard.count({
            where: { status: 'ACTIVE' },
          })}`,
          note: 'Currently active cards',
        },
      ];
      data.queueItems = cards.map((card) => ({
        title: card.cardNumber || 'Card pending number',
        subtitle: mapCustomerTitle(
          card.customer?.firstName,
          card.customer?.lastName,
        ),
        meta: card.issuedBusiness?.name || '',
        status: card.status || 'PENDING',
      }));
    } else if (
      sectionKey === 'wallet-ops' ||
      sectionKey === 'wallet' ||
      sectionKey === 'recharge' ||
      sectionKey === 'credit' ||
      sectionKey === 'reversals' ||
      sectionKey === 'benefits'
    ) {
      const config = await this.pricingService.getAdminCommercialConfig();
      const credits = await this.prisma.cashWalletTransaction.findMany({
        orderBy: { createdAt: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Service Rules',
          value: `${config.serviceRules.length}`,
          note: 'Commercial service rule count',
        },
        {
          label: 'Reward Rules',
          value: `${config.rewardRules.length}`,
          note: 'Reward rule count',
        },
        {
          label: 'Redemption Rules',
          value: `${config.redemptionRules.length}`,
          note: 'Redemption rule count',
        },
      ];
      data.queueItems = credits.map((entry) => ({
        title: entry.transactionType || 'Wallet transaction',
        subtitle: entry.remarks || 'Wallet ledger entry',
        meta: toDateLabel(entry.createdAt),
        status: toCurrency(Number(entry.amount || 0)),
      }));
      data.recentItems = config.settings.map((setting) => ({
        title: setting.code || 'Pricing setting',
        subtitle: setting.valueType || 'VALUE',
        meta: setting.status || '',
        status:
          setting.valueText ||
          `${setting.valueNumber ?? setting.valueBoolean ?? ''}`,
      }));
    } else if (sectionKey === 'businesses') {
      const businesses = await this.prisma.business.findMany({
        orderBy: { createdAt: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Businesses',
          value: `${await this.prisma.business.count()}`,
          note: 'Configured business entities',
        },
      ];
      data.queueItems = businesses.map((business) => ({
        title: business.name || 'Business',
        subtitle: business.code || 'Code unavailable',
        meta: business.businessType || 'UNSPECIFIED',
        status: business.status || 'ACTIVE',
      }));
    } else if (sectionKey === 'membership-plans') {
      const plans = await this.prisma.membershipType.findMany({
        orderBy: { id: 'asc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Plans',
          value: `${plans.length}`,
          note: 'Membership plans configured',
        },
      ];
      data.queueItems = plans.map((plan) => ({
        title: plan.name || plan.code || 'Membership plan',
        subtitle: `Joining Fee: ${toCurrency(Number(plan.joiningFee || 0))}`,
        meta: `${Number(plan.discountPercentage || 0)}% discount`,
        status: plan.status || 'ACTIVE',
      }));
    } else if (sectionKey === 'users') {
      const users = await this.prisma.user.findMany({
        orderBy: { createdAt: 'desc' },
        take: 8,
      });
      data.metrics = [
        {
          label: 'Users',
          value: `${await this.prisma.user.count()}`,
          note: 'Registered internal users',
        },
      ];
      data.queueItems = users.map((user) => ({
        title: user.email || user.firebaseUid || `User ${user.id.toString()}`,
        subtitle:
          mapCustomerTitle(user.firstName, user.lastName) ||
          'Display name unavailable',
        meta: toDateLabel(user.createdAt),
        status: user.status || 'ACTIVE',
      }));
    } else if (sectionKey === 'roles') {
      const roles = await this.prisma.role.findMany({
        orderBy: { id: 'asc' },
        take: 12,
      });
      data.metrics = [
        {
          label: 'Roles',
          value: `${roles.length}`,
          note: 'Access roles configured',
        },
      ];
      data.queueItems = roles.map((roleEntry) => ({
        title: roleEntry.name || roleEntry.code || 'Role',
        subtitle: roleEntry.description || 'Role description unavailable',
        meta: roleEntry.userType || 'INTERNAL',
        status: roleEntry.defaultScope || 'CONFIGURED',
      }));
    } else if (sectionKey === 'audit') {
      const audits = await this.prisma.auditLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: 12,
      });
      data.metrics = [
        {
          label: 'Audit Logs',
          value: `${await this.prisma.auditLog.count()}`,
          note: 'Stored audit trail rows',
        },
      ];
      data.queueItems = audits.map((audit) => ({
        title: audit.action || 'Audit event',
        subtitle: audit.entityType || 'Entity unavailable',
        meta: toDateLabel(audit.createdAt),
        status: audit.entityId?.toString() || 'RECORDED',
      }));
    } else if (sectionKey === 'notification-center') {
      const notifications = await this.prisma.notification.findMany({
        orderBy: { sentAt: 'desc' },
        take: 12,
      });
      data.metrics = [
        {
          label: 'Notifications',
          value: `${await this.prisma.notification.count()}`,
          note: 'Notification rows stored',
        },
      ];
      data.queueItems = notifications.map((notification) => ({
        title: notification.title || 'Notification',
        subtitle: notification.message || '',
        meta: toDateLabel(notification.sentAt),
        status: notification.status || 'UNREAD',
      }));
    } else if (sectionKey === 'system' || sectionKey === 'analytics') {
      const [customers, providers, businesses, appointments] =
        await Promise.all([
          this.prisma.customer.count(),
          this.prisma.serviceProvider.count(),
          this.prisma.business.count(),
          this.prisma.appointment.count(),
        ]);
      data.metrics = [
        {
          label: 'Customers',
          value: `${customers}`,
          note: 'Customer records in the database',
        },
        {
          label: 'Providers',
          value: `${providers}`,
          note: 'Provider records in the database',
        },
        {
          label: 'Businesses',
          value: `${businesses}`,
          note: 'Business records in the database',
        },
        {
          label: 'Appointments',
          value: `${appointments}`,
          note: 'Appointment rows in the database',
        },
      ];
    } else {
      const [customers, appointments, documents] = await Promise.all([
        this.prisma.customer.count(),
        this.prisma.appointment.count(),
        this.prisma.document.count(),
      ]);
      data.metrics = [
        {
          label: 'Customers',
          value: `${customers}`,
          note: 'Customer records available',
        },
        {
          label: 'Appointments',
          value: `${appointments}`,
          note: 'Appointments available',
        },
        {
          label: 'Documents',
          value: `${documents}`,
          note: 'Documents available',
        },
      ];
    }

    const liveRecords = data.queueItems.length + data.recentItems.length;
    data.insightItems = [
      {
        title: 'Records Returned',
        subtitle: `${liveRecords} live records were loaded for ${sectionKey}.`,
        meta: 'LIVE',
        status: liveRecords > 0 ? 'ACTIVE' : 'EMPTY',
      },
      {
        title: 'Last Refreshed',
        subtitle: 'Generated directly from current database state.',
        meta: startOfDay.toISOString().split('T')[0],
        status: 'OK',
      },
    ];

    return data;
  }
}
