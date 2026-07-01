import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import { PricingService } from '../pricing/pricing.service';
import { SERVICE_TYPES, type ShieldServiceType } from '../pricing/pricing.types';
import { PlatformRealtimeService } from '../platform-capabilities/platform-realtime.service';
import { TimelineService } from '../timeline/timeline.service';
import { WalletService } from '../wallet/wallet.service';

type ConsultationFormState = {
  chiefComplaint: string;
  symptoms: string;
  clinicalFindings: string;
  advice: string;
  procedures: string;
  labOrders: string;
  followUp: string;
  providerNotes: string;
};

type VisitBillingDraftState = {
  consultationFee: number;
  proceduresAmount: number;
  medicinesAmount: number;
  labTestsAmount: number;
  otherServicesAmount: number;
  manualDiscountAmount: number;
  taxPercent: number;
  walletUseAmount: number;
  cashAmount: number;
  upiAmount: number;
  cardAmount: number;
  pendingAmount: number;
  refundAmount: number;
  otherServicesLabel: string;
};

type PaymentSummaryState = {
  walletUsed: number;
  cash: number;
  upi: number;
  card: number;
  pending: number;
  refund: number;
  paidAmount: number;
  balanceDue: number;
  recordedAt: string | null;
};

type StructuredConsultationState = {
  form: ConsultationFormState;
  billingDraft: VisitBillingDraftState;
};

@Injectable()
export class AppointmentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pricingService: PricingService,
    private readonly timelineService: TimelineService,
    private readonly walletService: WalletService,
    private readonly platformRealtimeService: PlatformRealtimeService,
  ) {}

  async list(customerId?: bigint) {
    const whereClause: Record<string, unknown> = {};
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
    const appointment = await this.getWorkspaceAppointment(id);
    return this.buildConsultationWorkspacePayload(appointment);
  }

  async startConsultation(
    id: bigint,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id);

    await this.ensureConsultationRecord(appointment, undefined, undefined);

    if (!this.isCompletedAppointmentStatus(appointment.status)) {
      await this.prisma.appointment.update({
        where: { id: appointment.id },
        data: { status: 'IN_PROGRESS' },
      });
    }

    await this.recordAuditAction({
      action: 'STARTED_VISIT',
      entityType: 'VISIT',
      entityId: appointment.id,
      userId: auditActor?.userId,
      details: {
        appointmentId: appointment.id.toString(),
        actorRole: this.humanizeCode(auditActor?.roleCode),
      },
    });
    this.publishVisitEvent(appointment, 'VISIT_STARTED', 'Visit started', 'Consultation workflow started.');

    return this.getConsultationWorkspace(id);
  }

  async saveConsultation(
    id: bigint,
    data: {
      chiefComplaint?: string;
      symptoms?: string;
      clinicalFindings?: string;
      diagnosis?: string;
      advice?: string;
      procedures?: string;
      labOrders?: string;
      followUp?: string;
      providerNotes?: string;
      notes?: string;
    },
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id);

    await this.ensureConsultationRecord(
      appointment,
      this.normalizeConsultationInput(data),
      undefined,
    );

    if (!this.isCompletedAppointmentStatus(appointment.status)) {
      await this.prisma.appointment.update({
        where: { id: appointment.id },
        data: { status: 'IN_PROGRESS' },
      });
    }

    await this.recordAuditAction({
      action: 'UPDATED_CONSULTATION',
      entityType: 'CONSULTATION',
      entityId: appointment.id,
      userId: auditActor?.userId,
      details: {
        appointmentId: appointment.id.toString(),
        diagnosis: data.diagnosis ?? '',
        actorRole: this.humanizeCode(auditActor?.roleCode),
      },
    });
    this.publishVisitEvent(
      appointment,
      'CONSULTATION_UPDATED',
      'Consultation updated',
      'Consultation details were saved.',
    );

    return this.getConsultationWorkspace(id);
  }

  async saveVisitBillingDraft(
    id: bigint,
    data: Partial<VisitBillingDraftState>,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id);
    await this.ensureConsultationRecord(appointment, undefined, data);

    if (!this.isCompletedAppointmentStatus(appointment.status)) {
      await this.prisma.appointment.update({
        where: { id: appointment.id },
        data: { status: 'IN_PROGRESS' },
      });
    }

    await this.recordAuditAction({
      action: 'UPDATED_VISIT_BILLING',
      entityType: 'BILLING',
      entityId: appointment.id,
      userId: auditActor?.userId,
      details: {
        appointmentId: appointment.id.toString(),
        actorRole: this.humanizeCode(auditActor?.roleCode),
      },
    });
    this.publishVisitEvent(
      appointment,
      'VISIT_BILLING_UPDATED',
      'Visit billing updated',
      'Visit billing draft was saved.',
    );

    return this.getConsultationWorkspace(id);
  }

  async generateVisitInvoice(
    id: bigint,
    input?: {
      formData?: {
        chiefComplaint?: string;
        symptoms?: string;
        clinicalFindings?: string;
        diagnosis?: string;
        advice?: string;
        procedures?: string;
        labOrders?: string;
        followUp?: string;
        providerNotes?: string;
        notes?: string;
      };
      billingDraft?: Partial<VisitBillingDraftState>;
    },
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id);
    await this.ensureConsultationRecord(
      appointment,
      this.normalizeConsultationInput(input?.formData),
      input?.billingDraft,
    );
    await this.upsertVisitInvoice(appointment.id);
    await this.recordAuditAction({
      action: 'GENERATED_INVOICE',
      entityType: 'INVOICE',
      entityId: appointment.id,
      userId: auditActor?.userId,
      details: {
        appointmentId: appointment.id.toString(),
        actorRole: this.humanizeCode(auditActor?.roleCode),
      },
    });
    this.publishVisitEvent(
      appointment,
      'INVOICE_GENERATED',
      'Invoice generated',
      'A visit invoice was generated from the shared billing workflow.',
    );
    return this.getConsultationWorkspace(id);
  }

  async recordVisitPayment(
    id: bigint,
    data: Partial<VisitBillingDraftState>,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id);
    await this.ensureConsultationRecord(appointment, undefined, data);
    await this.upsertVisitInvoice(appointment.id);
    await this.applyVisitPayment(appointment.id);
    await this.recordAuditAction({
      action: 'RECEIVED_PAYMENT',
      entityType: 'PAYMENT',
      entityId: appointment.id,
      userId: auditActor?.userId,
      details: {
        appointmentId: appointment.id.toString(),
        actorRole: this.humanizeCode(auditActor?.roleCode),
      },
    });
    this.publishVisitEvent(
      appointment,
      'PAYMENT_RECORDED',
      'Payment recorded',
      'Visit payment details were recorded.',
    );
    return this.getConsultationWorkspace(id);
  }

  async completeConsultation(
    id: bigint,
    data: {
      chiefComplaint?: string;
      symptoms?: string;
      clinicalFindings?: string;
      diagnosis?: string;
      advice?: string;
      procedures?: string;
      labOrders?: string;
      followUp?: string;
      providerNotes?: string;
      notes?: string;
      billingDraft?: Partial<VisitBillingDraftState>;
    },
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id);

    await this.ensureConsultationRecord(
      appointment,
      this.normalizeConsultationInput(data),
      data.billingDraft,
    );

    const refreshedAppointment = await this.getWorkspaceAppointment(id);
    const consultation = refreshedAppointment.consultations?.[0];
    const state = this.parseStructuredConsultationState(consultation?.notes);
    if (this.computeVisitChargeItems(state).length > 0) {
      await this.upsertVisitInvoice(refreshedAppointment.id);
    }

    await this.prisma.appointment.update({
      where: { id: refreshedAppointment.id },
      data: { status: 'COMPLETED' },
    });

    await this.recordAuditAction({
      action: 'COMPLETED_VISIT',
      entityType: 'VISIT',
      entityId: refreshedAppointment.id,
      userId: auditActor?.userId,
      details: {
        appointmentId: refreshedAppointment.id.toString(),
        diagnosis: data.diagnosis ?? '',
        actorRole: this.humanizeCode(auditActor?.roleCode),
      },
    });
    this.publishVisitEvent(
      refreshedAppointment,
      'VISIT_COMPLETED',
      'Visit completed',
      'Visit workflow was completed.',
    );

    return this.getConsultationWorkspace(id);
  }

  private async getWorkspaceAppointment(id: bigint) {
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
        purchases: {
          include: {
            purchaseItems: {
              include: {
                product: true,
              },
            },
          },
          orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException(`Appointment with ID ${id.toString()} not found`);
    }

    return appointment;
  }

  private async ensureConsultationRecord(
    appointment: {
      id: bigint;
      customerId: bigint | null;
      provider?: { providerName: string | null } | null;
      consultations?: Array<{
        id: bigint;
        diagnosis: string | null;
        notes: string | null;
      }>;
    },
    formData?: Partial<ConsultationFormState> & { diagnosis?: string },
    billingDraft?: Partial<VisitBillingDraftState>,
  ) {
    const existing = appointment.consultations?.[0];
    const existingState = this.parseStructuredConsultationState(existing?.notes);
    const mergedState = {
      form: this.mergeConsultationForm(existingState.form, formData),
      billingDraft: this.mergeBillingDraft(existingState.billingDraft, billingDraft),
    };

    if (existing) {
      return this.prisma.consultation.update({
        where: { id: existing.id },
        data: {
          doctorName: appointment.provider?.providerName ?? 'Provider',
          diagnosis: this.normalizeText(formData?.diagnosis, existing.diagnosis ?? ''),
          notes: this.serializeStructuredConsultationState(mergedState),
        },
      });
    }

    return this.prisma.consultation.create({
      data: {
        customerId: appointment.customerId,
        appointmentId: appointment.id,
        doctorName: appointment.provider?.providerName ?? 'Provider',
        diagnosis: this.normalizeText(formData?.diagnosis),
        notes: this.serializeStructuredConsultationState(mergedState),
      },
    });
  }

  private async upsertVisitInvoice(appointmentId: bigint) {
    const appointment = await this.getWorkspaceAppointment(appointmentId);
    const consultation = appointment.consultations?.[0];
    if (!consultation) {
      throw new BadRequestException('Consultation must be started before billing.');
    }
    if (!appointment.customerId) {
      throw new BadRequestException('Patient is not attached to this visit.');
    }

    const state = this.parseStructuredConsultationState(consultation.notes);
    const lineItems = this.computeVisitChargeItems(state);
    if (lineItems.length === 0) {
      throw new BadRequestException(
        'Add at least one visit charge before generating the invoice.',
      );
    }

    const subtotal = Number(
      lineItems.reduce((sum, item) => sum + item.amount, 0).toFixed(2),
    );
    const manualDiscount = Math.min(
      subtotal,
      Math.max(0, Number(state.billingDraft.manualDiscountAmount || 0)),
    );
    const discountedSubtotal = Number(
      Math.max(0, subtotal - manualDiscount).toFixed(2),
    );
    const serviceType = this.resolveServiceType(appointment);
    const evaluation = await this.pricingService.evaluateServicePrice({
      customerId: appointment.customerId,
      serviceType,
      originalAmount: discountedSubtotal,
      persistAudit: true,
      referenceType: 'APPOINTMENT',
      referenceId: appointment.id,
    });

    const taxPercent = Math.max(0, Number(state.billingDraft.taxPercent || 0));
    const taxAmount = Number(
      ((evaluation.finalPayableAmount * taxPercent) / 100).toFixed(2),
    );
    const grandTotal = Number(
      (evaluation.finalPayableAmount + taxAmount).toFixed(2),
    );
    const payment = this.computePaymentSummary(
      grandTotal,
      state.billingDraft,
      undefined,
    );
    const paymentStatus = this.resolvePaymentStatus(payment);
    const now = new Date();

    const invoiceNumber =
      appointment.purchases?.find((purchase) =>
        this.isVisitPurchase(purchase.purchaseKind),
      )?.invoiceNumber ?? this.buildVisitInvoiceNumber(appointment.id);

    const billingSnapshot = {
      generatedAt: now.toISOString(),
      visitStatus: this.getAppointmentStatusLabel(appointment.status),
      lineItems: lineItems.map((item) => ({
        type: item.type,
        title: item.title,
        description: item.description,
        amount: item.amount,
      })),
      pricing: {
        serviceType,
        originalAmount: subtotal,
        manualDiscountApplied: manualDiscount,
        discountedSubtotal,
        benefitApplied: evaluation.benefitApplied,
        membershipDiscountApplied: evaluation.membershipDiscountApplied,
        rewardCreditApplied: evaluation.rewardPointCreditValue,
        taxPercent,
        taxAmount,
        grandTotal,
        customerVisibleLines: evaluation.customerVisibleLines,
      },
      totals: {
        subtotal,
        manualDiscount,
        benefitApplied: evaluation.benefitApplied,
        membershipDiscountApplied: evaluation.membershipDiscountApplied,
        rewardCreditApplied: evaluation.rewardPointCreditValue,
        taxAmount,
        grandTotal,
      },
      paymentStatus,
    };

    const existingInvoice = appointment.purchases?.find((purchase) =>
      this.isVisitPurchase(purchase.purchaseKind),
    );

    if (existingInvoice) {
      await this.prisma.$transaction(async (tx) => {
        await tx.purchaseItem.deleteMany({ where: { purchaseId: existingInvoice.id } });
        await tx.purchase.update({
          where: { id: existingInvoice.id },
          data: {
            customerId: appointment.customerId,
            providerId: appointment.providerId,
            appointmentId: appointment.id,
            invoiceNumber,
            totalAmount: subtotal,
            discountAmount: Number(
              (
                manualDiscount +
                evaluation.benefitApplied +
                evaluation.membershipDiscountApplied +
                evaluation.rewardPointCreditValue
              ).toFixed(2),
            ),
            payableAmount: grandTotal,
            purchaseDate: now,
            purchaseKind: 'VISIT',
            paymentStatus,
            paymentSummary: payment,
            billingSnapshot,
          },
        });
        for (const item of lineItems) {
          await tx.purchaseItem.create({
            data: {
              purchaseId: existingInvoice.id,
              quantity: 1,
              unitPrice: item.amount,
              totalPrice: item.amount,
              itemType: item.type,
              itemName: item.title,
              metadata: {
                description: item.description,
              },
            },
          });
        }
      });
      return;
    }

    await this.prisma.$transaction(async (tx) => {
      const purchase = await tx.purchase.create({
        data: {
          uuid: randomUUID(),
          customerId: appointment.customerId,
          providerId: appointment.providerId,
          appointmentId: appointment.id,
          invoiceNumber,
          totalAmount: subtotal,
          discountAmount: Number(
            (
              manualDiscount +
              evaluation.benefitApplied +
              evaluation.membershipDiscountApplied +
              evaluation.rewardPointCreditValue
            ).toFixed(2),
          ),
          payableAmount: grandTotal,
          purchaseDate: now,
          purchaseKind: 'VISIT',
          paymentStatus,
          paymentSummary: payment,
          billingSnapshot,
        },
      });

      for (const item of lineItems) {
        await tx.purchaseItem.create({
          data: {
            purchaseId: purchase.id,
            quantity: 1,
            unitPrice: item.amount,
            totalPrice: item.amount,
            itemType: item.type,
            itemName: item.title,
            metadata: {
              description: item.description,
            },
          },
        });
      }
    });
  }

  private async applyVisitPayment(appointmentId: bigint) {
    const appointment = await this.getWorkspaceAppointment(appointmentId);
    const invoice = appointment.purchases?.find((purchase) =>
      this.isVisitPurchase(purchase.purchaseKind),
    );
    if (!invoice) {
      throw new BadRequestException('Generate the visit invoice before recording payment.');
    }
    if (!appointment.customerId) {
      throw new BadRequestException('Patient is not attached to this visit.');
    }

    const consultation = appointment.consultations?.[0];
    const state = this.parseStructuredConsultationState(consultation?.notes);
    const grandTotal = Number(
      (
        (invoice.billingSnapshot as Record<string, any> | null)?.totals?.grandTotal ??
        invoice.payableAmount ??
        0
      ).toString(),
    );
    const previousPayment = this.parsePaymentSummary(invoice.paymentSummary);
    const nextPayment = this.computePaymentSummary(
      grandTotal,
      state.billingDraft,
      previousPayment,
    );
    const nextPaymentStatus = this.resolvePaymentStatus(nextPayment);

    const walletDelta = Number(
      Math.max(0, nextPayment.walletUsed - previousPayment.walletUsed).toFixed(2),
    );

    if (walletDelta > 0) {
      await this.walletService.ensureSufficientCashBalance(
        appointment.customerId,
        walletDelta,
      );
      const balances = await this.pricingService.getWalletLedgerBalances(
        appointment.customerId,
      );
      await this.walletService.createLedgerEntry({
        walletId: balances.walletId,
        transactionType: 'PURCHASE',
        subLedgerType: 'CASH',
        amount: walletDelta,
        remarks: `Visit payment applied (${invoice.invoiceNumber ?? 'Visit invoice'})`,
        referenceType: 'PURCHASE',
        referenceId: invoice.id,
        metadata: {
          appointmentId: appointment.id.toString(),
          invoiceNumber: invoice.invoiceNumber,
        },
      });
    }

    const billingSnapshot = {
      ...((invoice.billingSnapshot as Record<string, unknown> | null) ?? {}),
      paymentStatus: nextPaymentStatus,
      paymentUpdatedAt: nextPayment.recordedAt,
    };

    await this.prisma.purchase.update({
      where: { id: invoice.id },
      data: {
        paymentStatus: nextPaymentStatus,
        paymentSummary: nextPayment,
        billingSnapshot,
      },
    });
  }

  private async buildConsultationWorkspacePayload(appointment: {
    id: bigint;
    customerId: bigint | null;
    appointmentType: string | null;
    appointmentDate: Date | null;
    status: string | null;
    remarks: string | null;
    providerId?: bigint | null;
    provider?: {
      providerName: string | null;
      providerType?: string | null;
      business?: { name: string | null } | null;
    } | null;
    customer?: { firstName: string | null; lastName: string | null } | null;
    consultations?: Array<{
      id: bigint;
      diagnosis: string | null;
      notes: string | null;
      prescriptions?: Array<{ id: bigint }>;
    }>;
    purchases?: Array<{
      id: bigint;
      invoiceNumber: string | null;
      purchaseDate: Date | null;
      purchaseKind: string | null;
      paymentStatus: string | null;
      payableAmount: unknown;
      paymentSummary: unknown;
      billingSnapshot: unknown;
      purchaseItems?: Array<{
        id: bigint;
        itemType: string | null;
        itemName: string | null;
        totalPrice: unknown;
        metadata: unknown;
      }>;
    }>;
  }) {
    const consultation = appointment.consultations?.[0];
    const state = this.parseStructuredConsultationState(consultation?.notes);
    const statusCode = (appointment.status ?? 'PENDING').toUpperCase();
    const patientName = appointment.customer
      ? `${appointment.customer.firstName ?? ''} ${appointment.customer.lastName ?? ''}`.trim()
      : 'Patient';
    const visitTitle = `${this.getAppointmentTypeLabel(appointment.appointmentType)} for ${patientName}`;
    const statusLabel = this.getAppointmentStatusLabel(statusCode);
    const visitInvoice =
      appointment.purchases?.find((purchase) =>
        this.isVisitPurchase(purchase.purchaseKind),
      ) ?? null;
    const billingWorkspace = this.buildBillingWorkspace(appointment, state, visitInvoice);
    const timeline = await this.timelineService.getVisitTimeline(appointment.id);
    const statusSummary = this.buildVisitStatusSummary(
      statusCode,
      consultation,
      state,
      visitInvoice,
      billingWorkspace,
    );

    return {
      appointmentId: appointment.id.toString(),
      consultationId: consultation?.id?.toString() ?? null,
      statusCode,
      statusLabel,
      statusSummary,
      visit: {
        title: visitTitle,
        subtitle: `${appointment.provider?.providerName ?? 'Provider'} • ${appointment.provider?.business?.name ?? 'Branch not assigned'}`,
        appointmentTypeLabel: this.getAppointmentTypeLabel(appointment.appointmentType),
        appointmentDateLabel: this.formatDateTime(appointment.appointmentDate),
        reason: appointment.remarks?.trim() || 'Visit reason has not been recorded yet.',
        prescriptionCount: consultation?.prescriptions?.length ?? 0,
        visitStatusLabel: statusLabel,
        billingStatusLabel: statusSummary.billingStatus.label,
        paymentStatusLabel: statusSummary.paymentStatus.label,
      },
      actions: this.buildConsultationActions(statusCode, visitInvoice, billingWorkspace),
      formSections: [
        {
          code: 'chiefComplaint',
          title: 'Chief Complaint',
          placeholder: 'Record the main reason for this visit in plain language.',
          order: 1,
        },
        {
          code: 'symptoms',
          title: 'Present Illness',
          placeholder: 'Record the current illness story, symptoms, and recent changes.',
          order: 2,
        },
        {
          code: 'clinicalFindings',
          title: 'Examination',
          placeholder: 'Record examination notes, vitals, and observed findings.',
          order: 3,
        },
        {
          code: 'diagnosis',
          title: 'Diagnosis',
          placeholder: 'Record the diagnosis or working diagnosis.',
          order: 4,
        },
        {
          code: 'procedures',
          title: 'Procedures',
          placeholder: 'Record procedures completed or planned during this visit.',
          order: 5,
        },
        {
          code: 'labOrders',
          title: 'Lab Orders',
          placeholder: 'Record tests requested or report follow-ups needed.',
          order: 6,
        },
        {
          code: 'advice',
          title: 'Treatment Plan',
          placeholder: 'Record treatment decisions, medicines, and care guidance shared with the patient.',
          order: 7,
        },
        {
          code: 'followUp',
          title: 'Follow-up Instructions',
          placeholder: 'Record the next review, return visit, or follow-up timing.',
          order: 8,
        },
        {
          code: 'providerNotes',
          title: 'Clinical Notes',
          placeholder: 'Add visit notes that should remain with this encounter.',
          order: 9,
        },
      ],
      form: {
        chiefComplaint: state.form.chiefComplaint,
        symptoms: state.form.symptoms,
        clinicalFindings: state.form.clinicalFindings,
        diagnosis: consultation?.diagnosis ?? '',
        advice: state.form.advice,
        procedures: state.form.procedures,
        labOrders: state.form.labOrders,
        followUp: state.form.followUp,
        providerNotes: state.form.providerNotes,
      },
      billing: billingWorkspace,
      timeline,
    };
  }

  private buildVisitStatusSummary(
    statusCode: string,
    consultation:
      | {
          id: bigint;
          diagnosis: string | null;
          prescriptions?: Array<{ id: bigint }>;
        }
      | undefined,
    state: StructuredConsultationState,
    invoice: {
      paymentStatus: string | null;
      purchaseDate: Date | null;
    } | null,
    billingWorkspace: Record<string, any>,
  ) {
    const consultationStarted =
      statusCode === 'IN_PROGRESS' ||
      statusCode === 'COMPLETED' ||
      Boolean(consultation);
    const prescriptionCount = consultation?.prescriptions?.length ?? 0;
    const hasLabWork =
      state.form.labOrders.trim().length > 0 || state.billingDraft.labTestsAmount > 0;
    const followUpPlanned = state.form.followUp.trim().length > 0;
    const paymentSummary = (billingWorkspace['payment'] ?? {}) as Record<
      string,
      unknown
    >;

    return {
      consultationStatus: {
        code: consultationStarted ? 'IN_PROGRESS' : 'WAITING',
        label: consultationStarted ? 'Consultation In Progress' : 'Waiting to Start',
      },
      visitStatus: {
        code: statusCode,
        label: this.getAppointmentStatusLabel(statusCode),
      },
      billingStatus: {
        code: invoice ? 'INVOICE_READY' : 'PENDING',
        label: invoice ? 'Invoice Generated' : 'Billing In Progress',
      },
      paymentStatus: {
        code: invoice?.paymentStatus ?? 'PENDING',
        label: paymentSummary['statusLabel']?.toString() ?? 'Payment Pending',
      },
      prescriptionStatus: {
        code: prescriptionCount > 0 ? 'AVAILABLE' : 'PENDING',
        label: prescriptionCount > 0 ? 'Prescription Ready' : 'Prescription Pending',
      },
      labStatus: {
        code: hasLabWork ? 'ORDERED' : 'NOT_REQUIRED',
        label: hasLabWork ? 'Lab Work Requested' : 'No Lab Work Added',
      },
      followUpStatus: {
        code: followUpPlanned ? 'PLANNED' : 'NOT_PLANNED',
        label: followUpPlanned ? 'Follow-up Planned' : 'Follow-up Not Planned',
      },
    };
  }

  private buildBillingWorkspace(
    appointment: {
      id: bigint;
      customerId: bigint | null;
      appointmentType: string | null;
      provider?: { providerType?: string | null } | null;
    },
    state: StructuredConsultationState,
    invoice:
      | {
          id: bigint;
          invoiceNumber: string | null;
          purchaseDate: Date | null;
          paymentStatus: string | null;
          payableAmount: unknown;
          paymentSummary: unknown;
          billingSnapshot: unknown;
          purchaseItems?: Array<{
            itemType: string | null;
            itemName: string | null;
            totalPrice: unknown;
            metadata: unknown;
          }>;
        }
      | null,
  ) {
    const lineItems = this.computeVisitChargeItems(state);
    const subtotal = Number(
      lineItems.reduce((sum, item) => sum + item.amount, 0).toFixed(2),
    );
    const manualDiscount = Math.min(
      subtotal,
      Math.max(0, Number(state.billingDraft.manualDiscountAmount || 0)),
    );
    const serviceType = this.resolveServiceType(appointment);
    const summary = invoice
      ? ((invoice.billingSnapshot as Record<string, any> | null)?.totals ?? {})
      : null;
    const pricing = invoice
      ? ((invoice.billingSnapshot as Record<string, any> | null)?.pricing ?? {})
      : null;
    const taxPercent = pricing?.taxPercent ?? Number(state.billingDraft.taxPercent || 0);
    const taxAmount = Number(pricing?.taxAmount ?? 0);
    const grandTotal = Number(
      summary?.grandTotal ??
        invoice?.payableAmount ??
        Math.max(0, subtotal - manualDiscount),
    );
    const payment = this.parsePaymentSummary(invoice?.paymentSummary);

    return {
      draft: {
        consultationFee: state.billingDraft.consultationFee,
        proceduresAmount: state.billingDraft.proceduresAmount,
        medicinesAmount: state.billingDraft.medicinesAmount,
        labTestsAmount: state.billingDraft.labTestsAmount,
        otherServicesAmount: state.billingDraft.otherServicesAmount,
        manualDiscountAmount: state.billingDraft.manualDiscountAmount,
        taxPercent: state.billingDraft.taxPercent,
        walletUseAmount: state.billingDraft.walletUseAmount,
        cashAmount: state.billingDraft.cashAmount,
        upiAmount: state.billingDraft.upiAmount,
        cardAmount: state.billingDraft.cardAmount,
        pendingAmount: state.billingDraft.pendingAmount,
        refundAmount: state.billingDraft.refundAmount,
        otherServicesLabel: state.billingDraft.otherServicesLabel,
      },
      serviceTypeLabel: this.humanizeCode(serviceType),
      lineItems: lineItems.map((item) => ({
        type: item.type,
        title: item.title,
        description: item.description,
        amount: item.amount,
        amountLabel: this.formatMoney(item.amount),
      })),
      invoice: invoice == null
          ? null
          : {
              purchaseId: invoice.id.toString(),
              invoiceNumber: invoice.invoiceNumber,
              generatedAtLabel: this.formatDateTime(invoice.purchaseDate),
            },
      totals: {
        subtotal,
        subtotalLabel: this.formatMoney(subtotal),
        manualDiscount,
        manualDiscountLabel: this.formatMoney(manualDiscount),
        membershipDiscountApplied: Number(pricing?.membershipDiscountApplied ?? 0),
        membershipDiscountLabel: this.formatMoney(
          Number(pricing?.membershipDiscountApplied ?? 0),
        ),
        benefitApplied: Number(pricing?.benefitApplied ?? 0),
        benefitAppliedLabel: this.formatMoney(Number(pricing?.benefitApplied ?? 0)),
        rewardCreditApplied: Number(pricing?.rewardCreditApplied ?? 0),
        rewardCreditAppliedLabel: this.formatMoney(
          Number(pricing?.rewardCreditApplied ?? 0),
        ),
        taxPercent,
        taxPercentLabel: `${Number(taxPercent).toFixed(0)}%`,
        taxAmount,
        taxAmountLabel: this.formatMoney(taxAmount),
        grandTotal,
        grandTotalLabel: this.formatMoney(grandTotal),
        balanceDue: payment.balanceDue,
        balanceDueLabel: this.formatMoney(payment.balanceDue),
      },
      payment: {
        walletUsed: payment.walletUsed,
        walletUsedLabel: this.formatMoney(payment.walletUsed),
        cash: payment.cash,
        cashLabel: this.formatMoney(payment.cash),
        upi: payment.upi,
        upiLabel: this.formatMoney(payment.upi),
        card: payment.card,
        cardLabel: this.formatMoney(payment.card),
        pending: payment.pending,
        pendingLabel: this.formatMoney(payment.pending),
        refund: payment.refund,
        refundLabel: this.formatMoney(payment.refund),
        paidAmount: payment.paidAmount,
        paidAmountLabel: this.formatMoney(payment.paidAmount),
        balanceDue: payment.balanceDue,
        balanceDueLabel: this.formatMoney(payment.balanceDue),
        statusCode: invoice?.paymentStatus ?? 'PENDING',
        statusLabel: this.getPaymentStatusLabel(invoice?.paymentStatus),
        recordedAtLabel: payment.recordedAt == null
            ? 'Payment not recorded'
            : this.formatDateTime(new Date(payment.recordedAt)),
      },
      statusLabel: invoice == null ? 'Billing In Progress' : 'Invoice Generated',
      paymentStatusLabel: this.getPaymentStatusLabel(invoice?.paymentStatus),
    };
  }

  private buildConsultationActions(
    statusCode: string,
    invoice: { paymentStatus: string | null } | null,
    billingWorkspace: Record<string, any>,
  ) {
    const actions: Array<Record<string, string>> = [];

    if (statusCode !== 'IN_PROGRESS' && statusCode !== 'COMPLETED') {
      actions.push({
        code: 'START_CONSULTATION',
        title: 'Start Consultation',
        emphasis: 'primary',
      });
    }

    actions.push({
      code: 'SAVE_PROGRESS',
      title: 'Save Progress',
      emphasis: statusCode === 'IN_PROGRESS' ? 'secondary' : 'primary',
    });

    actions.push({
      code: 'SAVE_BILLING',
      title: 'Save Billing',
      emphasis: 'secondary',
    });

    if (
      Array.isArray(billingWorkspace['lineItems']) &&
      (billingWorkspace['lineItems'] as Array<unknown>).length > 0
    ) {
      actions.push({
        code: 'GENERATE_INVOICE',
        title: invoice == null ? 'Generate Invoice' : 'Refresh Invoice',
        emphasis: 'secondary',
      });
    }

    if (invoice != null &&
        (invoice.paymentStatus ?? '').toUpperCase() !== 'PAID') {
      actions.push({
        code: 'RECORD_PAYMENT',
        title: 'Record Payment',
        emphasis: 'primary',
      });
    }

    actions.push({
      code: 'COMPLETE_VISIT',
      title: statusCode === 'COMPLETED' ? 'Update Visit' : 'Complete Visit',
      emphasis: invoice != null ? 'primary' : 'secondary',
    });

    return actions;
  }

  private async recordAuditAction(input: {
    action: string;
    entityType: string;
    entityId: bigint;
    userId?: bigint | null;
    details?: Record<string, unknown>;
  }) {
    await this.timelineService.recordAuditLog({
      action: input.action,
      entityType: input.entityType,
      entityId: input.entityId,
      userId: input.userId,
      newData: input.details ?? {},
    });
  }

  private publishVisitEvent(
    appointment: { id: bigint; customerId: bigint | null; appointmentType: string | null },
    type: string,
    title: string,
    description: string,
  ) {
    this.platformRealtimeService.publish({
      id: `${type.toLowerCase()}:${appointment.id.toString()}`,
      type,
      category: 'workflow',
      title,
      description,
      workspace: 'provider',
      appointmentId: appointment.id.toString(),
      customerId: appointment.customerId?.toString() ?? undefined,
      metadata: {
        appointmentType: appointment.appointmentType ?? 'VISIT',
      },
    });
  }

  private normalizeConsultationInput(
    data:
      | {
          chiefComplaint?: string;
          symptoms?: string;
          clinicalFindings?: string;
          diagnosis?: string;
          advice?: string;
          procedures?: string;
          labOrders?: string;
          followUp?: string;
          providerNotes?: string;
          notes?: string;
        }
      | undefined,
  ) {
    if (!data) {
      return undefined;
    }
    return {
      chiefComplaint: data.chiefComplaint,
      symptoms: data.symptoms,
      clinicalFindings: data.clinicalFindings,
      diagnosis: data.diagnosis,
      advice: data.advice,
      procedures: data.procedures,
      labOrders: data.labOrders,
      followUp: data.followUp,
      providerNotes: data.providerNotes ?? data.notes,
    };
  }

  private parseStructuredConsultationState(notes?: string | null): StructuredConsultationState {
    const fallback: StructuredConsultationState = {
      form: {
        chiefComplaint: '',
        symptoms: '',
        clinicalFindings: '',
        advice: '',
        procedures: '',
        labOrders: '',
        followUp: '',
        providerNotes: '',
      },
      billingDraft: this.defaultBillingDraft(),
    };

    const raw = notes?.trim() ?? '';
    if (!raw) {
      return fallback;
    }

    try {
      const parsed = JSON.parse(raw) as Record<string, unknown>;
      return {
        form: this.mergeConsultationForm(fallback.form, {
          chiefComplaint: parsed['chiefComplaint']?.toString(),
          symptoms: parsed['symptoms']?.toString(),
          clinicalFindings: parsed['clinicalFindings']?.toString(),
          advice: parsed['advice']?.toString(),
          procedures: parsed['procedures']?.toString(),
          labOrders: parsed['labOrders']?.toString(),
          followUp: parsed['followUp']?.toString(),
          providerNotes: (parsed['providerNotes'] ?? parsed['notes'])?.toString(),
        }),
        billingDraft: this.mergeBillingDraft(
          fallback.billingDraft,
          parsed['billingDraft'] as Record<string, unknown> | undefined,
        ),
      };
    } catch {
      return {
        ...fallback,
        form: {
          ...fallback.form,
          providerNotes: raw,
        },
      };
    }
  }

  private serializeStructuredConsultationState(data: StructuredConsultationState) {
    return JSON.stringify({
      chiefComplaint: this.normalizeText(data.form.chiefComplaint),
      symptoms: this.normalizeText(data.form.symptoms),
      clinicalFindings: this.normalizeText(data.form.clinicalFindings),
      advice: this.normalizeText(data.form.advice),
      procedures: this.normalizeText(data.form.procedures),
      labOrders: this.normalizeText(data.form.labOrders),
      followUp: this.normalizeText(data.form.followUp),
      providerNotes: this.normalizeText(data.form.providerNotes),
      billingDraft: {
        consultationFee: data.billingDraft.consultationFee,
        proceduresAmount: data.billingDraft.proceduresAmount,
        medicinesAmount: data.billingDraft.medicinesAmount,
        labTestsAmount: data.billingDraft.labTestsAmount,
        otherServicesAmount: data.billingDraft.otherServicesAmount,
        manualDiscountAmount: data.billingDraft.manualDiscountAmount,
        taxPercent: data.billingDraft.taxPercent,
        walletUseAmount: data.billingDraft.walletUseAmount,
        cashAmount: data.billingDraft.cashAmount,
        upiAmount: data.billingDraft.upiAmount,
        cardAmount: data.billingDraft.cardAmount,
        pendingAmount: data.billingDraft.pendingAmount,
        refundAmount: data.billingDraft.refundAmount,
        otherServicesLabel: data.billingDraft.otherServicesLabel,
      },
    });
  }

  private mergeConsultationForm(
    existing: ConsultationFormState,
    data?: Partial<ConsultationFormState> & { diagnosis?: string },
  ): ConsultationFormState {
    return {
      chiefComplaint: this.normalizeText(data?.chiefComplaint, existing.chiefComplaint),
      symptoms: this.normalizeText(data?.symptoms, existing.symptoms),
      clinicalFindings: this.normalizeText(
        data?.clinicalFindings,
        existing.clinicalFindings,
      ),
      advice: this.normalizeText(data?.advice, existing.advice),
      procedures: this.normalizeText(data?.procedures, existing.procedures),
      labOrders: this.normalizeText(data?.labOrders, existing.labOrders),
      followUp: this.normalizeText(data?.followUp, existing.followUp),
      providerNotes: this.normalizeText(data?.providerNotes, existing.providerNotes),
    };
  }

  private mergeBillingDraft(
    existing: VisitBillingDraftState,
    draft?: Record<string, unknown> | Partial<VisitBillingDraftState>,
  ): VisitBillingDraftState {
    const source = (draft ?? {}) as Record<string, unknown>;
    return {
      consultationFee: this.normalizeNumber(
        source['consultationFee'],
        existing.consultationFee,
      ),
      proceduresAmount: this.normalizeNumber(
        source['proceduresAmount'],
        existing.proceduresAmount,
      ),
      medicinesAmount: this.normalizeNumber(
        source['medicinesAmount'],
        existing.medicinesAmount,
      ),
      labTestsAmount: this.normalizeNumber(
        source['labTestsAmount'],
        existing.labTestsAmount,
      ),
      otherServicesAmount: this.normalizeNumber(
        source['otherServicesAmount'],
        existing.otherServicesAmount,
      ),
      manualDiscountAmount: this.normalizeNumber(
        source['manualDiscountAmount'],
        existing.manualDiscountAmount,
      ),
      taxPercent: this.normalizeNumber(source['taxPercent'], existing.taxPercent),
      walletUseAmount: this.normalizeNumber(
        source['walletUseAmount'],
        existing.walletUseAmount,
      ),
      cashAmount: this.normalizeNumber(source['cashAmount'], existing.cashAmount),
      upiAmount: this.normalizeNumber(source['upiAmount'], existing.upiAmount),
      cardAmount: this.normalizeNumber(source['cardAmount'], existing.cardAmount),
      pendingAmount: this.normalizeNumber(source['pendingAmount'], existing.pendingAmount),
      refundAmount: this.normalizeNumber(source['refundAmount'], existing.refundAmount),
      otherServicesLabel: this.normalizeText(
        source['otherServicesLabel'],
        existing.otherServicesLabel,
      ),
    };
  }

  private defaultBillingDraft(): VisitBillingDraftState {
    return {
      consultationFee: 0,
      proceduresAmount: 0,
      medicinesAmount: 0,
      labTestsAmount: 0,
      otherServicesAmount: 0,
      manualDiscountAmount: 0,
      taxPercent: 0,
      walletUseAmount: 0,
      cashAmount: 0,
      upiAmount: 0,
      cardAmount: 0,
      pendingAmount: 0,
      refundAmount: 0,
      otherServicesLabel: 'Other Services',
    };
  }

  private computeVisitChargeItems(state: StructuredConsultationState) {
    const items: Array<{
      type: string;
      title: string;
      description: string;
      amount: number;
    }> = [];

    if (state.billingDraft.consultationFee > 0) {
      items.push({
        type: 'CONSULTATION_FEE',
        title: 'Consultation Fee',
        description: state.form.chiefComplaint || 'Consultation charge for this visit.',
        amount: Number(state.billingDraft.consultationFee.toFixed(2)),
      });
    }

    if (state.billingDraft.proceduresAmount > 0) {
      items.push({
        type: 'PROCEDURE',
        title: 'Procedures',
        description: state.form.procedures || 'Procedure charges added to this visit.',
        amount: Number(state.billingDraft.proceduresAmount.toFixed(2)),
      });
    }

    if (state.billingDraft.medicinesAmount > 0) {
      items.push({
        type: 'MEDICINE',
        title: 'Medicines',
        description:
          state.form.providerNotes || 'Medicine charges recorded during this visit.',
        amount: Number(state.billingDraft.medicinesAmount.toFixed(2)),
      });
    }

    if (state.billingDraft.labTestsAmount > 0) {
      items.push({
        type: 'LAB_TEST',
        title: 'Lab Tests',
        description: state.form.labOrders || 'Lab work charges added to this visit.',
        amount: Number(state.billingDraft.labTestsAmount.toFixed(2)),
      });
    }

    if (state.billingDraft.otherServicesAmount > 0) {
      items.push({
        type: 'OTHER_SERVICE',
        title: state.billingDraft.otherServicesLabel || 'Other Services',
        description: 'Additional service charges recorded during this visit.',
        amount: Number(state.billingDraft.otherServicesAmount.toFixed(2)),
      });
    }

    return items;
  }

  private computePaymentSummary(
    grandTotal: number,
    draft: VisitBillingDraftState,
    previous: PaymentSummaryState | undefined,
  ): PaymentSummaryState {
    const walletUsed = Number(Math.max(0, draft.walletUseAmount || 0).toFixed(2));
    const cash = Number(Math.max(0, draft.cashAmount || 0).toFixed(2));
    const upi = Number(Math.max(0, draft.upiAmount || 0).toFixed(2));
    const card = Number(Math.max(0, draft.cardAmount || 0).toFixed(2));
    const refund = Number(Math.max(0, draft.refundAmount || 0).toFixed(2));
    const paidAmount = Number((walletUsed + cash + upi + card).toFixed(2));
    const balanceDue = Number(
      Math.max(0, grandTotal - paidAmount + refund).toFixed(2),
    );
    const pending = Number(
      Math.max(balanceDue, draft.pendingAmount || 0).toFixed(2),
    );

    return {
      walletUsed,
      cash,
      upi,
      card,
      pending,
      refund,
      paidAmount,
      balanceDue,
      recordedAt:
        paidAmount > 0 || previous?.recordedAt != null ? new Date().toISOString() : null,
    };
  }

  private parsePaymentSummary(value: unknown): PaymentSummaryState {
    const summary = (value as Record<string, unknown> | null) ?? {};
    return {
      walletUsed: this.normalizeNumber(summary['walletUsed']),
      cash: this.normalizeNumber(summary['cash']),
      upi: this.normalizeNumber(summary['upi']),
      card: this.normalizeNumber(summary['card']),
      pending: this.normalizeNumber(summary['pending']),
      refund: this.normalizeNumber(summary['refund']),
      paidAmount: this.normalizeNumber(summary['paidAmount']),
      balanceDue: this.normalizeNumber(summary['balanceDue']),
      recordedAt: summary['recordedAt']?.toString() ?? null,
    };
  }

  private resolvePaymentStatus(payment: PaymentSummaryState) {
    if (payment.refund > 0 && payment.paidAmount <= 0) {
      return 'REFUND';
    }
    if (payment.balanceDue <= 0) {
      return 'PAID';
    }
    if (payment.paidAmount > 0) {
      return 'PARTIAL';
    }
    return 'PENDING';
  }

  private resolveServiceType(appointment: {
    appointmentType: string | null;
    provider?: { providerType?: string | null } | null;
  }): ShieldServiceType {
    const candidates = [
      appointment.provider?.providerType,
      appointment.appointmentType,
    ].map((value) => (value ?? '').toString().trim().toUpperCase());

    for (const candidate of candidates) {
      if (candidate.includes('PHARMACY')) {
        return 'PHARMACY';
      }
      if (candidate.includes('LAB')) {
        return 'LAB';
      }
      if (candidate.includes('DENTAL')) {
        return 'DENTAL';
      }
      if (candidate.includes('COSMETIC')) {
        return 'COSMETIC';
      }
      if (candidate.includes('DIET')) {
        return 'DIETITIAN';
      }
      if (candidate.includes('HOME')) {
        return 'HOMECARE';
      }
      if (candidate.includes('DOCTOR') || candidate.includes('CONSULT')) {
        return 'DOCTOR';
      }
    }

    return SERVICE_TYPES.includes('DOCTOR') ? 'DOCTOR' : SERVICE_TYPES[0];
  }

  private buildVisitInvoiceNumber(appointmentId: bigint) {
    return `VIS-${appointmentId.toString().padStart(6, '0')}`;
  }

  private isVisitPurchase(purchaseKind?: string | null) {
    return (purchaseKind ?? '').trim().toUpperCase() === 'VISIT';
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

  private normalizeText(value?: unknown, fallback = '') {
    const text = value?.toString().trim();
    return text && text.length > 0 ? text : fallback;
  }

  private normalizeNumber(value?: unknown, fallback = 0) {
    const number = Number(value);
    return Number.isFinite(number) ? Number(number.toFixed(2)) : fallback;
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
        return 'Consultation In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return this.humanizeCode(status || 'Appointment');
    }
  }

  private getPaymentStatusLabel(status?: string | null) {
    switch ((status ?? '').trim().toUpperCase()) {
      case 'PAID':
        return 'Payment Completed';
      case 'PARTIAL':
      case 'PARTIALLY_PAID':
        return 'Payment Pending';
      case 'REFUND':
      case 'REFUNDED':
        return 'Refund Recorded';
      case 'PENDING':
      default:
        return 'Payment Pending';
    }
  }

  private humanizeCode(value: string | null | undefined) {
    const normalized = (value || '').toString().trim();
    if (!normalized) {
      return '';
    }

    return normalized
      .replace(/_/g, ' ')
      .toLowerCase()
      .replace(/\b\w/g, (character) => character.toUpperCase());
  }

  private formatMoney(value: number) {
    return `Rs ${value.toFixed(2)}`;
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
