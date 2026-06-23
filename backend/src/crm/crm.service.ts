import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class CrmService {
  constructor(private prisma: PrismaService) {}

  async listActivities(customerId?: bigint) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
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

  async listTasks(customerId?: bigint, assignedTo?: bigint) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
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

  async listComplaints(customerId?: bigint) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    }
    return this.prisma.complaint.findMany({
      where: whereClause,
      include: {
        customer: true,
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

  async updateComplaint(id: bigint, data: { status?: string; description?: string }) {
    return this.prisma.complaint.update({
      where: { id },
      data: {
        status: data.status,
        description: data.description,
      },
    });
  }

  async resolveComplaint(id: bigint) {
    return this.prisma.complaint.update({
      where: { id },
      data: {
        status: 'RESOLVED',
      },
    });
  }
}
