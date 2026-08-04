import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  commissionBreakdown,
  monthlySubscriptionAllocations,
} from '../common/management-demo-calculations';
import { PrismaService } from '../prisma/prisma.service';

const planPaise = { contribution: 1000000n, benefit: 100000n };

@Injectable()
export class ManagementDemoService {
  constructor(private readonly prisma: PrismaService) {}

  subscriptionPreview(carryForwardPaise = 0n, usedPaise = 0n) {
    const allocations = monthlySubscriptionAllocations(
      planPaise.contribution + planPaise.benefit,
    );
    const currentAllocationPaise = allocations[new Date().getMonth()];
    return {
      planName: 'SHIELD Privilege Plan',
      customerContributionPaise: planPaise.contribution,
      shieldBenefitPaise: planPaise.benefit,
      totalEntitlementPaise: planPaise.contribution + planPaise.benefit,
      monthlyAllocationPaise: currentAllocationPaise,
      availablePaise: carryForwardPaise + currentAllocationPaise,
      carryForwardPaise,
      usedPaise,
      remainingPaise: carryForwardPaise + currentAllocationPaise - usedPaise,
      allocations,
    };
  }

  async activateSubscription(customerId: bigint, startsOn = new Date()) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      include: { membership: true },
    });
    if (!customer) throw new NotFoundException('Customer not found.');
    const endsOn = new Date(startsOn);
    endsOn.setFullYear(endsOn.getFullYear() + 1);
    const subscription = await this.prisma.membershipSubscription.upsert({
      where: { customerId },
      update: { status: 'ACTIVE', startsOn, endsOn },
      create: {
        uuid: randomUUID(),
        customerId,
        membershipId: customer.membership?.id,
        planName: 'SHIELD Privilege Plan',
        customerContributionPaise: planPaise.contribution,
        shieldBenefitPaise: planPaise.benefit,
        totalEntitlementPaise: planPaise.contribution + planPaise.benefit,
        status: 'ACTIVE',
        startsOn,
        endsOn,
      },
    });
    const allocations = monthlySubscriptionAllocations(
      planPaise.contribution + planPaise.benefit,
    );
    await this.prisma.subscriptionMonthlyAllocation.deleteMany({
      where: { subscriptionId: subscription.id },
    });
    await this.prisma.subscriptionMonthlyAllocation.createMany({
      data: allocations.map((allocationPaise, index) => ({
        subscriptionId: subscription.id,
        monthStart: new Date(
          startsOn.getFullYear(),
          startsOn.getMonth() + index,
          1,
        ),
        allocationPaise,
      })),
    });
    return this.getSubscription(customerId);
  }

  async getSubscription(customerId: bigint) {
    const subscription = await this.prisma.membershipSubscription.findUnique({
      where: { customerId },
    });
    if (!subscription) return null;
    const allocations =
      await this.prisma.subscriptionMonthlyAllocation.findMany({
        where: { subscriptionId: subscription.id },
        orderBy: { monthStart: 'asc' },
      });
    const current =
      allocations.find(
        (item) => item.monthStart.getMonth() === new Date().getMonth(),
      ) ?? allocations[0];
    const currentMonth = current
      ? {
          ...current,
          availablePaise: current.allocationPaise + current.carryForwardPaise,
          remainingPaise:
            current.allocationPaise +
            current.carryForwardPaise -
            current.usedPaise,
        }
      : null;
    return { subscription, allocations, currentMonth };
  }

  commissionPreview(poolPaise: bigint, originatingLevel: string) {
    if (poolPaise < 0n)
      throw new BadRequestException('Commission pool cannot be negative.');
    return {
      poolPaise,
      originatingLevel: originatingLevel.toUpperCase(),
      allocations: commissionBreakdown(poolPaise, originatingLevel),
    };
  }

  async createCommissionEvent(args: {
    customerId?: bigint;
    sourceType: string;
    originatingLevel: string;
    poolPaise: bigint;
    createdBy?: bigint;
  }) {
    const preview = this.commissionPreview(
      args.poolPaise,
      args.originatingLevel,
    );
    return this.prisma.$transaction(async (tx) => {
      const event = await tx.commissionEvent.create({
        data: {
          uuid: randomUUID(),
          customerId: args.customerId,
          sourceType: args.sourceType,
          originatingLevel: preview.originatingLevel,
          poolPaise: args.poolPaise,
          status: 'PENDING',
          createdBy: args.createdBy,
        },
      });
      await tx.commissionAllocation.createMany({
        data: preview.allocations.map((item) => ({
          commissionEventId: event.id,
          recipientLevel: item.recipientLevel,
          percentage: item.percentage,
          amountPaise: item.amountPaise,
          status: 'PENDING',
        })),
      });
      return event;
    });
  }

  async listCommissionHistory(customerId?: bigint) {
    const events = await this.prisma.commissionEvent.findMany({
      where: customerId ? { customerId } : undefined,
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    const allocations = await this.prisma.commissionAllocation.findMany({
      where: { commissionEventId: { in: events.map((event) => event.id) } },
      orderBy: { id: 'asc' },
    });
    return events.map((event) => ({
      ...event,
      allocations: allocations.filter(
        (allocation) => allocation.commissionEventId === event.id,
      ),
    }));
  }

  async listCustomerActivities(customerId: bigint) {
    return this.prisma.activityEvent.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }
}
