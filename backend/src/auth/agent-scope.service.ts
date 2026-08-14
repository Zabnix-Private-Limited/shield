import { ForbiddenException, Injectable } from '@nestjs/common';
import type { ShieldPrincipal } from './auth.types';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AgentScopeService {
  constructor(private readonly prisma: PrismaService) {}

  isAgentPrincipal(principal?: ShieldPrincipal) {
    return (
      principal?.principalType === 'USER' &&
      principal.roleCode?.trim().toUpperCase() === 'SHIELD_AGENT'
    );
  }

  async resolveAgentContext(principal?: ShieldPrincipal) {
    if (!this.isAgentPrincipal(principal) || !principal?.userId) {
      return null;
    }

    const user = await this.prisma.user.findUnique({
      where: { id: BigInt(principal.userId) },
      select: {
        id: true,
        employeeCode: true,
        firstName: true,
        lastName: true,
        email: true,
        mobile: true,
        status: true,
      },
    });

    if (!user?.employeeCode?.trim()) {
      throw new ForbiddenException(
        'Agent scope is not configured for this internal user.',
      );
    }

    return {
      userId: user.id,
      agentCode: user.employeeCode.trim(),
      displayName: `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim(),
      email: user.email?.trim() ?? null,
      mobile: user.mobile?.trim() ?? null,
      status: user.status?.trim() ?? 'ACTIVE',
    };
  }

  async resolveAgentCode(principal?: ShieldPrincipal) {
    const context = await this.resolveAgentContext(principal);
    return context?.agentCode;
  }

  async listAccessibleCustomerIds(
    principal: ShieldPrincipal | undefined,
    candidateCustomerIds?: bigint[],
  ) {
    if (!this.isAgentPrincipal(principal)) {
      return candidateCustomerIds ?? [];
    }

    const agentCode = await this.resolveAgentCode(principal);
    if (!agentCode) {
      return [];
    }

    const rows = await this.prisma.customer.findMany({
      where: {
        agentCode,
        deletedAt: null,
        ...(candidateCustomerIds != null
          ? { id: { in: candidateCustomerIds } }
          : {}),
      },
      select: { id: true },
      orderBy: { id: 'asc' },
    });

    return rows.map((row) => row.id);
  }

  async assertAgentCanAccessCustomer(
    customerId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
      return;
    }

    const customerIds = await this.listAccessibleCustomerIds(principal, [
      customerId,
    ]);
    if (!customerIds.some((value) => value === customerId)) {
      throw new ForbiddenException(
        'You are not authorized to access this customer.',
      );
    }
  }

  async assertAgentCanAccessAppointment(
    appointmentId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
      return;
    }

    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      select: { customerId: true },
    });

    if (!appointment?.customerId) {
      throw new ForbiddenException(
        'You are not authorized to access this appointment.',
      );
    }

    await this.assertAgentCanAccessCustomer(appointment.customerId, principal);
  }

  async assertAgentCanAccessDocument(
    documentId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
      return;
    }

    const document = await this.prisma.document.findUnique({
      where: { id: documentId },
      select: { customerId: true },
    });

    if (!document?.customerId) {
      throw new ForbiddenException(
        'You are not authorized to access this document.',
      );
    }

    await this.assertAgentCanAccessCustomer(document.customerId, principal);
  }

  async assertAgentCanAccessNotification(
    notificationId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
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

    await this.assertAgentCanAccessCustomer(notification.customerId, principal);
  }

  async assertAgentCanAccessWalletByCustomer(
    customerId: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.assertAgentCanAccessCustomer(customerId, principal);
  }

  async assertAgentCanAccessWallet(
    walletId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
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

    await this.assertAgentCanAccessCustomer(wallet.customerId, principal);
  }

  async assertAgentCanAccessCrmTask(
    taskId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
      return;
    }

    const task = await this.prisma.crmTask.findUnique({
      where: { id: taskId },
      select: { customerId: true, assignedTo: true },
    });

    if (!task) {
      throw new ForbiddenException(
        'You are not authorized to access this task.',
      );
    }

    if (principal?.userId && task.assignedTo === BigInt(principal.userId)) {
      if (task.customerId) {
        await this.assertAgentCanAccessCustomer(task.customerId, principal);
      }
      return;
    }

    if (task.customerId) {
      await this.assertAgentCanAccessCustomer(task.customerId, principal);
      return;
    }

    throw new ForbiddenException('You are not authorized to access this task.');
  }

  async assertAgentCanAccessCrmActivity(
    activityId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
      return;
    }

    const activity = await this.prisma.crmActivity.findUnique({
      where: { id: activityId },
      select: { customerId: true },
    });

    if (!activity?.customerId) {
      throw new ForbiddenException(
        'You are not authorized to access this follow-up record.',
      );
    }

    await this.assertAgentCanAccessCustomer(activity.customerId, principal);
  }

  async assertAgentCanAccessComplaint(
    complaintId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (!this.isAgentPrincipal(principal)) {
      return;
    }
    const complaint = await this.prisma.complaint.findUnique({
      where: { id: complaintId },
      select: { customerId: true },
    });
    if (!complaint?.customerId) {
      throw new ForbiddenException(
        'You are not authorized to access this complaint.',
      );
    }
    await this.assertAgentCanAccessCustomer(complaint.customerId, principal);
  }
}
