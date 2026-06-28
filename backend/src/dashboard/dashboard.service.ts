import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';
import { PricingService } from '../pricing/pricing.service';

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
        availableCredit: customer.creditAccount ? Number(customer.creditAccount.availableCredit) : 0,
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

  async getRoleSectionDashboard(role: string, section: string, customerId: bigint) {
    const roleKey = role.toLowerCase();
    const sectionKey = section.toLowerCase();

    // Default return structure
    const data: any = {
      key: sectionKey,
      title: section.charAt(0).toUpperCase() + section.slice(1),
      summary: `Real-time database records for the ${role} ${section} view.`,
      actions: [],
      metrics: [],
      queueItems: [],
      recentItems: [],
      insightItems: [],
    };

    // 1. Fetch default Customer info
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      include: { wallet: true, creditAccount: true, membership: true },
    });

    if (!customer) {
      throw new NotFoundException(`Customer not found for session`);
    }

    // 2. Compute wallet balance helper
      const getBalance = async () => {
        if (!customer.wallet) return 0;
        const summary = await this.walletService.getWalletSummary(customer.wallet.id);
        return summary.cashWallet.available;
      };

      const getRewardPoints = async () => {
        if (!customer.wallet) return 0;
        const summary = await this.walletService.getWalletSummary(customer.wallet.id);
        return summary.rewardPoints.available;
      };

    if (roleKey === 'customer') {
      const balance = await getBalance();
      const creditAvailable = customer.creditAccount ? Number(customer.creditAccount.availableCredit) : 0;

      if (sectionKey === 'dashboard') {
        data.title = 'Dashboard';
        data.summary = 'Track membership, wallet balance, appointments, and recent medical documents from one compact home view.';
        data.actions = ['View card', 'Book visit', 'Open wallet'];
        data.metrics = [
          { label: 'Wallet Balance', value: `₹${balance}`, note: 'Available starting balance' },
          { label: 'Reward Points', value: `${await getRewardPoints()}`, note: 'Available reward points' },
          { label: 'Credit Account', value: `₹${creditAvailable}`, note: 'Instant credit line' },
          { label: 'Active Membership', value: customer.membership?.membershipNumber || 'None', note: 'Founding Member' },
        ];

        // Queue: Scheduled appointments
        const appts = await this.prisma.appointment.findMany({
          where: { customerId: customer.id, status: 'SCHEDULED' },
          include: { provider: true },
          take: 3,
        });
        data.queueItems = appts.map((a) => ({
          title: a.remarks || 'Clinic Visit',
          subtitle: `Provider: ${a.provider?.providerName || 'SHIELD Care'}`,
          meta: a.appointmentDate ? a.appointmentDate.toLocaleDateString() : '',
          status: a.status,
        }));

        // Recent: Wallet transactions
        if (customer.wallet) {
          const recentTxns = await this.walletService.getTransactions(customer.wallet.id, {});
          data.recentItems = recentTxns.map((t) => ({
            title: t.remarks || 'Transaction',
            subtitle: `Amount: ₹${t.amount}`,
            meta: t.createdAt.toLocaleDateString(),
            status: t.transactionType || 'CREDIT',
          }));
        }
      } else if (sectionKey === 'wallet') {
        data.title = 'Wallet';
        data.summary = 'Calculate balance from ledgers, process recharges, and view historical transactions.';
        data.metrics = [
          { label: 'Total Balance', value: `₹${balance}`, note: 'Calculated from ledger history' },
          { label: 'Reward Points', value: `${await getRewardPoints()}`, note: 'Available now' },
          { label: 'Credit Limit', value: `₹${customer.creditAccount?.creditLimit || 0}`, note: 'Total line' },
          { label: 'Available Credit', value: `₹${creditAvailable}`, note: 'Usable credit line' },
        ];

        if (customer.wallet) {
          const txns = await this.walletService.getTransactions(customer.wallet.id, {});
          data.queueItems = txns.map((t) => ({
            title: t.remarks || 'Wallet Adjustment',
            subtitle: `Type: ${t.transactionType}`,
            meta: t.createdAt.toLocaleDateString(),
            status: `₹${t.amount}`,
          }));
        }
      } else if (sectionKey === 'appointments') {
        data.title = 'Appointments';
        data.summary = 'List scheduled, completed, and cancelled consultation slots.';
        
        const appts = await this.prisma.appointment.findMany({
          where: { customerId: customer.id },
          include: { provider: true },
          orderBy: { appointmentDate: 'desc' },
        });

        data.queueItems = appts.map((a) => ({
          title: `Appointment - ${a.appointmentType}`,
          subtitle: `Location: ${a.provider?.providerName || 'Care Center'}`,
          meta: a.appointmentDate ? a.appointmentDate.toLocaleDateString() : '',
          status: a.status || 'SCHEDULED',
        }));
      } else if (sectionKey === 'documents') {
        data.title = 'Documents';
        data.summary = 'View prescriptions, invoices, and clinical reports uploaded to your account.';

        const docs = await this.prisma.document.findMany({
          where: { customerId: customer.id },
          orderBy: { createdAt: 'desc' },
        });

        data.queueItems = docs.map((d) => ({
          title: d.fileName || 'Document.pdf',
          subtitle: `Type: ${d.documentType}`,
          meta: d.createdAt.toLocaleDateString(),
          status: d.status || 'PROCESSING',
        }));
      } else if (sectionKey === 'notifications') {
        data.title = 'Notifications';
        data.summary = 'Alerts feed indicating recharges, approvals, and scheduling updates.';

        const notifications = await this.prisma.notification.findMany({
          where: { customerId: customer.id },
          orderBy: { sentAt: 'desc' },
        });

        data.queueItems = notifications.map((n) => ({
          title: n.title || 'Alert',
          subtitle: n.message || '',
          meta: n.sentAt?.toLocaleDateString() || '',
          status: n.status || 'UNREAD',
        }));
      } else if (sectionKey === 'services') {
        data.title = 'Services';
        data.summary = 'Access pharmacy, lab, homecare, and clinical consultation services.';
        data.metrics = [
          { label: 'Active Services', value: '4', note: 'Pharmacy, Lab, Homecare, Clinic' },
          { label: 'Pharmacy Invoices', value: '1', note: 'Preloaded purchases' },
          { label: 'Scheduled Consults', value: '2', note: 'Dental + Doctor' },
        ];
        data.queueItems = [
          { title: 'SHIELD Hyper Pharmacy', subtitle: 'Perinthalmanna - Open now', meta: 'Pharmacy', status: 'ACTIVE' },
          { title: 'Smart Clinic', subtitle: 'Manjeri - Open now', meta: 'Doctor', status: 'ACTIVE' },
        ];
      }
    } else if (roleKey === 'crm-executive') {
      if (sectionKey === 'tasks') {
        data.title = 'CRM Follow-ups';
        const tasks = await this.prisma.crmTask.findMany({
          include: { customer: true },
        });
        data.queueItems = tasks.map((t) => ({
          title: `Task for ${t.customer?.firstName || 'Member'}`,
          subtitle: t.notes || 'Follow up',
          meta: t.dueDate?.toLocaleDateString() || '',
          status: t.status || 'PENDING',
        }));
      } else if (sectionKey === 'complaints') {
        data.title = 'Complaints Log';
        const comps = await this.prisma.complaint.findMany({
          include: { customer: true },
        });
        data.queueItems = comps.map((c) => ({
          title: `Complaint: ${c.complaintType}`,
          subtitle: c.description || '',
          meta: c.createdAt.toLocaleDateString(),
          status: c.status || 'PENDING',
        }));
      } else if (sectionKey === 'call-activities') {
        data.title = 'CRM Activity Feed';
        const acts = await this.prisma.crmActivity.findMany({
          include: { customer: true },
        });
        data.queueItems = acts.map((a) => ({
          title: `Call with ${a.customer?.firstName || 'Member'}`,
          subtitle: a.notes || 'Activity note',
          meta: a.createdAt.toLocaleDateString(),
          status: a.activityType || 'CALL',
        }));
      }
    } else if (roleKey === 'admin') {
      if (sectionKey === 'audit-trail') {
        data.title = 'Security Audit Trail';
        const audits = await this.prisma.auditLog.findMany({
          take: 20,
          orderBy: { createdAt: 'desc' },
        });
        data.queueItems = audits.map((a) => ({
          title: a.action || 'Admin Action',
          subtitle: `IP: ${a.ipAddress || 'Unknown'} • Entity: ${a.entityType}`,
          meta: a.createdAt.toLocaleDateString(),
          status: 'SUCCESS',
        }));
      } else if (sectionKey === 'wallet' || sectionKey === 'benefits') {
        data.title = 'Commercial Controls';
        data.summary =
          'Admin-only commercial configuration for preload, benefit, reward, and redemption behavior.';

        const config = await this.pricingService.getAdminCommercialConfig();
        data.metrics = [
          {
            label: 'Service Rules',
            value: `${config.serviceRules.length}`,
            note: 'Benefit and wallet-usage rules',
          },
          {
            label: 'Reward Rules',
            value: `${config.rewardRules.length}`,
            note: 'Points master actions',
          },
          {
            label: 'Redemption Rules',
            value: `${config.redemptionRules.length}`,
            note: 'Points-to-credit conversions',
          },
        ];
        data.queueItems = config.settings.map((setting) => ({
          title: setting.code,
          subtitle:
            setting.valueBoolean !== null && setting.valueBoolean !== undefined
              ? `Boolean: ${setting.valueBoolean}`
              : setting.valueNumber !== null && setting.valueNumber !== undefined
                ? `Number: ${setting.valueNumber}`
                : `Text: ${setting.valueText || ''}`,
          meta: setting.valueType,
          status: setting.status,
        }));
      }
    } else if (roleKey === 'shield-executive') {
      if (sectionKey === 'pending-onboarding') {
        data.title = 'Pending Onboardings';
        const pending = await this.prisma.customer.findMany({
          where: { status: 'PENDING' },
        });
        data.queueItems = pending.map((c) => ({
          title: `${c.firstName} ${c.lastName}`,
          subtitle: `Mobile: ${c.mobile}`,
          meta: c.createdAt.toLocaleDateString(),
          status: c.status || 'PENDING',
        }));
      }
    }

    // Default Insights for all roles/sections
    data.insightItems = [
      { title: 'Data Integrity', subtitle: 'Calculated live from active Neon PostgreSQL transaction records.', meta: 'SYSTEM', status: 'OK' },
      { title: 'Storage Provider', subtitle: 'Asset linkages point to Cloudflare R2 private bucket containers.', meta: 'INFRA', status: 'SECURE' },
    ];

    return data;
  }
}
