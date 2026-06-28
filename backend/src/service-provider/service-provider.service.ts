import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class ServiceProviderService {
  constructor(private readonly prisma: PrismaService) {}

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
}
