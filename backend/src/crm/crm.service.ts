import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class CrmService {
  constructor(private prisma: PrismaService) {}

  async listActivities(customerId?: bigint, customerIds?: bigint[]) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    } else if (customerIds !== undefined) {
      whereClause.customerId = { in: customerIds };
    }
    return this.prisma.crmActivity.findMany({
      where: whereClause,
      include: {
        customer: true,
        createdByUser: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createActivity(data: { customerId: bigint; activityType: string; notes: string; createdBy: bigint }) {
    return this.prisma.crmActivity.create({
      data: {
        customerId: data.customerId,
        activityType: data.activityType,
        notes: data.notes,
        createdBy: data.createdBy,
      },
    });
  }

  async listTasks(
    customerId?: bigint,
    assignedTo?: bigint,
    customerIds?: bigint[],
  ) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    } else if (customerIds !== undefined) {
      whereClause.customerId = { in: customerIds };
    }
    if (assignedTo) {
      whereClause.assignedTo = assignedTo;
    }
    return this.prisma.crmTask.findMany({
      where: whereClause,
      include: {
        customer: true,
        assignedToUser: true,
      },
      orderBy: { dueDate: 'asc' },
    });
  }

  async createTask(data: { customerId: bigint; assignedTo: bigint; dueDate: string; notes: string }) {
    return this.prisma.crmTask.create({
      data: {
        customerId: data.customerId,
        assignedTo: data.assignedTo,
        dueDate: new Date(data.dueDate),
        notes: data.notes,
        status: 'PENDING',
      },
    });
  }

  async updateTask(id: bigint, data: { status?: string; notes?: string }) {
    return this.prisma.crmTask.update({
      where: { id },
      data: {
        status: data.status,
        notes: data.notes,
      },
    });
  }

  async listComplaints(customerId?: bigint, customerIds?: bigint[]) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    } else if (customerIds !== undefined) {
      whereClause.customerId = { in: customerIds };
    }
    return this.prisma.complaint.findMany({
      where: whereClause,
      include: {
        customer: true,
        assignedToUser: { select: { id: true, firstName: true, lastName: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createComplaint(data: { customerId: bigint; complaintType: string; description: string }) {
    return this.prisma.complaint.create({
      data: {
        customerId: data.customerId,
        complaintType: data.complaintType,
        description: data.description,
        status: 'PENDING',
      },
    });
  }

  async updateComplaint(id: bigint, data: { status?: string; description?: string }, actorUserId?: bigint) {
    const existing = data.status ? await this.getComplaint(id) : undefined;
    const updated = await this.prisma.complaint.update({
      where: { id },
      data: {
        status: data.status,
        description: data.description,
      },
    });
    if (data.status && data.status !== existing?.status) {
      await this.event({ complaintId: id, eventType: 'STATUS_CHANGED', actorUserId, note: `${existing?.status ?? 'UNKNOWN'} → ${data.status}`, customerVisible: false });
    }
    return updated;
  }

  async getComplaint(id: bigint) {
    const complaint = await this.prisma.complaint.findUnique({
      where: { id },
      include: {
        customer: true,
        assignedToUser: { select: { id: true, firstName: true, lastName: true, email: true } },
        resolvedByUser: { select: { id: true, firstName: true, lastName: true, email: true } },
        lifecycleEvents: { include: { actorUser: { select: { id: true, firstName: true, lastName: true } } }, orderBy: { createdAt: 'asc' } },
      },
    });
    if (!complaint) throw new NotFoundException('Complaint not found');
    return complaint;
  }

  private async event(data: any) {
    return this.prisma.complaintLifecycleEvent.create({ data: { uuid: randomUUID(), ...data } });
  }

  async assignComplaint(id: bigint, targetUserId: bigint, actorUserId: bigint, note?: string) {
    const complaint = await this.getComplaint(id);
    const target = await this.prisma.user.findFirst({ where: { id: targetUserId, deletedAt: null, status: 'ACTIVE' }, select: { id: true } });
    if (!target) throw new BadRequestException('Assignment target must be an active internal user.');
    const eventType = complaint.assignedToUserId ? 'REASSIGNED' : 'ASSIGNED';
    const updated = await this.prisma.complaint.update({ where: { id }, data: { assignedToUserId: targetUserId, assignedAt: new Date() } });
    await this.event({ complaintId: id, eventType, actorUserId, fromAssigneeUserId: complaint.assignedToUserId, toAssigneeUserId: targetUserId, note: note?.trim() || null, customerVisible: false });
    await this.prisma.auditLog.create({ data: { userId: actorUserId, action: eventType === 'ASSIGNED' ? 'COMPLAINT_ASSIGNED' : 'COMPLAINT_REASSIGNED', entityType: 'complaint', entityId: id, newData: { assigneeUserId: targetUserId.toString() } } });
    return updated;
  }

  async addInternalNote(id: bigint, actorUserId: bigint, note: string) {
    if (!note.trim()) throw new BadRequestException('Internal note is required.');
    await this.getComplaint(id);
    return this.event({ complaintId: id, eventType: 'INTERNAL_NOTE_ADDED', actorUserId, note: note.trim(), customerVisible: false });
  }

  async replyToCustomer(id: bigint, actorUserId: bigint, note: string) {
    if (!note.trim()) throw new BadRequestException('Reply is required.');
    await this.getComplaint(id);
    const event = await this.event({ complaintId: id, eventType: 'CUSTOMER_REPLY_ADDED', actorUserId, note: note.trim(), customerVisible: true });
    await this.prisma.auditLog.create({ data: { userId: actorUserId, action: 'COMPLAINT_REPLIED', entityType: 'complaint', entityId: id } });
    return event;
  }

  async escalateComplaint(id: bigint, actorUserId: bigint, reason: string, targetUserId?: bigint) {
    if (!reason.trim()) throw new BadRequestException('Escalation reason is required.');
    const complaint = await this.getComplaint(id);
    if (targetUserId) await this.assignComplaint(id, targetUserId, actorUserId, reason);
    await this.event({ complaintId: id, eventType: 'ESCALATED', actorUserId, fromAssigneeUserId: complaint.assignedToUserId, toAssigneeUserId: targetUserId, note: reason.trim(), customerVisible: false });
    await this.prisma.auditLog.create({ data: { userId: actorUserId, action: 'COMPLAINT_ESCALATED', entityType: 'complaint', entityId: id } });
    return this.getComplaint(id);
  }

  async resolveComplaint(id: bigint, actorUserId: bigint, note: string) {
    if (!note.trim()) throw new BadRequestException('Resolution note is required.');
    const complaint = await this.getComplaint(id);
    if (complaint.status === 'RESOLVED') return complaint;
    const now = new Date();
    const updated = await this.prisma.complaint.update({ where: { id }, data: { status: 'RESOLVED', resolvedByUserId: actorUserId, resolvedAt: now, resolutionNote: note.trim() } });
    await this.event({ complaintId: id, eventType: 'RESOLUTION_NOTE_ADDED', actorUserId, note: note.trim(), customerVisible: true });
    await this.event({ complaintId: id, eventType: 'RESOLVED', actorUserId, note: note.trim(), customerVisible: true });
    await this.prisma.auditLog.create({ data: { userId: actorUserId, action: 'COMPLAINT_RESOLVED', entityType: 'complaint', entityId: id } });
    return updated;
  }
}
