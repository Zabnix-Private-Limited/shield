import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type SupportSubmissionInput = {
  complaintType: 'CONTACT_US' | 'FEEDBACK';
  customerId?: bigint;
  name?: string;
  phone?: string;
  email?: string;
  subject?: string;
  message: string;
  rating?: number;
  channel?: string;
  turnstileValidated: boolean;
};

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  async submit(input: SupportSubmissionInput) {
    const summary = [
      `Type: ${input.complaintType}`,
      `Channel: ${(input.channel ?? 'UNKNOWN').toUpperCase()}`,
      `Turnstile Validated: ${input.turnstileValidated ? 'Yes' : 'No'}`,
      input.name ? `Name: ${input.name}` : null,
      input.phone ? `Phone: ${input.phone}` : null,
      input.email ? `Email: ${input.email}` : null,
      input.subject ? `Subject: ${input.subject}` : null,
      input.rating != null ? `Rating: ${input.rating}/5` : null,
      'Message:',
      input.message,
    ]
      .filter((value): value is string => typeof value === 'string')
      .join('\n');

    return this.prisma.complaint.create({
      data: {
        customerId: input.customerId,
        complaintType: input.complaintType,
        description: summary,
        status: 'SUBMITTED',
      },
    });
  }

  async submitForCustomer(
    customerId: bigint,
    input: { subject?: string; message: string; complaintType?: string },
  ) {
    const message = input.message.trim();
    if (!message) {
      throw new Error('Support message is required.');
    }
    return this.prisma.complaint.create({
      data: {
        customerId,
        complaintType:
          input.complaintType?.trim().toUpperCase() || 'SUPPORT_REQUEST',
        description: [
          input.subject?.trim() ? `Subject: ${input.subject.trim()}` : null,
          message,
        ]
          .filter((value): value is string => Boolean(value))
          .join('\n'),
        status: 'SUBMITTED',
      },
    });
  }

  async listForCustomer(customerId: bigint) {
    return this.prisma.complaint.findMany({
      where: { customerId },
      select: {
        id: true,
        complaintType: true,
        description: true,
        status: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
