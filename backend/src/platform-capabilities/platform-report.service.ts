import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PlatformPrintService } from './platform-print.service';

type ReportMetadata = {
  id: string;
  title: string;
  workspace: string;
  description: string;
  supportedPortals: string[];
  availableFormats: Array<'PDF' | 'EXCEL' | 'CSV'>;
  filters: string[];
};

type ReportFilters = {
  workspace?: string;
  providerId?: bigint;
  businessId?: bigint;
  dateFrom?: string;
  dateTo?: string;
  status?: string;
  search?: string;
};

@Injectable()
export class PlatformReportService {
  private readonly registry: ReportMetadata[] = [
    {
      id: 'PROVIDER_TODAYS_CONSULTATIONS',
      title: "Today's Consultations",
      workspace: 'provider',
      description: 'Today’s appointment and consultation workload.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider', 'status', 'search'],
    },
    {
      id: 'PROVIDER_DAILY_REVENUE',
      title: 'Daily Revenue',
      workspace: 'provider',
      description: 'Daily billed and payable totals from provider invoices.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_MONTHLY_REVENUE',
      title: 'Monthly Revenue',
      workspace: 'provider',
      description: 'Month-wise revenue from provider invoices.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_APPOINTMENTS',
      title: 'Appointments',
      workspace: 'provider',
      description: 'Appointment volume and status details.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider', 'status', 'search'],
    },
    {
      id: 'PROVIDER_COMPLETED_VISITS',
      title: 'Completed Visits',
      workspace: 'provider',
      description: 'Completed provider visits in the requested range.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_CANCELLED_VISITS',
      title: 'Cancelled Visits',
      workspace: 'provider',
      description: 'Cancelled provider visits in the requested range.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_PENDING_VISITS',
      title: 'Pending Visits',
      workspace: 'provider',
      description: 'Pending and confirmed visits that still need work.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_WALLET_USAGE',
      title: 'Wallet Usage',
      workspace: 'provider',
      description: 'Wallet-applied spend and payment coverage on provider invoices.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_DOCUMENT_STATISTICS',
      title: 'Document Statistics',
      workspace: 'provider',
      description: 'Document counts by type and status for provider-linked patients.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_PRESCRIPTION_STATISTICS',
      title: 'Prescription Statistics',
      workspace: 'provider',
      description: 'Prescription counts from consultation-linked visits.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_SERVICE_UTILIZATION',
      title: 'Service Utilization',
      workspace: 'provider',
      description: 'Visit and invoice volume by service type.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'PROVIDER_PERFORMANCE',
      title: 'Provider Performance',
      workspace: 'provider',
      description: 'Top-level performance summary for the active provider scope.',
      supportedPortals: ['provider', 'manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch', 'provider'],
    },
    {
      id: 'BRANCH_PERFORMANCE',
      title: 'Branch Performance',
      workspace: 'provider',
      description: 'Branch-level performance for provider business scope.',
      supportedPortals: ['manager', 'executive', 'super-admin'],
      availableFormats: ['PDF', 'EXCEL', 'CSV'],
      filters: ['dateRange', 'branch'],
    },
  ];

  constructor(
    private readonly prisma: PrismaService,
    private readonly platformPrintService: PlatformPrintService,
  ) {}

  listMetadata(workspace?: string) {
    const normalizedWorkspace = workspace?.trim().toLowerCase();
    const reports = normalizedWorkspace
      ? this.registry.filter((report) => report.workspace === normalizedWorkspace)
      : this.registry;

    return {
      title: 'Shared Reporting Engine',
      description:
        'One backend-owned report registry, builder, filter engine, and export layer.',
      filters: ['dateRange', 'branch', 'provider', 'department', 'business', 'membership', 'status', 'search'],
      exportFormats: ['PDF', 'EXCEL', 'CSV'],
      reports,
    };
  }

  async runReport(reportId: string, filters: ReportFilters, format: 'PDF' | 'EXCEL' | 'CSV') {
    const metadata =
      this.registry.find((report) => report.id === reportId.trim().toUpperCase()) ??
      null;
    if (metadata == null) {
      throw new Error(`Unknown report: ${reportId}`);
    }

    const result = await this.buildProviderReport(metadata, filters);
    const exportFile = this.exportReport(metadata, result, format);

    return {
      metadata,
      filters,
      generatedAt: new Date().toISOString(),
      ...result,
      exportFile,
    };
  }

  private async buildProviderReport(metadata: ReportMetadata, filters: ReportFilters) {
    const appointmentWhere = this.buildAppointmentWhere(filters);
    const purchaseWhere = this.buildPurchaseWhere(filters);
    const providerPatientIds = await this.resolveProviderPatientIds(filters);

    switch (metadata.id) {
      case 'PROVIDER_TODAYS_CONSULTATIONS': {
        const now = new Date();
        const start = new Date(now);
        start.setHours(0, 0, 0, 0);
        const end = new Date(now);
        end.setHours(23, 59, 59, 999);
        const rows = await this.prisma.appointment.findMany({
          where: {
            ...appointmentWhere,
            appointmentDate: { gte: start, lte: end },
          },
          orderBy: [{ appointmentDate: 'asc' }, { id: 'asc' }],
          include: {
            customer: true,
            provider: true,
          },
        });

        return {
          columns: ['Appointment', 'Patient', 'Provider', 'Status', 'Date'],
          rows: rows.map((appointment) => ({
            Appointment: appointment.appointmentType ?? 'VISIT',
            Patient: this.toPersonLabel(appointment.customer?.firstName, appointment.customer?.lastName),
            Provider: appointment.provider?.providerName ?? 'Provider',
            Status: appointment.status ?? 'PENDING',
            Date: appointment.appointmentDate?.toISOString() ?? '',
          })),
          summary: {
            totalConsultations: rows.length,
          },
        };
      }
      case 'PROVIDER_DAILY_REVENUE':
      case 'PROVIDER_MONTHLY_REVENUE': {
        const purchases = await this.prisma.purchase.findMany({
          where: purchaseWhere,
          orderBy: [{ purchaseDate: 'asc' }, { id: 'asc' }],
        });
        const buckets = new Map<string, { billed: number; payable: number; invoices: number }>();
        for (const purchase of purchases) {
          const date = purchase.purchaseDate ?? new Date();
          const key =
            metadata.id === 'PROVIDER_MONTHLY_REVENUE'
              ? `${date.getUTCFullYear()}-${`${date.getUTCMonth() + 1}`.padStart(2, '0')}`
              : date.toISOString().slice(0, 10);
          const bucket = buckets.get(key) ?? { billed: 0, payable: 0, invoices: 0 };
          bucket.billed += Number(purchase.totalAmount ?? 0);
          bucket.payable += Number(purchase.payableAmount ?? 0);
          bucket.invoices += 1;
          buckets.set(key, bucket);
        }

        const rows = [...buckets.entries()].map(([period, value]) => ({
          Period: period,
          Invoices: value.invoices,
          Billed: value.billed.toFixed(2),
          Payable: value.payable.toFixed(2),
        }));

        return {
          columns: ['Period', 'Invoices', 'Billed', 'Payable'],
          rows,
          summary: {
            totalInvoices: purchases.length,
            totalPayable: purchases.reduce(
              (sum, purchase) => sum + Number(purchase.payableAmount ?? 0),
              0,
            ),
          },
        };
      }
      case 'PROVIDER_APPOINTMENTS':
      case 'PROVIDER_COMPLETED_VISITS':
      case 'PROVIDER_CANCELLED_VISITS':
      case 'PROVIDER_PENDING_VISITS': {
        const statusFilter =
          metadata.id === 'PROVIDER_COMPLETED_VISITS'
            ? ['COMPLETED']
            : metadata.id === 'PROVIDER_CANCELLED_VISITS'
              ? ['CANCELLED']
              : metadata.id === 'PROVIDER_PENDING_VISITS'
                ? ['PENDING', 'CONFIRMED', 'SCHEDULED']
                : filters.status?.trim()
                  ? [filters.status.trim().toUpperCase()]
                  : undefined;
        const rows = await this.prisma.appointment.findMany({
          where: {
            ...appointmentWhere,
            ...(statusFilter ? { status: { in: statusFilter } } : {}),
          },
          orderBy: [{ appointmentDate: 'desc' }, { id: 'desc' }],
          include: {
            customer: true,
            provider: true,
          },
        });
        return {
          columns: ['Appointment', 'Patient', 'Status', 'Date', 'Provider'],
          rows: rows.map((appointment) => ({
            Appointment: appointment.appointmentType ?? 'VISIT',
            Patient: this.toPersonLabel(appointment.customer?.firstName, appointment.customer?.lastName),
            Status: appointment.status ?? 'PENDING',
            Date: appointment.appointmentDate?.toISOString() ?? '',
            Provider: appointment.provider?.providerName ?? 'Provider',
          })),
          summary: {
            totalAppointments: rows.length,
          },
        };
      }
      case 'PROVIDER_WALLET_USAGE': {
        const purchases = await this.prisma.purchase.findMany({
          where: purchaseWhere,
          orderBy: [{ purchaseDate: 'desc' }, { id: 'desc' }],
        });
        const rows = purchases.map((purchase) => {
          const paymentSummary = this.parseJsonObject(purchase.paymentSummary);
          return {
            Invoice: purchase.invoiceNumber ?? `INV-${purchase.id.toString()}`,
            Date: purchase.purchaseDate?.toISOString() ?? '',
            WalletUsed: Number(paymentSummary['walletUsed'] ?? 0).toFixed(2),
            Cash: Number(paymentSummary['cash'] ?? 0).toFixed(2),
            Upi: Number(paymentSummary['upi'] ?? 0).toFixed(2),
            Card: Number(paymentSummary['card'] ?? 0).toFixed(2),
          };
        });
        return {
          columns: ['Invoice', 'Date', 'WalletUsed', 'Cash', 'Upi', 'Card'],
          rows,
          summary: {
            totalWalletUsed: rows.reduce(
              (sum, row) => sum + Number(row.WalletUsed),
              0,
            ),
          },
        };
      }
      case 'PROVIDER_DOCUMENT_STATISTICS': {
        const rows = await this.prisma.document.findMany({
          where: {
            ...(providerPatientIds.length > 0
              ? { customerId: { in: providerPatientIds } }
              : filters.providerId || filters.businessId
                ? { customerId: { in: [] } }
                : {}),
          },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        });
        const buckets = new Map<string, { total: number; approved: number }>();
        for (const document of rows) {
          const key = document.documentType ?? 'UNKNOWN';
          const bucket = buckets.get(key) ?? { total: 0, approved: 0 };
          bucket.total += 1;
          if ((document.status ?? '').toUpperCase().includes('APPRO')) {
            bucket.approved += 1;
          }
          buckets.set(key, bucket);
        }
        return {
          columns: ['DocumentType', 'Total', 'Approved'],
          rows: [...buckets.entries()].map(([type, value]) => ({
            DocumentType: type,
            Total: value.total,
            Approved: value.approved,
          })),
          summary: {
            totalDocuments: rows.length,
          },
        };
      }
      case 'PROVIDER_PRESCRIPTION_STATISTICS': {
        const rows = await this.prisma.prescription.findMany({
          where: {
            consultation: {
              appointment: appointmentWhere,
            },
          },
          include: {
            consultation: {
              include: {
                appointment: true,
              },
            },
          },
          orderBy: [{ issueDate: 'desc' }, { id: 'desc' }],
        });
        const buckets = new Map<string, number>();
        for (const prescription of rows) {
          const key = prescription.issueDate?.toISOString().slice(0, 10) ?? 'Undated';
          buckets.set(key, (buckets.get(key) ?? 0) + 1);
        }
        return {
          columns: ['Date', 'Prescriptions'],
          rows: [...buckets.entries()].map(([date, total]) => ({
            Date: date,
            Prescriptions: total,
          })),
          summary: {
            totalPrescriptions: rows.length,
          },
        };
      }
      case 'PROVIDER_SERVICE_UTILIZATION': {
        const rows = await this.prisma.appointment.findMany({
          where: appointmentWhere,
          select: {
            appointmentType: true,
          },
        });
        const buckets = new Map<string, number>();
        for (const appointment of rows) {
          const key = appointment.appointmentType ?? 'VISIT';
          buckets.set(key, (buckets.get(key) ?? 0) + 1);
        }
        return {
          columns: ['ServiceType', 'Visits'],
          rows: [...buckets.entries()].map(([serviceType, visits]) => ({
            ServiceType: serviceType,
            Visits: visits,
          })),
          summary: {
            totalVisits: rows.length,
          },
        };
      }
      case 'PROVIDER_PERFORMANCE':
      case 'BRANCH_PERFORMANCE': {
        const [appointments, purchases] = await Promise.all([
          this.prisma.appointment.findMany({ where: appointmentWhere }),
          this.prisma.purchase.findMany({ where: purchaseWhere }),
        ]);
        return {
          columns: ['Metric', 'Value'],
          rows: [
            { Metric: 'Appointments', Value: appointments.length },
            {
              Metric: 'Completed Visits',
              Value: appointments.filter(
                (appointment) =>
                  (appointment.status ?? '').toUpperCase() === 'COMPLETED',
              ).length,
            },
            { Metric: 'Invoices', Value: purchases.length },
            {
              Metric: 'Payable Amount',
              Value: purchases
                .reduce((sum, purchase) => sum + Number(purchase.payableAmount ?? 0), 0)
                .toFixed(2),
            },
          ],
          summary: {
            totalAppointments: appointments.length,
            totalInvoices: purchases.length,
          },
        };
      }
      default:
        return {
          columns: ['Status'],
          rows: [{ Status: 'Report builder not implemented' }],
          summary: {},
        };
    }
  }

  private exportReport(
    metadata: ReportMetadata,
    result: {
      columns: string[];
      rows: Array<Record<string, unknown>>;
      summary: Record<string, unknown>;
    },
    format: 'PDF' | 'EXCEL' | 'CSV',
  ) {
    const fileBaseName = metadata.id.toLowerCase().replace(/_/g, '-');

    if (format === 'CSV') {
      const csv = [
        result.columns.join(','),
        ...result.rows.map((row) =>
          result.columns
            .map((column) => `"${`${row[column] ?? ''}`.replace(/"/g, '""')}"`)
            .join(','),
        ),
      ].join('\n');
      return {
        fileName: `${fileBaseName}.csv`,
        mimeType: 'text/csv',
        format,
        contentBase64: Buffer.from(csv, 'utf8').toString('base64'),
      };
    }

    if (format === 'EXCEL') {
      const rowsXml = result.rows
        .map(
          (row) =>
            `<Row>${result.columns
              .map(
                (column) =>
                  `<Cell><Data ss:Type="String">${this.escapeXml(
                    `${row[column] ?? ''}`,
                  )}</Data></Cell>`,
              )
              .join('')}</Row>`,
        )
        .join('');
      const workbook = `<?xml version="1.0"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
 <Worksheet ss:Name="Report">
  <Table>
   <Row>${result.columns
     .map(
       (column) =>
         `<Cell><Data ss:Type="String">${this.escapeXml(column)}</Data></Cell>`,
     )
     .join('')}</Row>
   ${rowsXml}
  </Table>
 </Worksheet>
</Workbook>`;
      return {
        fileName: `${fileBaseName}.xls`,
        mimeType: 'application/vnd.ms-excel',
        format,
        contentBase64: Buffer.from(workbook, 'utf8').toString('base64'),
      };
    }

    const pdf = this.platformPrintService.generate('PATIENT_SUMMARY', {
      documentTitle: metadata.title,
      fileName: `${fileBaseName}.pdf`,
      header: {
        businessInformation: 'SHIELD',
        branchInformation: metadata.workspace,
        generatedDate: new Date().toISOString(),
        generatedBy: 'Shared Reporting Engine',
      },
      sections: [
        {
          title: 'Report Summary',
          rows: Object.entries(result.summary).map(([label, value]) => ({
            label,
            value: `${value ?? ''}`,
          })),
        },
        {
          title: 'Rows',
          rows: result.rows.slice(0, 20).map((row) => ({
            label: `${row[result.columns[0]] ?? 'Row'}`,
            value: result.columns
              .slice(1)
              .map((column) => `${column}: ${row[column] ?? ''}`)
              .join(' | '),
          })),
        },
      ],
    });

    return {
      fileName: pdf.fileName,
      mimeType: pdf.mimeType,
      format,
      contentBase64: pdf.contentBase64,
    };
  }

  private buildAppointmentWhere(filters: ReportFilters): Prisma.AppointmentWhereInput {
    const dateRange = this.buildDateRange(filters.dateFrom, filters.dateTo);
    return {
      ...(filters.providerId ? { providerId: filters.providerId } : {}),
      ...(filters.businessId
        ? {
            provider: {
              businessId: filters.businessId,
            },
          }
        : {}),
      ...(dateRange ? { appointmentDate: dateRange } : {}),
      ...(filters.search?.trim()
        ? {
            OR: [
              {
                customer: {
                  firstName: { contains: filters.search.trim(), mode: 'insensitive' },
                },
              },
              {
                customer: {
                  lastName: { contains: filters.search.trim(), mode: 'insensitive' },
                },
              },
            ],
          }
        : {}),
    };
  }

  private buildPurchaseWhere(filters: ReportFilters): Prisma.PurchaseWhereInput {
    const dateRange = this.buildDateRange(filters.dateFrom, filters.dateTo);
    return {
      ...(filters.providerId ? { providerId: filters.providerId } : {}),
      ...(filters.businessId
        ? {
            provider: {
              businessId: filters.businessId,
            },
          }
        : {}),
      ...(dateRange ? { purchaseDate: dateRange } : {}),
    };
  }

  private buildDateRange(dateFrom?: string, dateTo?: string) {
    const from = dateFrom?.trim() ? new Date(dateFrom.trim()) : undefined;
    const to = dateTo?.trim() ? new Date(dateTo.trim()) : undefined;
    if (!from && !to) {
      return undefined;
    }
    return {
      ...(from ? { gte: from } : {}),
      ...(to ? { lte: to } : {}),
    };
  }

  private async resolveProviderPatientIds(filters: ReportFilters) {
    const appointments = await this.prisma.appointment.findMany({
      where: this.buildAppointmentWhere(filters),
      select: { customerId: true },
      distinct: ['customerId'],
    });
    return appointments
      .map((appointment) => appointment.customerId)
      .filter((customerId): customerId is bigint => customerId != null);
  }

  private parseJsonObject(value: unknown) {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }
    if (typeof value === 'string' && value.trim()) {
      try {
        const parsed = JSON.parse(value);
        if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
          return parsed as Record<string, unknown>;
        }
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  private toPersonLabel(firstName?: string | null, lastName?: string | null) {
    const fullName = `${firstName ?? ''} ${lastName ?? ''}`.trim();
    return fullName.length > 0 ? fullName : 'SHIELD Member';
  }

  private escapeXml(value: string) {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}
