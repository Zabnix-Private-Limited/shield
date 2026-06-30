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

  async getConsultationWorkspace(id: bigint) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
      include: {
        customer: true,
        provider: {
          include: {
            business: true,
          },
        },
        consultations: {
          include: {
            prescriptions: true,
          },
          orderBy: [{ id: 'desc' }],
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException(`Appointment with ID ${id.toString()} not found`);
    }

    return this.buildConsultationWorkspacePayload(appointment);
  }

  async startConsultation(id: bigint) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
      include: {
        customer: true,
        provider: {
          include: {
            business: true,
          },
        },
        consultations: {
          include: {
            prescriptions: true,
          },
          orderBy: [{ id: 'desc' }],
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException(`Appointment with ID ${id.toString()} not found`);
    }

    await this.ensureConsultationRecord(appointment, undefined);

    if (!this.isCompletedAppointmentStatus(appointment.status)) {
      await this.prisma.appointment.update({
        where: { id: appointment.id },
        data: { status: 'IN_PROGRESS' },
      });
    }

    return this.getConsultationWorkspace(id);
  }

  async saveConsultation(
    id: bigint,
    data: {
      symptoms?: string;
      diagnosis?: string;
      advice?: string;
      followUp?: string;
      notes?: string;
    },
  ) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
      include: {
        customer: true,
        provider: {
          include: {
            business: true,
          },
        },
        consultations: {
          include: {
            prescriptions: true,
          },
          orderBy: [{ id: 'desc' }],
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException(`Appointment with ID ${id.toString()} not found`);
    }

    await this.ensureConsultationRecord(appointment, data);

    if (!this.isCompletedAppointmentStatus(appointment.status)) {
      await this.prisma.appointment.update({
        where: { id: appointment.id },
        data: { status: 'IN_PROGRESS' },
      });
    }

    return this.getConsultationWorkspace(id);
  }

  async completeConsultation(
    id: bigint,
    data: {
      symptoms?: string;
      diagnosis?: string;
      advice?: string;
      followUp?: string;
      notes?: string;
    },
  ) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
      include: {
        customer: true,
        provider: {
          include: {
            business: true,
          },
        },
        consultations: {
          include: {
            prescriptions: true,
          },
          orderBy: [{ id: 'desc' }],
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException(`Appointment with ID ${id.toString()} not found`);
    }

    await this.ensureConsultationRecord(appointment, data);

    await this.prisma.appointment.update({
      where: { id: appointment.id },
      data: { status: 'COMPLETED' },
    });

    return this.getConsultationWorkspace(id);
  }

  private async ensureConsultationRecord(
    appointment: {
      id: bigint;
      customerId: bigint | null;
      status: string | null;
      provider?: { providerName: string | null } | null;
      consultations?: Array<{
        id: bigint;
        diagnosis: string | null;
        notes: string | null;
      }>;
    },
    data?: {
      symptoms?: string;
      diagnosis?: string;
      advice?: string;
      followUp?: string;
      notes?: string;
    },
  ) {
    const existing = appointment.consultations?.[0];
    const existingForm = this.parseStructuredConsultationNotes(existing?.notes);
    const mergedForm = {
      symptoms: this.normalizeText(data?.symptoms, existingForm.symptoms),
      advice: this.normalizeText(data?.advice, existingForm.advice),
      followUp: this.normalizeText(data?.followUp, existingForm.followUp),
      notes: this.normalizeText(data?.notes, existingForm.notes),
    };

    if (existing) {
      return this.prisma.consultation.update({
        where: { id: existing.id },
        data: {
          doctorName: appointment.provider?.providerName ?? existing.id.toString(),
          diagnosis: this.normalizeText(data?.diagnosis, existing.diagnosis ?? ''),
          notes: this.serializeStructuredConsultationNotes(mergedForm),
        },
      });
    }

    return this.prisma.consultation.create({
      data: {
        customerId: appointment.customerId,
        appointmentId: appointment.id,
        doctorName: appointment.provider?.providerName ?? 'Provider',
        diagnosis: this.normalizeText(data?.diagnosis),
        notes: this.serializeStructuredConsultationNotes(mergedForm),
      },
    });
  }

  private buildConsultationWorkspacePayload(appointment: {
    id: bigint;
    appointmentType: string | null;
    appointmentDate: Date | null;
    status: string | null;
    remarks: string | null;
    customer?: { firstName: string | null; lastName: string | null } | null;
    provider?:
      | {
          providerName: string | null;
          providerType?: string | null;
          business?: { name: string | null } | null;
        }
      | null;
    consultations?: Array<{
      id: bigint;
      diagnosis: string | null;
      notes: string | null;
      prescriptions?: Array<{ id: bigint }>;
    }>;
  }) {
    const consultation = appointment.consultations?.[0];
    const form = this.parseStructuredConsultationNotes(consultation?.notes);
    const statusCode = (appointment.status ?? 'PENDING').toUpperCase();
    const patientName =
      appointment.customer
        ? `${appointment.customer.firstName ?? ''} ${appointment.customer.lastName ?? ''}`.trim()
        : 'Patient';
    const visitTitle = `${this.getAppointmentTypeLabel(appointment.appointmentType)} for ${patientName}`;
    const statusLabel = this.getAppointmentStatusLabel(statusCode);
    const timeline = this.buildConsultationTimeline(appointment, consultation, form);

    return {
      appointmentId: appointment.id.toString(),
      consultationId: consultation?.id?.toString() ?? null,
      statusCode,
      statusLabel,
      visit: {
        title: visitTitle,
        subtitle: `${appointment.provider?.providerName ?? 'Provider'} • ${appointment.provider?.business?.name ?? 'Branch not assigned'}`,
        appointmentTypeLabel: this.getAppointmentTypeLabel(appointment.appointmentType),
        appointmentDateLabel: this.formatDateTime(appointment.appointmentDate),
        reason: appointment.remarks?.trim() || 'Visit reason has not been recorded yet.',
        prescriptionCount: consultation?.prescriptions?.length ?? 0,
      },
      actions: this.buildConsultationActions(statusCode),
      formSections: [
        {
          code: 'symptoms',
          title: 'Symptoms',
          placeholder: 'Record what the patient is experiencing in plain language.',
          order: 1,
        },
        {
          code: 'diagnosis',
          title: 'Diagnosis',
          placeholder: 'Record the clinical finding or working diagnosis.',
          order: 2,
        },
        {
          code: 'advice',
          title: 'Advice',
          placeholder: 'Record the care advice or treatment guidance shared with the patient.',
          order: 3,
        },
        {
          code: 'followUp',
          title: 'Follow-up',
          placeholder: 'Record the next visit, review window, or additional action needed.',
          order: 4,
        },
        {
          code: 'notes',
          title: 'Clinical Notes',
          placeholder: 'Add provider notes that should stay with this visit.',
          order: 5,
        },
      ],
      form: {
        'symptoms': form.symptoms,
        'diagnosis': consultation?.diagnosis ?? '',
        'advice': form.advice,
        'followUp': form.followUp,
        'notes': form.notes,
      },
      timeline,
    };
  }

  private buildConsultationActions(statusCode: string) {
    if (statusCode === 'COMPLETED') {
      return [
        {
          code: 'SAVE_PROGRESS',
          title: 'Update Visit Notes',
          emphasis: 'secondary',
        },
      ];
    }

    if (statusCode === 'IN_PROGRESS') {
      return [
        {
          code: 'SAVE_PROGRESS',
          title: 'Save Progress',
          emphasis: 'secondary',
        },
        {
          code: 'COMPLETE_VISIT',
          title: 'Complete Visit',
          emphasis: 'primary',
        },
      ];
    }

    return [
      {
        code: 'START_CONSULTATION',
        title: 'Start Consultation',
        emphasis: 'primary',
      },
      {
        code: 'SAVE_PROGRESS',
        title: 'Save Notes',
        emphasis: 'secondary',
      },
    ];
  }

  private buildConsultationTimeline(
    appointment: {
      appointmentDate: Date | null;
      status: string | null;
      remarks: string | null;
    },
    consultation:
      | {
          diagnosis: string | null;
          notes: string | null;
        }
      | undefined,
    form: {
      symptoms: string;
      advice: string;
      followUp: string;
      notes: string;
    },
  ) {
    const timestamp = appointment.appointmentDate ?? new Date();
    const items = [
      {
        code: 'APPOINTMENT',
        title: 'Visit scheduled',
        subtitle: appointment.remarks?.trim() || 'Visit has been added to the provider schedule.',
        timestamp: timestamp.toISOString(),
      },
    ];

    if (this.isConsultationStarted(appointment.status, consultation)) {
      items.push({
        code: 'CONSULTATION',
        title: 'Consultation started',
        subtitle: 'Provider visit is in progress.',
        timestamp: timestamp.toISOString(),
      });
    }

    if ((consultation?.diagnosis ?? '').trim().length > 0) {
      items.push({
        code: 'DIAGNOSIS',
        title: 'Diagnosis recorded',
        subtitle: consultation?.diagnosis?.trim() ?? '',
        timestamp: timestamp.toISOString(),
      });
    }

    if (form.advice.trim().length > 0) {
      items.push({
        code: 'ADVICE',
        title: 'Care advice updated',
        subtitle: form.advice.trim(),
        timestamp: timestamp.toISOString(),
      });
    }

    if (form.followUp.trim().length > 0) {
      items.push({
        code: 'FOLLOW_UP',
        title: 'Follow-up planned',
        subtitle: form.followUp.trim(),
        timestamp: timestamp.toISOString(),
      });
    }

    if (this.isCompletedAppointmentStatus(appointment.status)) {
      items.push({
        code: 'COMPLETED',
        title: 'Visit completed',
        subtitle: 'This patient visit has been marked as completed.',
        timestamp: timestamp.toISOString(),
      });
    }

    return items;
  }

  private isConsultationStarted(
    appointmentStatus?: string | null,
    consultation?: { diagnosis: string | null; notes: string | null } | undefined,
  ) {
    if ((appointmentStatus ?? '').toUpperCase() === 'IN_PROGRESS') {
      return true;
    }
    return Boolean(
      consultation &&
        (((consultation.diagnosis ?? '').trim().length > 0) ||
          ((consultation.notes ?? '').trim().length > 0)),
    );
  }

  private isCompletedAppointmentStatus(status?: string | null) {
    return (status ?? '').trim().toUpperCase() === 'COMPLETED';
  }

  private parseStructuredConsultationNotes(notes?: string | null) {
    const fallback = {
      symptoms: '',
      advice: '',
      followUp: '',
      notes: '',
    };

    const raw = notes?.trim() ?? '';
    if (!raw) {
      return fallback;
    }

    try {
      const parsed = JSON.parse(raw) as Record<string, unknown>;
      return {
        symptoms: this.normalizeText(parsed.symptoms),
        advice: this.normalizeText(parsed.advice),
        followUp: this.normalizeText(parsed.followUp),
        notes: this.normalizeText(parsed.notes),
      };
    } catch {
      return {
        ...fallback,
        notes: raw,
      };
    }
  }

  private serializeStructuredConsultationNotes(data: {
    symptoms?: string;
    advice?: string;
    followUp?: string;
    notes?: string;
  }) {
    return JSON.stringify({
      symptoms: this.normalizeText(data.symptoms),
      advice: this.normalizeText(data.advice),
      followUp: this.normalizeText(data.followUp),
      notes: this.normalizeText(data.notes),
    });
  }

  private normalizeText(value?: unknown, fallback = '') {
    const text = value?.toString().trim();
    return text && text.length > 0 ? text : fallback;
  }

  private getAppointmentTypeLabel(type?: string | null) {
    switch ((type ?? '').trim().toUpperCase()) {
      case 'DENTAL':
        return 'Dental Visit';
      case 'HOME_VISIT':
      case 'HOMECARE':
        return 'Home Visit';
      case 'LAB':
      case 'LABORATORY':
        return 'Laboratory Visit';
      case 'CONSULTATION':
      case 'DOCTOR':
      case 'CLINIC':
      default:
        return 'Consultation';
    }
  }

  private getAppointmentStatusLabel(status?: string | null) {
    switch ((status ?? '').trim().toUpperCase()) {
      case 'PENDING':
        return 'Waiting';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'CHECKED_IN':
        return 'Checked In';
      case 'IN_PROGRESS':
        return 'Consultation in Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status?.replaceAll('_', ' ') ?? 'Appointment';
    }
  }

  private formatDateTime(value?: Date | null) {
    if (!value) {
      return 'Time not scheduled';
    }
    const day = value.getDate().toString().padStart(2, '0');
    const month = value.toLocaleString('en-US', { month: 'short' });
    const year = value.getFullYear();
    let hour = value.getHours() % 12;
    if (hour === 0) {
      hour = 12;
    }
    const minute = value.getMinutes().toString().padStart(2, '0');
    const suffix = value.getHours() >= 12 ? 'PM' : 'AM';
    return `${day} ${month} ${year} • ${hour}:${minute} ${suffix}`;
  }
}
