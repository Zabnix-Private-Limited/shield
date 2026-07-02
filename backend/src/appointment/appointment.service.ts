import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AgentScopeService } from '../auth/agent-scope.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { PricingService } from '../pricing/pricing.service';
import { SERVICE_TYPES, type ShieldServiceType } from '../pricing/pricing.types';
import { NotificationService } from '../notification/notification.service';
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
  history: Array<{
    kind: string;
    status: string;
    recordedAt: string;
    walletUsed: number;
    cash: number;
    upi: number;
    card: number;
    refund: number;
    paidAmount: number;
    balanceDue: number;
  }>;
  invoiceVoidedAt?: string | null;
  invoiceVoidReason?: string | null;
};

type PrescriptionMedicineState = {
  productId: string;
  productCode: string;
  productName: string;
  brand: string;
  unit: string;
  strength: string;
  dosage: string;
  route: string;
  frequency: string;
  duration: string;
  morning: boolean;
  afternoon: boolean;
  night: boolean;
  beforeFood: boolean;
  afterFood: boolean;
  specialInstructions: string;
  clinicalRemarks: string;
};

type PrescriptionDraftState = {
  status: 'EMPTY' | 'DRAFT' | 'FINALIZED';
  clinicalRemarks: string;
  items: PrescriptionMedicineState[];
  finalizedAt: string | null;
  sentToPharmacyAt: string | null;
};

type StructuredConsultationState = {
  form: ConsultationFormState;
  billingDraft: VisitBillingDraftState;
  prescriptionDraft: PrescriptionDraftState;
};

@Injectable()
export class AppointmentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pricingService: PricingService,
    private readonly agentScopeService: AgentScopeService,
    private readonly providerScopeService: ProviderScopeService,
    private readonly timelineService: TimelineService,
    private readonly walletService: WalletService,
    private readonly notificationService: NotificationService,
    private readonly platformRealtimeService: PlatformRealtimeService,
  ) {}

  async list(customerId?: bigint, principal?: ShieldPrincipal) {
    const whereClause: Record<string, unknown> = {};
    if (customerId) {
      whereClause.customerId = customerId;
    } else if (this.agentScopeService.isAgentPrincipal(principal)) {
      const accessibleCustomerIds =
        await this.agentScopeService.listAccessibleCustomerIds(principal);
      whereClause.customerId =
        accessibleCustomerIds.length > 0 ? { in: accessibleCustomerIds } : { in: [] };
    }
    return this.prisma.appointment.findMany({
      where: this.providerScopeService.scopeAppointmentWhere(
        whereClause,
        principal,
      ),
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

  async findOne(id: bigint, principal?: ShieldPrincipal) {
    await this.agentScopeService.assertAgentCanAccessAppointment(id, principal);
    await this.providerScopeService.assertProviderCanAccessAppointment(
      id,
      principal,
    );
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

  async cancel(id: bigint, principal?: ShieldPrincipal) {
    const appt = await this.findOne(id, principal);
    const updated = await this.prisma.appointment.update({
      where: { id: appt.id },
      data: { status: 'CANCELLED' },
    });
    this.publishVisitEvent(updated, 'APPOINTMENT_CANCELLED', 'Appointment cancelled', 'The appointment was cancelled.');
    await this.sendPatientNotification(updated, {
      title: 'Appointment cancelled',
      message: 'This appointment has been cancelled. Contact SHIELD if you need to reschedule.',
      eventType: 'APPOINTMENT_CANCELLED',
    });
    return updated;
  }

  async confirm(id: bigint, principal?: ShieldPrincipal) {
    const appt = await this.findOne(id, principal);
    const updated = await this.prisma.appointment.update({
      where: { id: appt.id },
      data: { status: 'CONFIRMED' },
    });
    this.publishVisitEvent(updated, 'APPOINTMENT_CONFIRMED', 'Appointment confirmed', 'The appointment was confirmed.');
    await this.sendPatientNotification(updated, {
      title: 'Appointment confirmed',
      message: 'Your appointment has been confirmed and is ready for the visit workflow.',
      eventType: 'APPOINTMENT_CONFIRMED',
    });
    return updated;
  }

  async getConsultationWorkspace(id: bigint, principal?: ShieldPrincipal) {
    const appointment = await this.getWorkspaceAppointment(id, principal);
    return this.buildConsultationWorkspacePayload(appointment);
  }

  async startConsultation(
    id: bigint,
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);

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
    await this.sendPatientNotification(appointment, {
      title: 'Visit started',
      message: 'Your visit has started and the provider has opened the consultation workspace.',
      eventType: 'VISIT_STARTED',
    });

    return this.getConsultationWorkspace(id, principal);
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
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);

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

    return this.getConsultationWorkspace(id, principal);
  }

  async saveVisitBillingDraft(
    id: bigint,
    data: Partial<VisitBillingDraftState>,
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);
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

    return this.getConsultationWorkspace(id, principal);
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
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);
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
    await this.sendPatientNotification(appointment, {
      title: 'Invoice generated',
      message: 'A visit invoice is ready in your SHIELD records.',
      eventType: 'INVOICE_GENERATED',
    });
    return this.getConsultationWorkspace(id, principal);
  }

  async recordVisitPayment(
    id: bigint,
    data: Partial<VisitBillingDraftState>,
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);
    await this.ensureConsultationRecord(appointment, undefined, data);
    await this.upsertVisitInvoice(appointment.id);
    const paymentResult = await this.applyVisitPayment(appointment.id);
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
    await this.sendPatientNotification(appointment, {
      title:
        paymentResult.refundAmount > 0 ? 'Refund processed' : 'Payment received',
      message:
        paymentResult.refundAmount > 0
          ? 'A refund has been recorded for your visit invoice.'
          : 'A payment has been recorded for your visit invoice.',
      eventType:
        paymentResult.refundAmount > 0 ? 'REFUND_PROCESSED' : 'PAYMENT_RECORDED',
    });
    return this.getConsultationWorkspace(id, principal);
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
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);

    await this.ensureConsultationRecord(
      appointment,
      this.normalizeConsultationInput(data),
      data.billingDraft,
    );

    const refreshedAppointment = await this.getWorkspaceAppointment(id, principal);
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
    await this.sendPatientNotification(refreshedAppointment, {
      title: 'Visit completed',
      message: 'This visit has been completed and added to your care history.',
      eventType: 'VISIT_COMPLETED',
    });

    return this.getConsultationWorkspace(id, principal);
  }

  private async getWorkspaceAppointment(
    id: bigint,
    principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessAppointment(
      id,
      principal,
    );
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
      prescriptionDraft: this.mergePrescriptionDraft(
        existingState.prescriptionDraft,
      ),
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
    const existingInvoice = appointment.purchases?.find((purchase) =>
      this.isVisitPurchase(purchase.purchaseKind),
    );
    const payment = existingInvoice
      ? this.parsePaymentSummary(existingInvoice.paymentSummary)
      : this.parsePaymentSummary(undefined);
    const paymentStatus = existingInvoice
      ? (existingInvoice.paymentStatus ?? this.resolvePaymentStatus(payment))
      : this.resolvePaymentStatus(payment);
    const now = new Date();

    const invoiceNumber =
      existingInvoice?.invoiceNumber ?? this.buildVisitInvoiceNumber(appointment.id);

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
    if (
      previousPayment.walletUsed === nextPayment.walletUsed &&
      previousPayment.cash === nextPayment.cash &&
      previousPayment.upi === nextPayment.upi &&
      previousPayment.card === nextPayment.card &&
      previousPayment.refund === nextPayment.refund &&
      previousPayment.balanceDue === nextPayment.balanceDue
    ) {
      throw new BadRequestException(
        'Enter a payment or refund amount before saving.',
      );
    }

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

    return {
      paymentStatus: nextPaymentStatus,
      paidAmount: nextPayment.paidAmount,
      refundAmount: nextPayment.refund,
      balanceDue: nextPayment.balanceDue,
    };
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
    const isReadOnly = this.isCompletedAppointmentStatus(statusCode);
    const visitInvoice =
      appointment.purchases?.find((purchase) =>
        this.isVisitPurchase(purchase.purchaseKind),
      ) ?? null;
    const billingWorkspace = this.buildBillingWorkspace(appointment, state, visitInvoice);
    const timeline = await this.timelineService.getVisitTimeline(appointment.id);
    const copyTargetAppointment = isReadOnly && appointment.customerId
      ? await this.findOpenVisitForCustomer(appointment.customerId, appointment.id)
      : null;
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
      isReadOnly,
      readOnlyMessage: isReadOnly
        ? 'This visit is complete. You can review records, print documents, or copy the prescription into an active visit.'
        : null,
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
      prescription: {
        statusCode: state.prescriptionDraft.status,
        statusLabel:
          state.prescriptionDraft.status === 'FINALIZED'
            ? 'Prescription Finalized'
            : state.prescriptionDraft.status === 'DRAFT'
              ? 'Prescription Draft'
              : 'No Prescription Yet',
        totalItems: state.prescriptionDraft.items.length,
        totalItemsLabel: `${state.prescriptionDraft.items.length} medicine${state.prescriptionDraft.items.length == 1 ? '' : 's'}`,
        clinicalRemarks: state.prescriptionDraft.clinicalRemarks,
        finalizedAtLabel: state.prescriptionDraft.finalizedAt
          ? this.formatDateTime(new Date(state.prescriptionDraft.finalizedAt))
          : 'Not finalized',
        sentToPharmacy:
          state.prescriptionDraft.sentToPharmacyAt != null,
        sentToPharmacyAtLabel: state.prescriptionDraft.sentToPharmacyAt
          ? this.formatDateTime(new Date(state.prescriptionDraft.sentToPharmacyAt))
          : 'Not sent',
        readOnly: isReadOnly,
        canCopyToCurrentVisit: isReadOnly && state.prescriptionDraft.items.length > 0,
        copyTargetAppointmentId: copyTargetAppointment?.id?.toString() ?? null,
        items: state.prescriptionDraft.items.map((item, index) => ({
          index,
          productId: item.productId,
          productCode: item.productCode,
          title: item.productName,
          subtitle: [item.brand, item.strength, item.frequency]
            .filter((value) => value.trim().length > 0)
            .join(' • '),
          dosage: item.dosage,
          route: item.route,
          duration: item.duration,
          schedule: {
            morning: item.morning,
            afternoon: item.afternoon,
            night: item.night,
          },
          mealPlan: item.beforeFood
            ? 'Before food'
            : item.afterFood
              ? 'After food'
              : 'Flexible',
          specialInstructions: item.specialInstructions,
          clinicalRemarks: item.clinicalRemarks,
        })),
      },
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
        invoiceVoidedAtLabel: payment.invoiceVoidedAt == null
            ? null
            : this.formatDateTime(new Date(payment.invoiceVoidedAt)),
        invoiceVoidReason: payment.invoiceVoidReason ?? null,
        history: payment.history.map((entry) => ({
          kind: entry.kind,
          status: entry.status,
          recordedAt: entry.recordedAt,
          recordedAtLabel: this.formatDateTime(new Date(entry.recordedAt)),
          paidAmount: entry.paidAmount,
          paidAmountLabel: this.formatMoney(entry.paidAmount),
          balanceDue: entry.balanceDue,
          balanceDueLabel: this.formatMoney(entry.balanceDue),
          walletUsedLabel: this.formatMoney(entry.walletUsed),
          cashLabel: this.formatMoney(entry.cash),
          upiLabel: this.formatMoney(entry.upi),
          cardLabel: this.formatMoney(entry.card),
          refundLabel: this.formatMoney(entry.refund),
        })),
      },
      statusLabel:
        payment.invoiceVoidedAt != null
          ? 'Invoice Voided'
          : invoice == null
            ? 'Billing In Progress'
            : 'Invoice Generated',
      paymentStatusLabel:
        payment.invoiceVoidedAt != null
          ? 'Invoice Voided'
          : this.getPaymentStatusLabel(invoice?.paymentStatus),
    };
  }

  private buildConsultationActions(
    statusCode: string,
    invoice: { paymentStatus: string | null } | null,
    billingWorkspace: Record<string, any>,
  ) {
    const actions: Array<Record<string, string>> = [];

    if (statusCode === 'COMPLETED') {
      return actions;
    }

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

    if (invoice != null && (invoice.paymentStatus ?? '').toUpperCase() !== 'VOID') {
      actions.push({
        code: 'VOID_INVOICE',
        title: 'Void Invoice',
        emphasis: 'secondary',
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

  private async sendPatientNotification(
    appointment: { id: bigint; customerId: bigint | null; appointmentType?: string | null },
    input: { title: string; message: string; eventType: string },
  ) {
    if (!appointment.customerId) {
      return;
    }
    await this.notificationService.send({
      customerId: appointment.customerId,
      title: input.title,
      message: input.message,
      data: {
        appointmentId: appointment.id.toString(),
        appointmentType: appointment.appointmentType ?? 'VISIT',
        eventType: input.eventType,
      },
    });
  }

  private async findOpenVisitForCustomer(customerId: bigint, excludeAppointmentId: bigint) {
    return this.prisma.appointment.findFirst({
      where: {
        customerId,
        id: { not: excludeAppointmentId },
        status: {
          in: ['PENDING', 'CONFIRMED', 'IN_PROGRESS'],
        },
      },
      orderBy: [{ appointmentDate: 'asc' }, { id: 'asc' }],
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
      prescriptionDraft: this.defaultPrescriptionDraft(),
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
        prescriptionDraft: this.mergePrescriptionDraft(
          fallback.prescriptionDraft,
          parsed['prescriptionDraft'] as Record<string, unknown> | undefined,
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

  async savePrescriptionDraft(
    id: bigint,
    data: {
      clinicalRemarks?: string;
      items?: Array<Record<string, unknown>>;
    },
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    await this.upsertVisitPrescription(id, data, {
      finalized: false,
      sendToPharmacy: false,
    });
    await this.recordAuditAction({
      action: 'PRESCRIPTION_DRAFT_SAVED',
      entityType: 'APPOINTMENT',
      entityId: id,
      userId: auditActor?.userId,
      details: { appointmentId: id.toString() },
    });
    const appointment = await this.getWorkspaceAppointment(id, principal);
    this.publishVisitEvent(
      appointment,
      'PRESCRIPTION_DRAFT_SAVED',
      'Prescription draft saved',
      'Prescription changes were saved for this visit.',
    );
    return this.buildConsultationWorkspacePayload(
      await this.getWorkspaceAppointment(id, principal),
    );
  }

  async finalizePrescription(
    id: bigint,
    data: {
      clinicalRemarks?: string;
      items?: Array<Record<string, unknown>>;
      sendToPharmacy?: boolean;
    },
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    await this.upsertVisitPrescription(id, data, {
      finalized: true,
      sendToPharmacy: data.sendToPharmacy === true,
    });
    await this.recordAuditAction({
      action: data.sendToPharmacy === true
        ? 'PRESCRIPTION_SENT_TO_PHARMACY'
        : 'PRESCRIPTION_FINALIZED',
      entityType: 'APPOINTMENT',
      entityId: id,
      userId: auditActor?.userId,
      details: {
        appointmentId: id.toString(),
        sendToPharmacy: data.sendToPharmacy === true,
      },
    });
    const appointment = await this.getWorkspaceAppointment(id, principal);
    this.publishVisitEvent(
      appointment,
      data.sendToPharmacy === true
        ? 'PRESCRIPTION_SENT_TO_PHARMACY'
        : 'PRESCRIPTION_FINALIZED',
      data.sendToPharmacy === true
        ? 'Prescription sent to pharmacy'
        : 'Prescription finalized',
      data.sendToPharmacy === true
        ? 'The finalized prescription was sent to the pharmacy workflow.'
        : 'The prescription is ready for printing and review.',
    );
    await this.sendPatientNotification(appointment, {
      title:
        data.sendToPharmacy === true
          ? 'Prescription sent to pharmacy'
          : 'Prescription finalized',
      message:
        data.sendToPharmacy === true
          ? 'Your finalized prescription has been sent to the pharmacy workflow.'
          : 'A finalized prescription is now available in your medical records.',
      eventType:
        data.sendToPharmacy === true
          ? 'PRESCRIPTION_SENT_TO_PHARMACY'
          : 'PRESCRIPTION_FINALIZED',
    });
    return this.buildConsultationWorkspacePayload(
      await this.getWorkspaceAppointment(id, principal),
    );
  }

  async duplicatePreviousPrescription(
    id: bigint,
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);
    if (!appointment.customerId) {
      throw new BadRequestException('Patient is not attached to this visit.');
    }

    const previousConsultations = await this.prisma.consultation.findMany({
      where: {
        customerId: appointment.customerId,
        appointmentId: { not: appointment.id },
      },
      orderBy: { id: 'desc' },
      take: 10,
    });

    const previousState = previousConsultations
      .map((consultation) => this.parseStructuredConsultationState(consultation.notes))
      .find((state) => state.prescriptionDraft.items.length > 0);

    if (!previousState) {
      throw new BadRequestException(
        'No previous prescription was found for this patient.',
      );
    }

    await this.upsertVisitPrescription(
      id,
      {
        clinicalRemarks: previousState.prescriptionDraft.clinicalRemarks,
        items: previousState.prescriptionDraft.items,
      },
      { finalized: false, sendToPharmacy: false },
    );
    await this.recordAuditAction({
      action: 'PRESCRIPTION_DUPLICATED',
      entityType: 'APPOINTMENT',
      entityId: id,
      userId: auditActor?.userId,
      details: { appointmentId: id.toString() },
    });
    const refreshed = await this.getWorkspaceAppointment(id, principal);
    this.publishVisitEvent(
      refreshed,
      'PRESCRIPTION_DUPLICATED',
      'Previous prescription copied',
      'Medicines from an earlier visit were copied into this draft.',
    );
    return this.buildConsultationWorkspacePayload(refreshed);
  }

  async copyPrescriptionToOpenVisit(
    id: bigint,
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const sourceAppointment = await this.getWorkspaceAppointment(id, principal);
    if (!sourceAppointment.customerId) {
      throw new BadRequestException('Patient is not attached to this visit.');
    }

    const sourceConsultation = sourceAppointment.consultations?.[0];
    const sourceState = this.parseStructuredConsultationState(sourceConsultation?.notes);
    if (sourceState.prescriptionDraft.items.length === 0) {
      throw new BadRequestException('No historical prescription is available to copy.');
    }

    const targetAppointment = await this.findOpenVisitForCustomer(
      sourceAppointment.customerId,
      sourceAppointment.id,
    );
    if (!targetAppointment) {
      throw new BadRequestException(
        'There is no active visit available for this patient right now.',
      );
    }

    await this.upsertVisitPrescription(
      targetAppointment.id,
      {
        clinicalRemarks: sourceState.prescriptionDraft.clinicalRemarks,
        items: sourceState.prescriptionDraft.items,
      },
      { finalized: false, sendToPharmacy: false },
    );
    await this.recordAuditAction({
      action: 'PRESCRIPTION_COPIED_TO_ACTIVE_VISIT',
      entityType: 'APPOINTMENT',
      entityId: targetAppointment.id,
      userId: auditActor?.userId,
      details: {
        sourceAppointmentId: sourceAppointment.id.toString(),
        targetAppointmentId: targetAppointment.id.toString(),
      },
    });
    this.publishVisitEvent(
      targetAppointment,
      'PRESCRIPTION_COPIED_TO_ACTIVE_VISIT',
      'Historical prescription copied',
      'A past prescription was copied into the active visit draft.',
    );
    return this.buildConsultationWorkspacePayload(
      await this.getWorkspaceAppointment(targetAppointment.id, principal),
    );
  }

  async searchMedicineCatalog(query?: string) {
    const normalized = query?.trim();
    return this.prisma.product.findMany({
      where: normalized
        ? {
            OR: [
              { productName: { contains: normalized, mode: 'insensitive' } },
              { brand: { contains: normalized, mode: 'insensitive' } },
              { productCode: { contains: normalized, mode: 'insensitive' } },
            ],
          }
        : undefined,
      orderBy: [{ productName: 'asc' }],
      take: 15,
    });
  }

  async voidVisitInvoice(
    id: bigint,
    reason?: string,
    principal?: ShieldPrincipal,
    auditActor?: { userId?: bigint | null; roleCode?: string | null },
  ) {
    const appointment = await this.getWorkspaceAppointment(id, principal);
    const invoice = appointment.purchases?.find((purchase) =>
      this.isVisitPurchase(purchase.purchaseKind),
    );
    if (!invoice) {
      throw new BadRequestException('There is no visit invoice to void.');
    }

    const payment = this.parsePaymentSummary(invoice.paymentSummary);
    if (payment.paidAmount > 0 || payment.walletUsed > 0) {
      throw new BadRequestException(
        'Paid invoices cannot be voided. Record a refund instead.',
      );
    }

    const voidedAt = new Date().toISOString();
    const nextPayment: PaymentSummaryState = {
      ...payment,
      invoiceVoidedAt: voidedAt,
      invoiceVoidReason: this.normalizeText(reason, 'Invoice voided by provider'),
    };

    await this.prisma.purchase.update({
      where: { id: invoice.id },
      data: {
        paymentStatus: 'VOID',
        paymentSummary: nextPayment,
        billingSnapshot: {
          ...((invoice.billingSnapshot as Record<string, unknown> | null) ?? {}),
          invoiceStatus: 'VOID',
          invoiceVoidedAt: voidedAt,
          invoiceVoidReason: nextPayment.invoiceVoidReason,
        },
      },
    });

    await this.recordAuditAction({
      action: 'VISIT_INVOICE_VOIDED',
      entityType: 'PURCHASE',
      entityId: invoice.id,
      userId: auditActor?.userId,
      details: {
        appointmentId: id.toString(),
        invoiceNumber: invoice.invoiceNumber,
        reason: nextPayment.invoiceVoidReason,
      },
    });
    this.publishVisitEvent(
      appointment,
      'VISIT_INVOICE_VOIDED',
      'Invoice voided',
      nextPayment.invoiceVoidReason ?? 'The invoice was voided for this visit.',
    );
    await this.sendPatientNotification(appointment, {
      title: 'Invoice voided',
      message:
        nextPayment.invoiceVoidReason ?? 'A visit invoice was voided for this record.',
      eventType: 'VISIT_INVOICE_VOIDED',
    });

    return this.buildConsultationWorkspacePayload(
      await this.getWorkspaceAppointment(id),
    );
  }

  private async upsertVisitPrescription(
    id: bigint,
    data: {
      clinicalRemarks?: string;
      items?: Array<Record<string, unknown>> | PrescriptionMedicineState[];
    },
    options: { finalized: boolean; sendToPharmacy: boolean },
  ) {
    const appointment = await this.getWorkspaceAppointment(id);
    const consultation = await this.ensureConsultationRecord(appointment);
    const currentState = this.parseStructuredConsultationState(consultation.notes);
    const nextItems = Array.isArray(data.items)
      ? data.items.map((item) =>
          this.normalizePrescriptionItem(item as Record<string, unknown>),
        )
      : currentState.prescriptionDraft.items;
    const filteredItems = nextItems.filter(
      (item) => item.productName.trim().length > 0,
    );

    if (options.finalized && filteredItems.length === 0) {
      throw new BadRequestException(
        'Add at least one medicine before finalizing the prescription.',
      );
    }

    const nowIso = new Date().toISOString();
    const nextPrescriptionDraft: PrescriptionDraftState = {
      status:
        filteredItems.length === 0
          ? 'EMPTY'
          : options.finalized
            ? 'FINALIZED'
            : 'DRAFT',
      clinicalRemarks: this.normalizeText(
        data.clinicalRemarks,
        currentState.prescriptionDraft.clinicalRemarks,
      ),
      items: filteredItems,
      finalizedAt: options.finalized
        ? nowIso
        : currentState.prescriptionDraft.finalizedAt,
      sentToPharmacyAt: options.sendToPharmacy
        ? nowIso
        : currentState.prescriptionDraft.sentToPharmacyAt,
    };

    await this.prisma.consultation.update({
      where: { id: consultation.id },
      data: {
        notes: this.serializeStructuredConsultationState({
          ...currentState,
          prescriptionDraft: nextPrescriptionDraft,
        }),
      },
    });

    if (!options.finalized) {
      return;
    }

    const existingPrescription = await this.prisma.prescription.findFirst({
      where: { consultationId: consultation.id },
      orderBy: { id: 'desc' },
    });

    if (existingPrescription) {
      await this.prisma.prescription.update({
        where: { id: existingPrescription.id },
        data: { issueDate: new Date(nowIso) },
      });
      return;
    }

    await this.prisma.prescription.create({
      data: {
        customerId: appointment.customerId,
        consultationId: consultation.id,
        issueDate: new Date(nowIso),
      },
    });
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
      prescriptionDraft: {
        status: data.prescriptionDraft.status,
        clinicalRemarks: this.normalizeText(data.prescriptionDraft.clinicalRemarks),
        finalizedAt: data.prescriptionDraft.finalizedAt,
        sentToPharmacyAt: data.prescriptionDraft.sentToPharmacyAt,
        items: data.prescriptionDraft.items.map((item) => ({
          productId: this.normalizeText(item.productId),
          productCode: this.normalizeText(item.productCode),
          productName: this.normalizeText(item.productName),
          brand: this.normalizeText(item.brand),
          unit: this.normalizeText(item.unit),
          strength: this.normalizeText(item.strength),
          dosage: this.normalizeText(item.dosage),
          route: this.normalizeText(item.route),
          frequency: this.normalizeText(item.frequency),
          duration: this.normalizeText(item.duration),
          morning: item.morning,
          afternoon: item.afternoon,
          night: item.night,
          beforeFood: item.beforeFood,
          afterFood: item.afterFood,
          specialInstructions: this.normalizeText(item.specialInstructions),
          clinicalRemarks: this.normalizeText(item.clinicalRemarks),
        })),
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

  private mergePrescriptionDraft(
    existing: PrescriptionDraftState,
    draft?: Record<string, unknown> | Partial<PrescriptionDraftState>,
  ): PrescriptionDraftState {
    const source = (draft ?? {}) as Record<string, unknown>;
    const hasItems = Object.prototype.hasOwnProperty.call(source, 'items');
    const rawItems = Array.isArray(source['items']) ? source['items'] : [];
    const items = rawItems
      .map((item) => this.normalizePrescriptionItem(item as Record<string, unknown>))
      .filter((item) => item.productName.trim().length > 0);
    const status =
      (hasItems ? items.length : existing.items.length) == 0
        ? 'EMPTY'
        : ((source['status']?.toString().toUpperCase() as
            | 'EMPTY'
            | 'DRAFT'
            | 'FINALIZED'
            | undefined) ?? existing.status ?? 'DRAFT');
    return {
      status,
      clinicalRemarks: this.normalizeText(
        source['clinicalRemarks'],
        existing.clinicalRemarks,
      ),
      finalizedAt: source['finalizedAt']?.toString() ?? existing.finalizedAt,
      sentToPharmacyAt:
        source['sentToPharmacyAt']?.toString() ?? existing.sentToPharmacyAt,
      items: hasItems ? items : existing.items,
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

  private defaultPrescriptionDraft(): PrescriptionDraftState {
    return {
      status: 'EMPTY',
      clinicalRemarks: '',
      items: [],
      finalizedAt: null,
      sentToPharmacyAt: null,
    };
  }

  private normalizePrescriptionItem(
    value?: Record<string, unknown>,
  ): PrescriptionMedicineState {
    const source = value ?? {};
    return {
      productId: this.normalizeText(source['productId']),
      productCode: this.normalizeText(source['productCode']),
      productName: this.normalizeText(source['productName']),
      brand: this.normalizeText(source['brand']),
      unit: this.normalizeText(source['unit']),
      strength: this.normalizeText(source['strength']),
      dosage: this.normalizeText(source['dosage']),
      route: this.normalizeText(source['route'], 'Oral'),
      frequency: this.normalizeText(source['frequency']),
      duration: this.normalizeText(source['duration']),
      morning: Boolean(source['morning']),
      afternoon: Boolean(source['afternoon']),
      night: Boolean(source['night']),
      beforeFood: Boolean(source['beforeFood']),
      afterFood: Boolean(source['afterFood']),
      specialInstructions: this.normalizeText(source['specialInstructions']),
      clinicalRemarks: this.normalizeText(source['clinicalRemarks']),
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
    const status = this.resolvePaymentStatus({
      walletUsed,
      cash,
      upi,
      card,
      pending,
      refund,
      paidAmount,
      balanceDue,
      recordedAt: null,
      history: previous?.history ?? [],
      invoiceVoidedAt: previous?.invoiceVoidedAt ?? null,
      invoiceVoidReason: previous?.invoiceVoidReason ?? null,
    });
    const history = [...(previous?.history ?? [])];
    const hasChanged =
      previous == null ||
      previous.walletUsed !== walletUsed ||
      previous.cash !== cash ||
      previous.upi !== upi ||
      previous.card !== card ||
      previous.refund !== refund ||
      previous.balanceDue !== balanceDue;
    const recordedAt =
      paidAmount > 0 || refund > 0 || previous?.recordedAt != null
        ? new Date().toISOString()
        : null;
    if (hasChanged && recordedAt != null) {
      history.push({
        kind: refund > (previous?.refund ?? 0) ? 'REFUND' : 'PAYMENT',
        status,
        recordedAt,
        walletUsed,
        cash,
        upi,
        card,
        refund,
        paidAmount,
        balanceDue,
      });
    }

    return {
      walletUsed,
      cash,
      upi,
      card,
      pending,
      refund,
      paidAmount,
      balanceDue,
      recordedAt,
      history,
      invoiceVoidedAt: previous?.invoiceVoidedAt ?? null,
      invoiceVoidReason: previous?.invoiceVoidReason ?? null,
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
      history: Array.isArray(summary['history'])
        ? (summary['history'] as Array<Record<string, unknown>>).map((item) => ({
            kind: item['kind']?.toString() ?? 'PAYMENT',
            status: item['status']?.toString() ?? 'PENDING',
            recordedAt: item['recordedAt']?.toString() ?? new Date().toISOString(),
            walletUsed: this.normalizeNumber(item['walletUsed']),
            cash: this.normalizeNumber(item['cash']),
            upi: this.normalizeNumber(item['upi']),
            card: this.normalizeNumber(item['card']),
            refund: this.normalizeNumber(item['refund']),
            paidAmount: this.normalizeNumber(item['paidAmount']),
            balanceDue: this.normalizeNumber(item['balanceDue']),
          }))
        : [],
      invoiceVoidedAt: summary['invoiceVoidedAt']?.toString() ?? null,
      invoiceVoidReason: summary['invoiceVoidReason']?.toString() ?? null,
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
