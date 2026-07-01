import { Injectable } from '@nestjs/common';

type PrintTemplateMetadata = {
  id: string;
  title: string;
  category: string;
  supportedPortals: string[];
  description: string;
  outputFormat: 'PDF';
};

type PrintSection = {
  title: string;
  rows: Array<{ label: string; value: string }>;
};

type PrintPayload = {
  documentTitle?: string;
  fileName?: string;
  header?: Record<string, unknown>;
  patient?: Record<string, unknown>;
  provider?: Record<string, unknown>;
  business?: Record<string, unknown>;
  branch?: Record<string, unknown>;
  summary?: Record<string, unknown>;
  sections?: PrintSection[];
  footer?: Record<string, unknown>;
  verification?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
};

@Injectable()
export class PlatformPrintService {
  private readonly templates: PrintTemplateMetadata[] = [
    {
      id: 'PATIENT_SUMMARY',
      title: 'Patient Summary',
      category: 'patient',
      supportedPortals: [
        'customer',
        'provider',
        'agent',
        'crm',
        'manager',
        'executive',
        'super-admin',
      ],
      description: 'Patient identity, membership, wallet, and care snapshot.',
      outputFormat: 'PDF',
    },
    {
      id: 'VISIT_SUMMARY',
      title: 'Visit Summary',
      category: 'visit',
      supportedPortals: ['provider', 'crm', 'manager', 'executive', 'super-admin'],
      description: 'Clinical and billing summary for a single visit.',
      outputFormat: 'PDF',
    },
    {
      id: 'CONSULTATION_SUMMARY',
      title: 'Consultation Summary',
      category: 'clinical',
      supportedPortals: ['customer', 'provider', 'crm', 'manager', 'executive'],
      description: 'Structured consultation notes and advice.',
      outputFormat: 'PDF',
    },
    {
      id: 'PRESCRIPTION',
      title: 'Prescription',
      category: 'clinical',
      supportedPortals: ['customer', 'provider', 'crm', 'manager', 'executive'],
      description: 'Medication instructions and provider directions.',
      outputFormat: 'PDF',
    },
    {
      id: 'INVOICE',
      title: 'Invoice',
      category: 'billing',
      supportedPortals: ['customer', 'provider', 'agent', 'manager', 'executive', 'super-admin'],
      description: 'Visit or service invoice generated from backend billing data.',
      outputFormat: 'PDF',
    },
    {
      id: 'RECEIPT',
      title: 'Receipt',
      category: 'billing',
      supportedPortals: ['customer', 'provider', 'agent', 'manager', 'executive', 'super-admin'],
      description: 'Payment receipt for a completed SHIELD transaction.',
      outputFormat: 'PDF',
    },
    {
      id: 'MEMBERSHIP_CERTIFICATE',
      title: 'Membership Certificate',
      category: 'membership',
      supportedPortals: ['customer', 'agent', 'executive', 'super-admin'],
      description: 'Certificate for an approved SHIELD membership.',
      outputFormat: 'PDF',
    },
    {
      id: 'MEMBERSHIP_CARD',
      title: 'Membership Card',
      category: 'membership',
      supportedPortals: ['customer', 'agent', 'executive', 'super-admin'],
      description: 'Digital SHIELD membership card print layout.',
      outputFormat: 'PDF',
    },
    {
      id: 'REGISTRATION_RECEIPT',
      title: 'Registration Receipt',
      category: 'registration',
      supportedPortals: ['customer', 'agent', 'executive', 'super-admin'],
      description: 'Receipt for a completed customer registration workflow.',
      outputFormat: 'PDF',
    },
    {
      id: 'REFERRAL_FORM',
      title: 'Referral Form',
      category: 'referral',
      supportedPortals: ['customer', 'provider', 'agent', 'crm', 'executive'],
      description: 'Referral and onboarding handoff sheet.',
      outputFormat: 'PDF',
    },
    {
      id: 'CONSENT_FORM',
      title: 'Consent Form',
      category: 'clinical',
      supportedPortals: ['customer', 'provider', 'crm', 'executive'],
      description: 'Provider-issued consent document.',
      outputFormat: 'PDF',
    },
    {
      id: 'MEDICAL_CERTIFICATE',
      title: 'Medical Certificate',
      category: 'clinical',
      supportedPortals: ['customer', 'provider', 'crm', 'manager', 'executive'],
      description: 'Medical certificate generated from visit data.',
      outputFormat: 'PDF',
    },
    {
      id: 'REFERRAL_LETTER',
      title: 'Referral Letter',
      category: 'clinical',
      supportedPortals: ['customer', 'provider', 'crm', 'executive'],
      description: 'Referral letter to another care owner or business.',
      outputFormat: 'PDF',
    },
    {
      id: 'LAB_REPORT',
      title: 'Lab Report',
      category: 'records',
      supportedPortals: ['customer', 'provider', 'crm', 'manager', 'executive'],
      description: 'Laboratory result print layout.',
      outputFormat: 'PDF',
    },
    {
      id: 'APPOINTMENT_SLIP',
      title: 'Appointment Slip',
      category: 'appointments',
      supportedPortals: ['customer', 'provider', 'agent', 'crm', 'executive'],
      description: 'Appointment slip for customer or provider handoff.',
      outputFormat: 'PDF',
    },
    {
      id: 'VISIT_TOKEN',
      title: 'Visit Token',
      category: 'appointments',
      supportedPortals: ['customer', 'provider', 'agent', 'executive'],
      description: 'Visit queue token for care operations.',
      outputFormat: 'PDF',
    },
    {
      id: 'PAYMENT_RECEIPT',
      title: 'Payment Receipt',
      category: 'billing',
      supportedPortals: ['customer', 'provider', 'agent', 'manager', 'executive', 'super-admin'],
      description: 'Receipt with payment breakdown and verification details.',
      outputFormat: 'PDF',
    },
  ];

  listTemplates() {
    return this.templates.map((template) => ({
      ...template,
      action: 'generate(templateId, payload)',
    }));
  }

  getTemplate(templateId: string) {
    return (
      this.templates.find(
        (template) => template.id === templateId.trim().toUpperCase(),
      ) ?? null
    );
  }

  generate(templateId: string, payload: PrintPayload) {
    const template = this.getTemplate(templateId);
    if (template == null) {
      throw new Error(`Unknown print template: ${templateId}`);
    }

    const lines = this.renderTemplateLines(template, payload);
    const pdfBuffer = this.buildSimplePdf(lines);
    const base64 = pdfBuffer.toString('base64');
    const fileName =
      payload.fileName?.trim() ||
      `${template.id.toLowerCase().replace(/_/g, '-')}.pdf`;

    return {
      template,
      fileName,
      mimeType: 'application/pdf',
      format: 'PDF',
      contentBase64: base64,
      previewText: lines.join('\n'),
      generatedAt: new Date().toISOString(),
    };
  }

  buildProviderPatientPrintContext(input: {
    patient?: Record<string, any> | null;
    membership?: Record<string, any> | null;
    wallet?: Record<string, any> | null;
    activeVisit?: Record<string, any> | null;
    billing?: Record<string, any> | null;
    timeline?: Array<Record<string, any>>;
    providerContext?: Record<string, any> | null;
    documents?: Array<Record<string, any>>;
  }) {
    const patient = input.patient ?? {};
    const membership = (input.membership?.membership as Record<string, any> | undefined) ?? {};
    const wallet = input.wallet ?? {};
    const activeVisit = input.activeVisit ?? {};
    const billingSummary =
      (input.billing?.summary as Record<string, any> | undefined) ?? {};
    const providerContext = input.providerContext ?? {};
    const latestLabReport = (input.documents ?? []).find((document) =>
      `${document.documentType ?? document.type ?? ''}`
        .trim()
        .toUpperCase()
        .includes('LAB'),
    );

    const baseHeader = this.buildHeader({
      businessName:
        providerContext['business']?.['name']?.toString() ?? 'SHIELD',
      branchName:
        providerContext['branch']?.['name']?.toString() ?? 'Primary Branch',
      generatedBy:
        providerContext['providerName']?.toString() ?? 'SHIELD Team',
    });

    const basePatient = {
      name: patient['fullName']?.toString() ?? patient['firstName']?.toString() ?? 'SHIELD Member',
      patientId: patient['customerCode']?.toString() ?? patient['id']?.toString() ?? '',
      mobile: patient['mobile']?.toString() ?? '',
      bloodGroup: patient['bloodGroup']?.toString() ?? '',
      membershipNumber: membership['membershipNumber']?.toString() ?? '',
      shieldCardNumber: patient['shieldCardNumber']?.toString() ?? '',
    };

    const baseProvider = {
      name: providerContext['providerName']?.toString() ?? 'Provider',
      role: providerContext['role']?.toString() ?? 'Provider',
      department: providerContext['department']?.toString() ?? '',
    };

    return {
      templates: [
        'PATIENT_SUMMARY',
        'VISIT_SUMMARY',
        'CONSULTATION_SUMMARY',
        'PRESCRIPTION',
        'INVOICE',
        'PAYMENT_RECEIPT',
        'MEDICAL_CERTIFICATE',
        'REFERRAL_LETTER',
        'APPOINTMENT_SLIP',
        'LAB_REPORT',
      ]
        .map((id) => this.getTemplate(id))
        .filter(
          (template): template is PrintTemplateMetadata => template != null,
        ),
      payloads: {
        PATIENT_SUMMARY: {
          documentTitle: 'Patient Summary',
          fileName: `patient-summary-${basePatient['patientId'] || 'record'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          summary: {
            status: patient['status']?.toString() ?? 'ACTIVE',
            membershipStatus: membership['status']?.toString() ?? 'PENDING',
            walletBalance:
              wallet['cashWallet']?.['available']?.toString() ?? '0.00',
            rewardPoints:
              wallet['rewardPoints']?.['available']?.toString() ?? '0.00',
          },
          sections: [
            {
              title: 'Patient Snapshot',
              rows: [
                {
                  label: 'Membership',
                  value: `${membership['membershipType']?.['name'] ?? 'Not assigned'}`,
                },
                {
                  label: 'Wallet Balance',
                  value: `Rs ${wallet['cashWallet']?.['available'] ?? 0}`,
                },
                {
                  label: 'Reward Points',
                  value: `${wallet['rewardPoints']?.['available'] ?? 0}`,
                },
              ],
            },
          ],
          footer: this.buildFooter(basePatient['patientId']?.toString()),
          verification: this.buildVerification(basePatient['patientId']?.toString()),
        },
        VISIT_SUMMARY: {
          documentTitle: 'Visit Summary',
          fileName: `visit-summary-${activeVisit['appointmentId'] ?? basePatient['patientId'] ?? 'visit'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          summary: {
            visitStatus: activeVisit['status']?.toString() ?? '',
            appointmentDate:
              activeVisit['appointment']?.['appointmentDate']?.toString() ??
              '',
          },
          sections: [
            {
              title: 'Visit Overview',
              rows: [
                { label: 'Status', value: activeVisit['status']?.toString() ?? 'Open' },
                {
                  label: 'Appointment',
                  value:
                    activeVisit['appointment']?.['typeLabel']?.toString() ??
                    'Visit',
                },
                {
                  label: 'Timeline Events',
                  value: `${(input.timeline ?? []).length}`,
                },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(activeVisit['appointmentId']?.toString()),
        },
        CONSULTATION_SUMMARY: {
          documentTitle: 'Consultation Summary',
          fileName: `consultation-summary-${activeVisit['appointmentId'] ?? 'consultation'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          summary: {
            visitStatus: activeVisit['status']?.toString() ?? '',
          },
          sections: [
            {
              title: 'Clinical Notes',
              rows: [
                {
                  label: 'Diagnosis',
                  value:
                    activeVisit['workspace']?.['form']?.['diagnosis']?.toString() ??
                    'Not recorded',
                },
                {
                  label: 'Advice',
                  value:
                    activeVisit['workspace']?.['form']?.['advice']?.toString() ??
                    'Not recorded',
                },
                {
                  label: 'Follow Up',
                  value:
                    activeVisit['workspace']?.['form']?.['followUp']?.toString() ??
                    'Not recorded',
                },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(activeVisit['appointmentId']?.toString()),
        },
        PRESCRIPTION: {
          documentTitle: 'Prescription',
          fileName: `prescription-${activeVisit['appointmentId'] ?? 'patient'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          sections: [
            {
              title: 'Prescription Notes',
              rows: [
                {
                  label: 'Diagnosis',
                  value:
                    activeVisit['workspace']?.['form']?.['diagnosis']?.toString() ??
                    'Pending',
                },
                {
                  label: 'Provider Notes',
                  value:
                    activeVisit['workspace']?.['form']?.['providerNotes']?.toString() ??
                    'Pending',
                },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(activeVisit['appointmentId']?.toString()),
        },
        INVOICE: {
          documentTitle: 'Invoice',
          fileName: `invoice-${billingSummary['lastInvoiceNumber'] ?? activeVisit['appointmentId'] ?? 'visit'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          summary: {
            invoiceNumber: billingSummary['lastInvoiceNumber']?.toString() ?? '',
            totalInvoices: `${billingSummary['totalInvoices'] ?? 0}`,
          },
          sections: [
            {
              title: 'Billing Summary',
              rows: [
                { label: 'Total Billed', value: `Rs ${billingSummary['totalBilled'] ?? 0}` },
                { label: 'Total Discount', value: `Rs ${billingSummary['totalDiscount'] ?? 0}` },
                { label: 'Total Payable', value: `Rs ${billingSummary['totalPayable'] ?? 0}` },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(billingSummary['lastInvoiceNumber']?.toString()),
        },
        PAYMENT_RECEIPT: {
          documentTitle: 'Payment Receipt',
          fileName: `payment-receipt-${billingSummary['lastInvoiceNumber'] ?? activeVisit['appointmentId'] ?? 'visit'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          sections: [
            {
              title: 'Payment Summary',
              rows: [
                { label: 'Total Payable', value: `Rs ${billingSummary['totalPayable'] ?? 0}` },
                { label: 'Latest Invoice', value: `${billingSummary['lastInvoiceNumber'] ?? 'Pending'}` },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(billingSummary['lastInvoiceNumber']?.toString()),
        },
        MEDICAL_CERTIFICATE: {
          documentTitle: 'Medical Certificate',
          fileName: `medical-certificate-${activeVisit['appointmentId'] ?? basePatient['patientId'] ?? 'visit'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          sections: [
            {
              title: 'Certificate Details',
              rows: [
                {
                  label: 'Diagnosis',
                  value:
                    activeVisit['workspace']?.['form']?.['diagnosis']?.toString() ??
                    'Not recorded',
                },
                {
                  label: 'Follow Up',
                  value:
                    activeVisit['workspace']?.['form']?.['followUp']?.toString() ??
                    'Not recorded',
                },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(activeVisit['appointmentId']?.toString()),
        },
        REFERRAL_LETTER: {
          documentTitle: 'Referral Letter',
          fileName: `referral-letter-${activeVisit['appointmentId'] ?? basePatient['patientId'] ?? 'visit'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          sections: [
            {
              title: 'Referral Summary',
              rows: [
                {
                  label: 'Diagnosis',
                  value:
                    activeVisit['workspace']?.['form']?.['diagnosis']?.toString() ??
                    'Not recorded',
                },
                {
                  label: 'Clinical Notes',
                  value:
                    activeVisit['workspace']?.['form']?.['providerNotes']?.toString() ??
                    'Not recorded',
                },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(activeVisit['appointmentId']?.toString()),
        },
        APPOINTMENT_SLIP: {
          documentTitle: 'Appointment Slip',
          fileName: `appointment-slip-${activeVisit['appointmentId'] ?? basePatient['patientId'] ?? 'appointment'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          sections: [
            {
              title: 'Appointment Details',
              rows: [
                {
                  label: 'Visit Type',
                  value:
                    activeVisit['appointment']?.['typeLabel']?.toString() ??
                    'Visit',
                },
                {
                  label: 'Status',
                  value: activeVisit['status']?.toString() ?? 'Scheduled',
                },
              ],
            },
          ],
          footer: this.buildFooter(activeVisit['appointmentId']?.toString()),
          verification: this.buildVerification(activeVisit['appointmentId']?.toString()),
        },
        LAB_REPORT: {
          documentTitle: 'Lab Report',
          fileName: `lab-report-${basePatient['patientId'] ?? 'record'}.pdf`,
          header: baseHeader,
          patient: basePatient,
          provider: baseProvider,
          sections: [
            {
              title: 'Latest Report',
              rows: [
                {
                  label: 'File',
                  value:
                    latestLabReport?.['fileName']?.toString() ??
                    'No lab report available',
                },
                {
                  label: 'Status',
                  value:
                    latestLabReport?.['status']?.toString() ?? 'Pending upload',
                },
              ],
            },
          ],
          footer: this.buildFooter(basePatient['patientId']?.toString()),
          verification: this.buildVerification(basePatient['patientId']?.toString()),
        },
      },
    };
  }

  private buildHeader(input: {
    businessName: string;
    branchName: string;
    generatedBy: string;
  }) {
    return {
      title: 'SHIELD',
      logo: 'SHIELD',
      businessInformation: input.businessName,
      branchInformation: input.branchName,
      generatedDate: new Date().toISOString(),
      generatedBy: input.generatedBy,
    };
  }

  private buildFooter(referenceId?: string) {
    return {
      text: 'Generated by the SHIELD shared print engine.',
      referenceId: referenceId ?? '',
    };
  }

  private buildVerification(referenceId?: string) {
    return {
      qrCode: referenceId ?? '',
      digitalVerification: referenceId
        ? `Verification ID: ${referenceId}`
        : 'Verification pending',
    };
  }

  private renderTemplateLines(
    template: PrintTemplateMetadata,
    payload: PrintPayload,
  ) {
    const lines: string[] = [];
    const header = payload.header ?? {};
    const patient = payload.patient ?? {};
    const provider = payload.provider ?? {};
    const summary = payload.summary ?? {};
    const verification = payload.verification ?? {};
    const footer = payload.footer ?? {};

    lines.push(payload.documentTitle?.trim() || template.title);
    lines.push('SHIELD Shared Print Engine');
    lines.push('');
    lines.push(
      `Business: ${header['businessInformation']?.toString() || 'SHIELD'}`,
    );
    lines.push(
      `Branch: ${header['branchInformation']?.toString() || 'Primary Branch'}`,
    );
    lines.push(
      `Generated: ${header['generatedDate']?.toString() || new Date().toISOString()}`,
    );
    lines.push(
      `Generated By: ${header['generatedBy']?.toString() || 'SHIELD Team'}`,
    );
    lines.push('');

    if (Object.keys(patient).length > 0) {
      lines.push('Patient Information');
      lines.push(
        `Name: ${patient['name']?.toString() || 'Not recorded'}`,
      );
      if (patient['patientId']) {
        lines.push(`Patient ID: ${patient['patientId']}`);
      }
      if (patient['membershipNumber']) {
        lines.push(`Membership: ${patient['membershipNumber']}`);
      }
      if (patient['mobile']) {
        lines.push(`Mobile: ${patient['mobile']}`);
      }
      lines.push('');
    }

    if (Object.keys(provider).length > 0) {
      lines.push('Provider Information');
      lines.push(`Name: ${provider['name']?.toString() || 'Provider'}`);
      if (provider['role']) {
        lines.push(`Role: ${provider['role']}`);
      }
      if (provider['department']) {
        lines.push(`Department: ${provider['department']}`);
      }
      lines.push('');
    }

    if (Object.keys(summary).length > 0) {
      lines.push('Summary');
      for (const [key, value] of Object.entries(summary)) {
        lines.push(`${this.humanizeKey(key)}: ${this.normalizeValue(value)}`);
      }
      lines.push('');
    }

    for (const section of payload.sections ?? []) {
      lines.push(section.title);
      for (const row of section.rows) {
        lines.push(`${row.label}: ${row.value}`);
      }
      lines.push('');
    }

    if (verification['digitalVerification']) {
      lines.push(
        `Digital Verification: ${verification['digitalVerification']}`,
      );
    }
    if (verification['qrCode']) {
      lines.push(`QR Code Reference: ${verification['qrCode']}`);
    }
    if (footer['text']) {
      lines.push('');
      lines.push(footer['text'].toString());
    }

    return lines;
  }

  private buildSimplePdf(lines: string[]) {
    const sanitized = lines.map((line) =>
      line
        .replace(/\\/g, '\\\\')
        .replace(/\(/g, '\\(')
        .replace(/\)/g, '\\)')
        .slice(0, 110),
    );

    let y = 780;
    const content: string[] = ['BT', '/F1 10 Tf'];
    for (const line of sanitized) {
      content.push(`36 ${y} Td (${line || ' '}) Tj`);
      y -= 14;
      if (y < 40) {
        break;
      }
    }
    content.push('ET');
    const stream = content.join('\n');
    const objects = [
      '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj',
      '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj',
      '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj',
      '4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj',
      `5 0 obj << /Length ${Buffer.byteLength(stream, 'utf8')} >> stream\n${stream}\nendstream endobj`,
    ];

    const parts = ['%PDF-1.4\n'];
    const offsets: number[] = [0];
    let cursor = Buffer.byteLength(parts[0], 'utf8');

    for (const object of objects) {
      offsets.push(cursor);
      const chunk = `${object}\n`;
      parts.push(chunk);
      cursor += Buffer.byteLength(chunk, 'utf8');
    }

    const xrefStart = cursor;
    const xrefEntries = ['0000000000 65535 f '];
    for (let index = 1; index < offsets.length; index += 1) {
      xrefEntries.push(`${offsets[index].toString().padStart(10, '0')} 00000 n `);
    }

    parts.push(`xref\n0 ${offsets.length}\n${xrefEntries.join('\n')}\n`);
    parts.push(
      `trailer << /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF`,
    );

    return Buffer.from(parts.join(''), 'utf8');
  }

  private humanizeKey(key: string) {
    return key
      .replace(/([a-z])([A-Z])/g, '$1 $2')
      .replace(/_/g, ' ')
      .replace(/\b\w/g, (character) => character.toUpperCase());
  }

  private normalizeValue(value: unknown) {
    const text = `${value ?? ''}`.trim();
    return text.length > 0 ? text : 'Not recorded';
  }
}
