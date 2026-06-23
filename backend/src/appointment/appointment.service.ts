import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class AppointmentService {
  constructor(private prisma: PrismaService) {}

  async list(customerId?: bigint) {
    const whereClause: any = {};
    if (customerId) {
      whereClause.customerId = customerId;
    }
    return this.prisma.appointment.findMany({
      where: whereClause,
      include: {
        customer: true,
        provider: true,
      },
      orderBy: { appointmentDate: 'desc' },
    });
  }

  async create(data: any) {
    return this.prisma.appointment.create({
      data: {
        uuid: randomUUID(),
        customerId: BigInt(data.customer_id),
        providerId: BigInt(data.provider_id),
        appointmentType: data.appointment_type,
        appointmentDate: new Date(data.appointment_date),
        status: data.status || 'PENDING',
        remarks: data.remarks || data.notes,
      },
    });
  }

  async findOne(id: bigint) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id },
      include: {
        customer: true,
        provider: true,
        consultations: true,
      },
    });
    if (!appt) {
      throw new NotFoundException(`Appointment with ID ${id} not found`);
    }
    return appt;
  }

  async cancel(id: bigint) {
    const appt = await this.findOne(id);
    return this.prisma.appointment.update({
      where: { id: appt.id },
      data: { status: 'CANCELLED' },
    });
  }

  async confirm(id: bigint) {
    const appt = await this.findOne(id);
    return this.prisma.appointment.update({
      where: { id: appt.id },
      data: { status: 'CONFIRMED' },
    });
  }
}
