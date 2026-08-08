import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type TimelineAuditInput = {
  action: string;
  entityType: string;
  entityId?: bigint | null;
  userId?: bigint | null;
  oldData?: Record<string, unknown> | null;
  newData?: Record<string, unknown> | null;
  ipAddress?: string | null;
  deviceInfo?: string | null;
};

type TimelineEventRecord = {
  eventType: string;
  category: string;
  displayTitle: string;
  description: string;
  timestamp: string;
  actor: string;
  actorRole: string;
  patient?: {
    id: string | null;
    title: string;
  } | null;
  relatedVisit?: {
    id: string | null;
    title: string;
  } | null;
  relatedAppointment?: {
    id: string | null;
    title: string;
  } | null;
  relatedInvoice?: {
    id: string | null;
    title: string;
  } | null;
  relatedPrescription?: {
    id: string | null;
    title: string;
  } | null;
  relatedDocument?: {
    id: string | null;
    title: string;
  } | null;
  relatedWalletTransaction?: {
    id: string | null;
    title: string;
  } | null;
  status: string;
  icon: string;
  color: string;
  clickAction: {
    tab: string;
    target: string;
    recordId?: string | null;
  };
  metadata: Record<string, unknown>;
};

@Injectable()
export class TimelineService {
  constructor(private readonly prisma: PrismaService) {}

  async getPatientTimeline(customerId: bigint) {
    const [customer, membership, shieldCard, wallet, appointments, documents, notifications] =
      await Promise.all([
        this.prisma.customer.findUnique({
          where: { id: customerId },
          select: { id: true, firstName: true, lastName: true },
        }),
        this.prisma.membership.findUnique({
          where: { customerId },
          include: { membershipType: true },
        }),
        this.prisma.shieldCard.findUnique({
          where: { customerId },
          include: { issuedBusiness: true },
        }),
        this.prisma.wallet.findUnique({
          where: { customerId },
          select: { id: true },
        }),
        this.prisma.appointment.findMany({
          where: { customerId },
          include: {
            provider: {
              include: {
                business: true,
              },
            },
            consultations: {
              include: {
                prescriptions: {
                  include: {
                    document: true,
                  },
                },
              },
            },
            purchases: {
              include: {
                purchaseItems: true,
              },
              orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
            },
            labReports: {
              include: {
                document: true,
              },
            },
          },
          orderBy: [{ appointmentDate: 'desc' }, { id: 'desc' }],
        }),
        this.prisma.document.findMany({
          where: { customerId },
          include: {
            uploadedByUser: true,
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        }),
        this.prisma.notification.findMany({
          where: { customerId },
          orderBy: [{ sentAt: 'desc' }, { id: 'desc' }],
        }),
      ]);

    const walletTransactions = wallet
      ? await this.prisma.walletTransaction.findMany({
          where: {
            walletId: wallet.id,
            isCustomerVisible: true,
          },
          include: {
            createdByUser: true,
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        })
      : [];

    const patientLabel = this.getPatientLabel(customer);
    const events: TimelineEventRecord[] = [];

    if (membership) {
      events.push(
        this.createEvent({
          eventType: 'MEMBERSHIP_ISSUED',
          category: 'MEMBERSHIP',
          displayTitle: 'Membership issued',
          description:
            membership.membershipType?.name?.trim() ||
            membership.membershipNumber?.trim() ||
            'Membership is now active for this patient.',
          timestamp: (membership.activationDate ?? membership.createdAt).toISOString(),
          actor: 'SHIELD Membership',
          actorRole: 'Membership Desk',
          patientId: customerId,
          patientTitle: patientLabel,
          status: this.humanizeCode(membership.status || 'ACTIVE'),
          icon: 'workspace_premium',
          color: 'indigo',
          tab: 'overview',
          target: 'membership',
          metadata: {
            membershipNumber: membership.membershipNumber ?? '',
            membershipStatus: this.humanizeCode(membership.status || 'ACTIVE'),
            expiresOn: this.toIsoDate(membership.expiryDate),
          },
        }),
      );
    }

    if (shieldCard?.issuedAt) {
      events.push(
        this.createEvent({
          eventType: 'CARD_ISSUED',
          category: 'MEMBERSHIP',
          displayTitle: 'SHIELD card issued',
          description:
            shieldCard.issuedBusiness?.name?.trim() ||
            'A SHIELD card is now available for this patient.',
          timestamp: shieldCard.issuedAt.toISOString(),
          actor: 'SHIELD Card Desk',
          actorRole: 'Card Desk',
          patientId: customerId,
          patientTitle: patientLabel,
          status: this.humanizeCode(shieldCard.status || 'ACTIVE'),
          icon: 'badge',
          color: 'blue',
          tab: 'overview',
          target: 'membership',
          metadata: {
            cardNumber: shieldCard.cardNumber ?? '',
            branch: shieldCard.issuedBusiness?.name ?? '',
          },
        }),
      );
    }

    for (const appointment of appointments) {
      events.push(...this.buildAppointmentEvents(appointment, customerId, patientLabel));
    }

    const visitDocumentIds = new Set<string>();
    for (const appointment of appointments) {
      for (const consultation of appointment.consultations) {
        for (const prescription of consultation.prescriptions) {
          if (prescription.documentId != null) {
            visitDocumentIds.add(prescription.documentId.toString());
          }
        }
      }
      for (const report of appointment.labReports) {
        if (report.documentId != null) {
          visitDocumentIds.add(report.documentId.toString());
        }
      }
    }

    for (const document of documents) {
      const isVisitRecord = visitDocumentIds.has(document.id.toString());
      events.push(
        this.createEvent({
          eventType: this.resolveDocumentEventType(document.documentType),
          category: 'DOCUMENT',
          displayTitle: this.resolveDocumentTitle(document.documentType, document.fileName),
          description:
            this.humanizeCode(document.documentType || document.status || 'DOCUMENT') ||
            'Patient record uploaded',
          timestamp: document.createdAt.toISOString(),
          actor: this.getUserLabel(document.uploadedByUser) || 'Provider',
          actorRole: 'Care Team',
          patientId: customerId,
          patientTitle: patientLabel,
          documentId: document.id,
          documentTitle: document.fileName?.trim() || 'Patient record',
          status: this.humanizeCode(document.status || 'UPLOADED'),
          icon: this.resolveDocumentIcon(document.documentType),
          color: isVisitRecord ? 'teal' : 'blue',
          tab: isVisitRecord ? 'records' : 'documents',
          target: isVisitRecord ? 'record' : 'document',
          metadata: {
            documentType: this.humanizeCode(document.documentType || 'DOCUMENT'),
            mimeType: document.mimeType ?? '',
          },
        }),
      );
    }

    for (const transaction of walletTransactions) {
      const amount = Number(transaction.amount ?? 0);
      const walletEventType = this.resolveWalletEventType(
        transaction.transactionType,
        transaction.referenceType,
        amount,
      );
      events.push(
        this.createEvent({
          eventType: walletEventType,
          category: 'WALLET',
          displayTitle: this.resolveWalletTitle(walletEventType, transaction.remarks),
          description:
            `${this.humanizeCode(transaction.subLedgerType || 'CASH')} • ${this.formatMoney(amount)}`,
          timestamp: transaction.createdAt.toISOString(),
          actor:
            this.getUserLabel(transaction.createdByUser) ||
            (amount >= 0 ? 'SHIELD Wallet' : 'Billing Desk'),
          actorRole: 'Wallet',
          patientId: customerId,
          patientTitle: patientLabel,
          walletTransactionId: transaction.id,
          walletTransactionTitle:
            transaction.remarks?.trim() || 'Wallet transaction recorded',
          status: amount >= 0 ? 'Credited' : 'Used',
          icon: 'account_balance_wallet',
          color:
            walletEventType === 'WALLET_BENEFIT_APPLIED'
              ? 'green'
              : amount >= 0
                ? 'blue'
                : 'amber',
          tab: 'wallet',
          target: 'wallet-transaction',
          metadata: {
            amount,
            referenceType: transaction.referenceType ?? '',
            remarks: transaction.remarks ?? '',
          },
        }),
      );
    }

    for (const notification of notifications) {
      events.push(
        this.createEvent({
          eventType: 'NOTIFICATION_SENT',
          category: 'NOTIFICATION',
          displayTitle: notification.title?.trim() || 'Notification sent',
          description: notification.message?.trim() || 'Patient notification delivered.',
          timestamp: (notification.sentAt ?? new Date()).toISOString(),
          actor: 'SHIELD',
          actorRole: 'Notification Center',
          patientId: customerId,
          patientTitle: patientLabel,
          status: this.humanizeCode(notification.status || 'SENT'),
          icon: 'notifications',
          color: 'indigo',
          tab: 'notifications',
          target: 'notification',
          metadata: {
            channel: this.humanizeCode(notification.channel || 'IN_APP'),
          },
        }),
      );
    }

    return this.sortEvents(events);
  }

  async getCustomerTimeline(customerId: bigint) {
    const events = await this.getPatientTimeline(customerId);
    return events.map((event, index) => ({
      id: `${event.eventType}:${event.timestamp}:${index}`,
      category: event.category,
      displayTitle: event.displayTitle,
      description: event.description,
      timestamp: event.timestamp,
      status: event.status,
      entity: this.customerTimelineEntity(event.clickAction),
    }));
  }

  private customerTimelineEntity(action: TimelineEventRecord['clickAction']) {
    const allowedTargets = new Set([
      'membership',
      'wallet-transaction',
      'document',
      'notification',
      'appointment',
      'prescription',
      'order',
    ]);
    return allowedTargets.has(action.target)
      ? { target: action.target, id: action.recordId ?? null }
      : null;
  }

  async getVisitTimeline(appointmentId: bigint) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        customer: true,
        provider: {
          include: {
            business: true,
          },
        },
        consultations: {
          include: {
            prescriptions: {
              include: {
                document: true,
              },
            },
          },
        },
        purchases: {
          include: {
            purchaseItems: true,
          },
          orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
        },
        labReports: {
          include: {
            document: true,
          },
        },
      },
    });

    if (!appointment) {
      return [];
    }

    return this.sortEvents(
      this.buildAppointmentEvents(
        appointment,
        appointment.customerId,
        this.getPatientLabel(appointment.customer),
      ),
    );
  }

  async getProviderTimeline(providerId?: bigint) {
    const where = providerId == null ? {} : { providerId };
    const appointments = await this.prisma.appointment.findMany({
      where,
      include: {
        customer: true,
        provider: {
          include: {
            business: true,
          },
        },
        consultations: {
          include: {
            prescriptions: {
              include: {
                document: true,
              },
            },
          },
        },
        purchases: {
          include: {
            purchaseItems: true,
          },
          orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
        },
        labReports: {
          include: {
            document: true,
          },
        },
      },
      orderBy: [{ appointmentDate: 'desc' }, { id: 'desc' }],
      take: 80,
    });

    const events = appointments.flatMap((appointment) =>
      this.buildAppointmentEvents(
        appointment,
        appointment.customerId,
        this.getPatientLabel(appointment.customer),
      ),
    );

    return this.sortEvents(events).slice(0, 120);
  }

  async getBusinessTimeline(businessId: bigint) {
    const appointments = await this.prisma.appointment.findMany({
      where: {
        provider: {
          businessId,
        },
      },
      include: {
        customer: true,
        provider: {
          include: {
            business: true,
          },
        },
        consultations: {
          include: {
            prescriptions: {
              include: {
                document: true,
              },
            },
          },
        },
        purchases: {
          include: {
            purchaseItems: true,
          },
          orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
        },
        labReports: {
          include: {
            document: true,
          },
        },
      },
      orderBy: [{ appointmentDate: 'desc' }, { id: 'desc' }],
      take: 120,
    });

    const events = appointments.flatMap((appointment) =>
      this.buildAppointmentEvents(
        appointment,
        appointment.customerId,
        this.getPatientLabel(appointment.customer),
      ),
    );

    return this.sortEvents(events).slice(0, 160);
  }

  async recordAuditLog(input: TimelineAuditInput) {
    await this.prisma.auditLog.create({
      data: {
        userId: input.userId ?? null,
        action: input.action,
        entityType: input.entityType,
        entityId: input.entityId ?? null,
        oldData: (input.oldData ?? undefined) as Prisma.InputJsonValue | undefined,
        newData: (input.newData ?? undefined) as Prisma.InputJsonValue | undefined,
        ipAddress: input.ipAddress ?? null,
        deviceInfo: input.deviceInfo ?? null,
      },
    });
  }

  private buildAppointmentEvents(
    appointment: {
      id: bigint;
      customerId: bigint | null;
      appointmentDate: Date | null;
      appointmentType: string | null;
      status: string | null;
      remarks: string | null;
      customer?: { firstName: string | null; lastName: string | null } | null;
      provider?: {
        providerName: string | null;
        providerType?: string | null;
        business?: { name: string | null } | null;
      } | null;
      consultations: Array<{
        id: bigint;
        diagnosis: string | null;
        notes: string | null;
        prescriptions: Array<{
          id: bigint;
          issueDate: Date | null;
          documentId: bigint | null;
          document?: { id: bigint; fileName: string | null } | null;
        }>;
      }>;
      purchases: Array<{
        id: bigint;
        invoiceNumber: string | null;
        payableAmount: unknown;
        paymentStatus: string | null;
        purchaseDate: Date | null;
        paymentSummary: unknown;
        purchaseItems: Array<{
          id: bigint;
          itemType: string | null;
          itemName: string | null;
          totalPrice: unknown;
        }>;
      }>;
      labReports: Array<{
        id: bigint;
        reportDate: Date | null;
        documentId: bigint | null;
        document?: { id: bigint; fileName: string | null } | null;
      }>;
    },
    patientId: bigint | null,
    patientTitle: string,
  ) {
    const events: TimelineEventRecord[] = [];
    const providerName = appointment.provider?.providerName?.trim() || 'Provider';
    const providerRole = this.humanizeCode(
      appointment.provider?.providerType || 'PROVIDER',
    );
    const appointmentTimestamp = (
      appointment.appointmentDate ?? new Date()
    ).toISOString();
    const visitTitle = this.getAppointmentTypeLabel(appointment.appointmentType);
    const visitDescription =
      appointment.remarks?.trim() || 'Patient visit is scheduled with the care team.';

    events.push(
      this.createEvent({
        eventType: 'APPOINTMENT_CREATED',
        category: 'VISIT',
        displayTitle: 'Visit scheduled',
        description: visitDescription,
        timestamp: appointmentTimestamp,
        actor: providerName,
        actorRole: providerRole,
        patientId,
        patientTitle,
        appointmentId: appointment.id,
        appointmentTitle: visitTitle,
        visitId: appointment.id,
        visitTitle,
        status: this.getAppointmentStatusLabel(appointment.status),
        icon: 'event',
        color: 'blue',
        tab: 'appointments',
        target: 'appointment',
        metadata: {
          appointmentType: visitTitle,
          branch: appointment.provider?.business?.name ?? '',
        },
      }),
    );

    const statusCode = (appointment.status || '').toUpperCase();
    if (statusCode === 'CONFIRMED') {
      events.push(
        this.createEvent({
          eventType: 'APPOINTMENT_CONFIRMED',
          category: 'VISIT',
          displayTitle: 'Visit confirmed',
          description: `${visitTitle} is confirmed with ${providerName}.`,
          timestamp: appointmentTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          status: 'Confirmed',
          icon: 'event_available',
          color: 'green',
          tab: 'appointments',
          target: 'appointment',
        }),
      );
    }

    const consultation = appointment.consultations[0];
    const structuredState = this.parseStructuredConsultationState(
      consultation?.notes || null,
    );
    if (consultation != null || statusCode === 'IN_PROGRESS' || statusCode === 'COMPLETED') {
      events.push(
        this.createEvent({
          eventType: 'CONSULTATION_STARTED',
          category: 'VISIT',
          displayTitle: 'Consultation started',
          description:
            structuredState.chiefComplaint ||
            'The provider has started working on this visit.',
          timestamp: appointmentTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          status: statusCode === 'COMPLETED' ? 'Completed' : 'In Progress',
          icon: 'stethoscope',
          color: 'blue',
          tab: 'today-visit',
          target: 'visit',
          metadata: {
            symptoms: structuredState.symptoms,
            clinicalFindings: structuredState.clinicalFindings,
          },
        }),
      );
    }

    if (consultation?.diagnosis?.trim()) {
      events.push(
        this.createEvent({
          eventType: statusCode === 'COMPLETED'
            ? 'CONSULTATION_COMPLETED'
            : 'CONSULTATION_UPDATED',
          category: 'VISIT',
          displayTitle:
            statusCode === 'COMPLETED'
              ? 'Consultation completed'
              : 'Consultation updated',
          description: consultation.diagnosis.trim(),
          timestamp: appointmentTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          status:
            statusCode === 'COMPLETED' ? 'Completed' : 'Care Updated',
          icon: 'clinical_notes',
          color: 'indigo',
          tab: 'today-visit',
          target: 'visit',
          metadata: {
            diagnosis: consultation.diagnosis.trim(),
            advice: structuredState.advice,
            providerNotes: structuredState.providerNotes,
          },
        }),
      );
    }

    if (structuredState.procedures) {
      events.push(
        this.createEvent({
          eventType: 'PROCEDURE_RECORDED',
          category: 'VISIT',
          displayTitle: 'Procedure added',
          description: structuredState.procedures,
          timestamp: appointmentTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          status: 'Procedure Added',
          icon: 'medical_services',
          color: 'amber',
          tab: 'today-visit',
          target: 'visit',
          metadata: {
            procedures: structuredState.procedures,
          },
        }),
      );
    }

    if (structuredState.labOrders) {
      events.push(
        this.createEvent({
          eventType: 'LAB_TEST_ORDERED',
          category: 'LAB',
          displayTitle: 'Lab work requested',
          description: structuredState.labOrders,
          timestamp: appointmentTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          status: 'Ordered',
          icon: 'biotech',
          color: 'purple',
          tab: 'records',
          target: 'lab-order',
          metadata: {
            labOrders: structuredState.labOrders,
          },
        }),
      );
    }

    for (const prescription of consultation?.prescriptions ?? []) {
      events.push(
        this.createEvent({
          eventType: 'PRESCRIPTION_GENERATED',
          category: 'PRESCRIPTION',
          displayTitle: 'Prescription generated',
          description:
            prescription.document?.fileName?.trim() ||
            'Prescription is available for this visit.',
          timestamp: (
            prescription.issueDate ??
            appointment.appointmentDate ??
            new Date()
          ).toISOString(),
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          prescriptionId: prescription.id,
          prescriptionTitle: 'Prescription',
          documentId: prescription.document?.id ?? null,
          documentTitle: prescription.document?.fileName ?? 'Prescription',
          status: 'Ready',
          icon: 'medication',
          color: 'teal',
          tab: 'prescriptions',
          target: 'prescription',
        }),
      );
    }

    for (const report of appointment.labReports) {
      const reportTimestamp = (
        report.reportDate ??
        appointment.appointmentDate ??
        new Date()
      ).toISOString();
      events.push(
        this.createEvent({
          eventType: 'LAB_REPORT_UPLOADED',
          category: 'LAB',
          displayTitle: 'Lab report uploaded',
          description:
            report.document?.fileName?.trim() ||
            'Lab results are available for this visit.',
          timestamp: reportTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          documentId: report.document?.id ?? null,
          documentTitle: report.document?.fileName ?? 'Lab report',
          status: 'Uploaded',
          icon: 'lab_profile',
          color: 'purple',
          tab: 'records',
          target: 'lab-report',
        }),
      );
    }

    for (const purchase of appointment.purchases) {
      const grandTotal = Number(purchase.payableAmount ?? 0);
      events.push(
        this.createEvent({
          eventType: 'INVOICE_GENERATED',
          category: 'BILLING',
          displayTitle: 'Invoice generated',
          description: `${purchase.invoiceNumber ?? 'Visit invoice'} • ${this.formatMoney(grandTotal)}`,
          timestamp: (purchase.purchaseDate ?? appointment.appointmentDate ?? new Date()).toISOString(),
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          invoiceId: purchase.id,
          invoiceTitle: purchase.invoiceNumber ?? 'Visit invoice',
          status: this.getPaymentStatusLabel(purchase.paymentStatus),
          icon: 'receipt_long',
          color: 'amber',
          tab: 'payments',
          target: 'invoice',
          metadata: {
            total: grandTotal,
            medicineCount: purchase.purchaseItems.filter(
              (item) => (item.itemType || '').toUpperCase() === 'MEDICINE',
            ).length,
            procedureCount: purchase.purchaseItems.filter(
              (item) => (item.itemType || '').toUpperCase() === 'PROCEDURE',
            ).length,
          },
        }),
      );

      const payment = this.parsePaymentSummary(purchase.paymentSummary);
      if (payment.paidAmount > 0) {
        const paymentMethod = this.resolvePaymentMethodLabel(payment);
        events.push(
          this.createEvent({
            eventType: 'INVOICE_PAID',
            category: 'BILLING',
            displayTitle: 'Payment received',
            description: `${this.formatMoney(payment.paidAmount)} collected${paymentMethod ? ` • ${paymentMethod}` : ''}`,
            timestamp:
              payment.recordedAt ||
              (purchase.purchaseDate ?? appointment.appointmentDate ?? new Date()).toISOString(),
            actor: providerName,
            actorRole: providerRole,
            patientId,
            patientTitle,
            appointmentId: appointment.id,
            appointmentTitle: visitTitle,
            visitId: appointment.id,
            visitTitle,
            invoiceId: purchase.id,
            invoiceTitle: purchase.invoiceNumber ?? 'Visit invoice',
            status: this.getPaymentStatusLabel(purchase.paymentStatus),
            icon: 'payments',
            color: 'green',
            tab: 'payments',
            target: 'payment',
            metadata: {
              amount: payment.paidAmount,
              walletUsed: payment.walletUsed,
              pending: payment.pending,
              paymentMethod,
            },
          }),
        );

        if (payment.walletUsed > 0) {
          events.push(
            this.createEvent({
              eventType: 'WALLET_BENEFIT_APPLIED',
              category: 'WALLET',
              displayTitle: 'Wallet used',
              description: `${this.formatMoney(payment.walletUsed)} used toward this invoice.`,
              timestamp:
                payment.recordedAt ||
                (purchase.purchaseDate ?? appointment.appointmentDate ?? new Date()).toISOString(),
              actor: 'SHIELD Wallet',
              actorRole: 'Wallet',
              patientId,
              patientTitle,
              appointmentId: appointment.id,
              appointmentTitle: visitTitle,
              visitId: appointment.id,
              visitTitle,
              invoiceId: purchase.id,
              invoiceTitle: purchase.invoiceNumber ?? 'Visit invoice',
              status: 'Applied',
              icon: 'account_balance_wallet',
              color: 'green',
              tab: 'wallet',
              target: 'wallet-benefit',
              metadata: {
                amount: payment.walletUsed,
              },
            }),
          );
        }
      }
    }

    if (structuredState.followUp) {
      events.push(
        this.createEvent({
          eventType: 'FOLLOW_UP_CREATED',
          category: 'VISIT',
          displayTitle: 'Follow-up planned',
          description: structuredState.followUp,
          timestamp: appointmentTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          status: 'Planned',
          icon: 'event_repeat',
          color: 'teal',
          tab: 'appointments',
          target: 'follow-up',
        }),
      );
    }

    if (statusCode === 'COMPLETED') {
      events.push(
        this.createEvent({
          eventType: 'VISIT_CLOSED',
          category: 'VISIT',
          displayTitle: 'Visit closed',
          description: 'This visit has been completed and closed for the patient.',
          timestamp: appointmentTimestamp,
          actor: providerName,
          actorRole: providerRole,
          patientId,
          patientTitle,
          appointmentId: appointment.id,
          appointmentTitle: visitTitle,
          visitId: appointment.id,
          visitTitle,
          status: 'Completed',
          icon: 'task_alt',
          color: 'green',
          tab: 'today-visit',
          target: 'visit',
        }),
      );
    }

    return events;
  }

  private createEvent(args: {
    eventType: string;
    category: string;
    displayTitle: string;
    description: string;
    timestamp: string;
    actor: string;
    actorRole: string;
    patientId?: bigint | null;
    patientTitle?: string | null;
    visitId?: bigint | null;
    visitTitle?: string | null;
    appointmentId?: bigint | null;
    appointmentTitle?: string | null;
    invoiceId?: bigint | null;
    invoiceTitle?: string | null;
    prescriptionId?: bigint | null;
    prescriptionTitle?: string | null;
    documentId?: bigint | null;
    documentTitle?: string | null;
    walletTransactionId?: bigint | null;
    walletTransactionTitle?: string | null;
    status: string;
    icon: string;
    color: string;
    tab: string;
    target: string;
    metadata?: Record<string, unknown>;
  }): TimelineEventRecord & Record<string, unknown> {
    const event: TimelineEventRecord & Record<string, unknown> = {
      eventType: args.eventType,
      category: args.category,
      displayTitle: args.displayTitle,
      description: args.description,
      timestamp: args.timestamp,
      actor: args.actor,
      actorRole: args.actorRole,
      patient:
        args.patientId == null
          ? null
          : {
              id: args.patientId.toString(),
              title: args.patientTitle || 'Patient',
            },
      relatedVisit:
        args.visitId == null
          ? null
          : {
              id: args.visitId.toString(),
              title: args.visitTitle || 'Visit',
            },
      relatedAppointment:
        args.appointmentId == null
          ? null
          : {
              id: args.appointmentId.toString(),
              title: args.appointmentTitle || 'Visit',
            },
      relatedInvoice:
        args.invoiceId == null
          ? null
          : {
              id: args.invoiceId.toString(),
              title: args.invoiceTitle || 'Invoice',
            },
      relatedPrescription:
        args.prescriptionId == null
          ? null
          : {
              id: args.prescriptionId.toString(),
              title: args.prescriptionTitle || 'Prescription',
            },
      relatedDocument:
        args.documentId == null
          ? null
          : {
              id: args.documentId.toString(),
              title: args.documentTitle || 'Document',
            },
      relatedWalletTransaction:
        args.walletTransactionId == null
          ? null
          : {
              id: args.walletTransactionId.toString(),
              title: args.walletTransactionTitle || 'Wallet transaction',
            },
      status: args.status,
      icon: args.icon,
      color: args.color,
      clickAction: {
        tab: args.tab,
        target: args.target,
        recordId:
          args.visitId?.toString() ??
          args.appointmentId?.toString() ??
          args.invoiceId?.toString() ??
          args.documentId?.toString() ??
          args.walletTransactionId?.toString() ??
          null,
      },
      metadata: args.metadata ?? {},
      code: args.eventType,
      title: args.displayTitle,
      subtitle: args.description,
      linkedRecordId:
        args.visitId?.toString() ??
        args.appointmentId?.toString() ??
        args.invoiceId?.toString() ??
        args.documentId?.toString() ??
        args.walletTransactionId?.toString() ??
        null,
      quickNavigationTarget: {
        tab: args.tab,
        target: args.target,
      },
    };
    return event;
  }

  private sortEvents(events: TimelineEventRecord[]) {
    return [...events].sort(
      (left, right) =>
        new Date(right.timestamp).getTime() - new Date(left.timestamp).getTime(),
    );
  }

  private parseStructuredConsultationState(notes?: string | null) {
    if (!notes?.trim()) {
      return {
        chiefComplaint: '',
        symptoms: '',
        clinicalFindings: '',
        advice: '',
        procedures: '',
        labOrders: '',
        followUp: '',
        providerNotes: '',
      };
    }

    try {
      const parsed = JSON.parse(notes) as Record<string, unknown>;
      const form = (parsed.form ?? {}) as Record<string, unknown>;
      return {
        chiefComplaint: this.normalizeText(form.chiefComplaint),
        symptoms: this.normalizeText(form.symptoms),
        clinicalFindings: this.normalizeText(form.clinicalFindings),
        advice: this.normalizeText(form.advice),
        procedures: this.normalizeText(form.procedures),
        labOrders: this.normalizeText(form.labOrders),
        followUp: this.normalizeText(form.followUp),
        providerNotes: this.normalizeText(form.providerNotes),
      };
    } catch {
      return {
        chiefComplaint: '',
        symptoms: '',
        clinicalFindings: '',
        advice: '',
        procedures: '',
        labOrders: '',
        followUp: '',
        providerNotes: this.normalizeText(notes),
      };
    }
  }

  private parsePaymentSummary(value: unknown) {
    const summary = (value ?? {}) as Record<string, unknown>;
    return {
      walletUsed: Number(summary.walletUsed ?? 0),
      cash: Number(summary.cash ?? 0),
      upi: Number(summary.upi ?? 0),
      card: Number(summary.card ?? 0),
      pending: Number(summary.pending ?? 0),
      refund: Number(summary.refund ?? 0),
      paidAmount: Number(summary.paidAmount ?? 0),
      balanceDue: Number(summary.balanceDue ?? 0),
      recordedAt:
        typeof summary.recordedAt === 'string' ? summary.recordedAt : null,
    };
  }

  private resolvePaymentMethodLabel(payment: {
    walletUsed: number;
    cash: number;
    upi: number;
    card: number;
  }) {
    const labels: string[] = [];
    if (payment.walletUsed > 0) labels.push('Wallet');
    if (payment.cash > 0) labels.push('Cash');
    if (payment.upi > 0) labels.push('UPI');
    if (payment.card > 0) labels.push('Card');
    return labels.join(' + ');
  }

  private resolveWalletEventType(
    transactionType?: string | null,
    referenceType?: string | null,
    amount?: number,
  ) {
    const normalizedReference = (referenceType || '').toUpperCase();
    const normalizedType = (transactionType || '').toUpperCase();
    if (normalizedReference === 'PURCHASE' || normalizedType.includes('DEBIT')) {
      return 'WALLET_BENEFIT_APPLIED';
    }
    return (amount ?? 0) >= 0 ? 'WALLET_RECHARGED' : 'WALLET_USED';
  }

  private resolveWalletTitle(eventType: string, remarks?: string | null) {
    if (remarks?.trim()) {
      return remarks.trim();
    }
    switch (eventType) {
      case 'WALLET_BENEFIT_APPLIED':
        return 'Wallet used';
      case 'WALLET_USED':
        return 'Wallet debited';
      default:
        return 'Wallet recharged';
    }
  }

  private resolveDocumentEventType(documentType?: string | null) {
    const normalized = (documentType || '').toUpperCase();
    if (normalized === 'PRESCRIPTION') {
      return 'PRESCRIPTION_UPLOADED';
    }
    if (normalized === 'LAB_REPORT') {
      return 'LAB_REPORT_UPLOADED';
    }
    if (normalized === 'MEDICAL_CERTIFICATE') {
      return 'MEDICAL_CERTIFICATE_UPLOADED';
    }
    return 'DOCUMENT_UPLOADED';
  }

  private resolveDocumentTitle(documentType?: string | null, fileName?: string | null) {
    if (fileName?.trim()) {
      return fileName.trim();
    }
    const normalized = (documentType || '').toUpperCase();
    if (normalized === 'LAB_REPORT') {
      return 'Lab report uploaded';
    }
    if (normalized === 'PRESCRIPTION') {
      return 'Prescription uploaded';
    }
    return 'Document uploaded';
  }

  private resolveDocumentIcon(documentType?: string | null) {
    const normalized = (documentType || '').toUpperCase();
    if (normalized === 'LAB_REPORT') {
      return 'lab_profile';
    }
    if (normalized === 'PRESCRIPTION') {
      return 'medication';
    }
    return 'description';
  }

  private getPatientLabel(
    patient?:
      | {
          firstName: string | null;
          lastName: string | null;
        }
      | null,
  ) {
    return (
      `${patient?.firstName ?? ''} ${patient?.lastName ?? ''}`.trim() || 'Patient'
    );
  }

  private getUserLabel(
    user?:
      | {
          firstName?: string | null;
          lastName?: string | null;
        }
      | null,
  ) {
    return `${user?.firstName ?? ''} ${user?.lastName ?? ''}`.trim();
  }

  private humanizeCode(value?: string | null) {
    return (value || '')
      .toLowerCase()
      .split(/[_\s-]+/)
      .filter(Boolean)
      .map((part) => `${part[0].toUpperCase()}${part.slice(1)}`)
      .join(' ');
  }

  private getAppointmentTypeLabel(type?: string | null) {
    const normalized = (type || '').toUpperCase();
    switch (normalized) {
      case 'CONSULTATION':
        return 'Consultation Visit';
      case 'CHECKUP':
        return 'Check-up Visit';
      case 'FOLLOW_UP':
        return 'Follow-up Visit';
      default:
        return this.humanizeCode(type || 'VISIT') || 'Visit';
    }
  }

  private getAppointmentStatusLabel(status?: string | null) {
    const normalized = (status || '').toUpperCase();
    switch (normalized) {
      case 'PENDING':
        return 'Waiting';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return this.humanizeCode(status || 'SCHEDULED') || 'Scheduled';
    }
  }

  private getPaymentStatusLabel(status?: string | null) {
    const normalized = (status || '').toUpperCase();
    switch (normalized) {
      case 'PAID':
        return 'Paid';
      case 'PARTIALLY_PAID':
        return 'Partially Paid';
      case 'REFUNDED':
        return 'Refunded';
      case 'PENDING':
      default:
        return 'Payment Pending';
    }
  }

  private formatMoney(value: number) {
    return `Rs ${Number(value || 0).toFixed(2)}`;
  }

  private normalizeText(value?: unknown) {
    return typeof value === 'string' ? value.trim() : '';
  }

  private toIsoDate(value?: Date | null) {
    return value == null ? null : value.toISOString();
  }
}
