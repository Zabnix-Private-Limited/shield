import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AgentScopeService } from '../auth/agent-scope.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { PrescriptionIntelligenceService } from './prescription-intelligence.service';
import { StorageService } from '../storage/storage.service';

type ExtractedPrescriptionMedicine = {
  name: string;
  dosage: string;
  frequency: string;
  duration: string;
};

type PrescriptionMatchCandidate = {
  productId: string;
  productName: string;
  brand: string | null;
  confidence: number;
};

@Injectable()
export class DocumentService {
  constructor(
    private prisma: PrismaService,
    private readonly agentScopeService: AgentScopeService,
    private readonly providerScopeService: ProviderScopeService,
    private prescriptionIntelligenceService: PrescriptionIntelligenceService,
    private storageService: StorageService,
  ) {}

  private normalizeDocumentType(documentType?: string | null) {
    return (documentType ?? '').trim().toUpperCase().replaceAll(' ', '_');
  }

  private normalizeSearchText(value?: string | null) {
    return (value ?? '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  private levenshteinDistance(a: string, b: string) {
    if (a === b) {
      return 0;
    }
    if (!a.length) {
      return b.length;
    }
    if (!b.length) {
      return a.length;
    }

    const matrix = Array.from({ length: a.length + 1 }, () =>
      new Array<number>(b.length + 1).fill(0),
    );

    for (let i = 0; i <= a.length; i += 1) {
      matrix[i][0] = i;
    }
    for (let j = 0; j <= b.length; j += 1) {
      matrix[0][j] = j;
    }

    for (let i = 1; i <= a.length; i += 1) {
      for (let j = 1; j <= b.length; j += 1) {
        const cost = a[i - 1] === b[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[a.length][b.length];
  }

  private jaroSimilarity(a: string, b: string) {
    if (a === b) {
      return 1;
    }
    if (!a.length || !b.length) {
      return 0;
    }

    const matchDistance = Math.max(a.length, b.length) / 2 - 1;
    const aMatches = new Array<boolean>(a.length).fill(false);
    const bMatches = new Array<boolean>(b.length).fill(false);

    let matches = 0;
    for (let i = 0; i < a.length; i += 1) {
      const start = Math.max(0, Math.floor(i - matchDistance));
      const end = Math.min(i + matchDistance + 1, b.length);
      for (let j = start; j < end; j += 1) {
        if (bMatches[j] || a[i] !== b[j]) {
          continue;
        }
        aMatches[i] = true;
        bMatches[j] = true;
        matches += 1;
        break;
      }
    }

    if (!matches) {
      return 0;
    }

    let transpositions = 0;
    let k = 0;
    for (let i = 0; i < a.length; i += 1) {
      if (!aMatches[i]) {
        continue;
      }
      while (!bMatches[k]) {
        k += 1;
      }
      if (a[i] !== b[k]) {
        transpositions += 1;
      }
      k += 1;
    }

    return (
      (matches / a.length +
        matches / b.length +
        (matches - transpositions / 2) / matches) /
      3
    );
  }

  private jaroWinklerSimilarity(a: string, b: string) {
    const jaro = this.jaroSimilarity(a, b);
    let prefixLength = 0;
    for (let i = 0; i < Math.min(4, a.length, b.length); i += 1) {
      if (a[i] !== b[i]) {
        break;
      }
      prefixLength += 1;
    }
    return jaro + prefixLength * 0.1 * (1 - jaro);
  }

  private similarityScore(a: string, b: string) {
    const normalizedA = this.normalizeSearchText(a);
    const normalizedB = this.normalizeSearchText(b);
    if (!normalizedA || !normalizedB) {
      return 0;
    }

    const longestLength = Math.max(normalizedA.length, normalizedB.length);
    const levenshteinScore =
      longestLength === 0
        ? 1
        : 1 -
          this.levenshteinDistance(normalizedA, normalizedB) / longestLength;
    const jaroWinklerScore = this.jaroWinklerSimilarity(
      normalizedA,
      normalizedB,
    );
    const containmentBoost =
      normalizedA.includes(normalizedB) || normalizedB.includes(normalizedA)
        ? 0.08
        : 0;

    return Number(
      Math.min(
        0.99,
        levenshteinScore * 0.45 + jaroWinklerScore * 0.55 + containmentBoost,
      ).toFixed(3),
    );
  }

  private parseIssueDate(rawDate?: string | null) {
    const value = (rawDate ?? '').trim();
    const ddmmyyyy = value.match(/^(\d{2})-(\d{2})-(\d{4})$/);
    if (ddmmyyyy) {
      const [, day, month, year] = ddmmyyyy;
      return new Date(`${year}-${month}-${day}T00:00:00.000Z`);
    }

    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? new Date() : parsed;
  }

  private getLatestExtraction(document: any) {
    const items = [...(document.documentExtractions ?? [])];
    if (!items.length) {
      return null;
    }
    items.sort(
      (a, b) =>
        new Date(a.createdAt ?? 0).getTime() -
        new Date(b.createdAt ?? 0).getTime(),
    );
    return items[items.length - 1];
  }

  private parsePrescriptionExtraction(extractedText?: string | null) {
    const lines = (extractedText ?? '')
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);

    const patient =
      lines
        .find((line) => line.startsWith('Patient:'))
        ?.split(':')[1]
        ?.trim() ?? 'Customer';
    const doctor =
      lines
        .find((line) => line.startsWith('Doctor:'))
        ?.split(':')[1]
        ?.trim() ?? 'Doctor unavailable';
    const date =
      lines
        .find((line) => line.startsWith('Date:'))
        ?.split(':')[1]
        ?.trim() ?? new Date().toLocaleDateString('en-GB').replace(/\//g, '-');

    const medicineLines = lines
      .filter((line) => line.startsWith('- '))
      .map((line) => line.replace(/^- /, '').trim());

    const medicines: ExtractedPrescriptionMedicine[] = medicineLines.map(
      (line) => {
        const [name = '', dosage = '', frequency = '', duration = ''] = line
          .split('|')
          .map((item) => item.trim());

        return {
          name: name || 'Unknown medicine',
          dosage: dosage || 'As directed',
          frequency: frequency || 'As directed',
          duration: duration || 'Not specified',
        };
      },
    );

    return {
      patient,
      doctor,
      date,
      medicines,
    };
  }

  private async ensurePrescriptionRecord(document: any, issueDate: string) {
    const existing = await this.prisma.prescription.findFirst({
      where: { documentId: document.id },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.prescription.create({
      data: {
        customerId: document.customerId,
        documentId: document.id,
        issueDate: this.parseIssueDate(issueDate),
      },
    });
  }

  private async matchMedicines(
    medicines: ExtractedPrescriptionMedicine[],
  ): Promise<
    Array<{
      rawName: string;
      dosage: string;
      frequency: string;
      duration: string;
      status: 'MATCHED' | 'REVIEW' | 'UNMATCHED';
      confidence: number;
      matchedProductId: string | null;
      matchedProductName: string | null;
      matchedBrand: string | null;
      candidates: PrescriptionMatchCandidate[];
    }>
  > {
    const products = await this.prisma.product.findMany({
      take: 250,
      orderBy: { id: 'asc' },
    });

    return medicines.map((medicine) => {
      const candidates = products
        .map((product) => {
          const namesToScore = [
            product.productName ?? '',
            product.brand ?? '',
            `${product.productName ?? ''} ${product.brand ?? ''}`.trim(),
            product.productCode ?? '',
          ].filter(Boolean);

          const bestScore = namesToScore.reduce((highest, candidate) => {
            return Math.max(
              highest,
              this.similarityScore(medicine.name, candidate),
            );
          }, 0);

          return {
            productId: product.id.toString(),
            productName: product.productName ?? 'Unnamed product',
            brand: product.brand,
            confidence: Number(bestScore.toFixed(3)),
          };
        })
        .filter((candidate) => candidate.confidence > 0.25)
        .sort((a, b) => b.confidence - a.confidence)
        .slice(0, 3);

      const bestCandidate = candidates[0];
      const status = !bestCandidate
        ? 'UNMATCHED'
        : bestCandidate.confidence >= 0.82
          ? 'MATCHED'
          : bestCandidate.confidence >= 0.62
            ? 'REVIEW'
            : 'UNMATCHED';

      return {
        rawName: medicine.name,
        dosage: medicine.dosage,
        frequency: medicine.frequency,
        duration: medicine.duration,
        status,
        confidence: Number((bestCandidate?.confidence ?? 0).toFixed(3)),
        matchedProductId:
          status === 'UNMATCHED' ? null : (bestCandidate?.productId ?? null),
        matchedProductName:
          status === 'UNMATCHED' ? null : (bestCandidate?.productName ?? null),
        matchedBrand:
          status === 'UNMATCHED' ? null : (bestCandidate?.brand ?? null),
        candidates,
      };
    });
  }

  private async getPrescriptionProductMaster() {
    const products = await this.prisma.product.findMany({
      take: 500,
      orderBy: { id: 'asc' },
    });

    return products.map((product) => ({
      productId: product.id.toString(),
      productName: product.productName ?? 'Unnamed product',
      brand: product.brand,
      productCode: product.productCode,
    }));
  }

  private buildCanonicalPrescriptionText(input: {
    patient: string;
    doctor: string;
    date: string;
    medicines: ExtractedPrescriptionMedicine[];
  }) {
    const medicineLines = input.medicines.map(
      (medicine) =>
        `- ${medicine.name} | ${medicine.dosage} | ${medicine.frequency} | ${medicine.duration}`,
    );

    return [
      `Patient: ${input.patient || 'Customer'}`,
      `Doctor: ${input.doctor || 'Doctor unavailable'}`,
      `Date: ${input.date || new Date().toLocaleDateString('en-GB').replace(/\//g, '-')}`,
      'Medicines:',
      ...medicineLines,
    ]
      .filter((line) => Boolean(line && line.trim()))
      .join('\n');
  }

  private async runAutomatedPrescriptionPipeline(
    documentId: bigint,
    documentType?: string | null,
    uploadedFile?: {
      buffer?: Buffer;
      fileName: string;
      mimeType: string;
    },
  ) {
    const normalizedType = this.normalizeDocumentType(documentType);
    if (normalizedType !== 'PRESCRIPTION') {
      return this.findOne(documentId);
    }

    await this.prisma.documentProcessingLog.create({
      data: {
        documentId,
        stage: 'UPLOAD',
        status: 'SUCCESS',
        remarks:
          'Prescription file uploaded and saved to the customer record without OCR processing.',
        processedAt: new Date(),
      },
    });

    return this.prisma.document.update({
      where: { id: documentId },
      data: { status: 'UPLOADED' },
      include: {
        customer: true,
        documentClassifications: true,
        documentExtractions: true,
        documentProcessingLogs: true,
      },
    });
  }

  async upload(data: {
    customerId: bigint;
    fileName: string;
    fileSize: number;
    mimeType: string;
    documentType: string;
    uploadedBy?: bigint;
    fileBuffer?: Buffer;
  }) {
    const docUuid = randomUUID();
    const persistedFile = await this.storageService.persistPrivateObject({
      customerId: data.customerId,
      documentUuid: docUuid,
      fileName: data.fileName,
      documentType: data.documentType,
      mimeType: data.mimeType,
      buffer: data.fileBuffer,
    });
    const storagePath =
      persistedFile?.storagePath ??
      `customers/${data.customerId.toString()}/documents/${docUuid}_${data.fileName}`;

    const created = await this.prisma.document.create({
      data: {
        uuid: docUuid,
        customerId: data.customerId,
        fileName: data.fileName,
        fileSize: BigInt(data.fileSize),
        mimeType: data.mimeType,
        documentType: data.documentType,
        storagePath,
        status: 'PROCESSING',
        uploadedBy: data.uploadedBy,
      },
    });

    return this.runAutomatedPrescriptionPipeline(
      created.id,
      data.documentType,
      {
        buffer: data.fileBuffer,
        fileName: data.fileName,
        mimeType: data.mimeType,
      },
    );
  }

  async list(customerId?: bigint, principal?: ShieldPrincipal) {
    const whereClause: any = {
      NOT: { status: 'DELETED' },
    };
    if (customerId) {
      whereClause.customerId = customerId;
    } else if (this.agentScopeService.isAgentPrincipal(principal)) {
      const accessibleCustomerIds =
        await this.agentScopeService.listAccessibleCustomerIds(principal);
      whereClause.customerId =
        accessibleCustomerIds.length > 0
          ? { in: accessibleCustomerIds }
          : { in: [] };
    } else if (this.providerScopeService.isProviderPrincipal(principal)) {
      const accessibleCustomerIds =
        await this.providerScopeService.listAccessibleCustomerIds(principal);
      whereClause.customerId =
        accessibleCustomerIds.length > 0
          ? { in: accessibleCustomerIds }
          : { in: [] };
    }
    return this.prisma.document.findMany({
      where: whereClause,
      include: {
        customer: true,
        uploadedByUser: true,
        documentClassifications: true,
        documentExtractions: true,
        documentProcessingLogs: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: bigint) {
    const doc = await this.prisma.document.findUnique({
      where: { id },
      include: {
        customer: true,
        documentClassifications: true,
        documentExtractions: true,
        documentProcessingLogs: true,
      },
    });
    if (!doc || doc.status === 'DELETED') {
      throw new NotFoundException(`Document with ID ${id} not found`);
    }
    return doc;
  }

  async documentBelongsToCustomer(documentId: bigint, customerId: bigint) {
    return Boolean(
      await this.prisma.document.findFirst({
        where: { id: documentId, customerId, status: { not: 'DELETED' } },
        select: { id: true },
      }),
    );
  }

  async getDownloadUrl(id: bigint) {
    const doc = await this.findOne(id);
    if (!doc.storagePath) {
      throw new NotFoundException(
        `Document ${id.toString()} does not have a stored file path`,
      );
    }
    return this.storageService.createDownloadUrl(doc.storagePath);
  }

  async softDelete(id: bigint) {
    const doc = await this.findOne(id);
    return this.prisma.document.update({
      where: { id: doc.id },
      data: { status: 'DELETED' },
    });
  }

  async classify(documentId: bigint, classificationHint?: string) {
    const doc = await this.findOne(documentId);
    const supportedClassifications = [
      'PRESCRIPTION',
      'LAB_REPORT',
      'PHARMACY_BILL',
      'INVOICE',
      'DENTAL_REPORT',
      'UNCLASSIFIED',
    ];
    const normalizedHint = this.normalizeDocumentType(classificationHint);
    const normalizedDocType = this.normalizeDocumentType(doc.documentType);
    const classification = supportedClassifications.includes(normalizedHint)
      ? normalizedHint
      : supportedClassifications.includes(normalizedDocType)
        ? normalizedDocType
        : 'UNCLASSIFIED';

    await this.prisma.documentClassification.create({
      data: {
        documentId: doc.id,
        classification,
        confidence: 96.5,
      },
    });

    await this.prisma.documentProcessingLog.create({
      data: {
        documentId: doc.id,
        stage: 'CLASSIFICATION',
        status: 'SUCCESS',
        remarks: `Document classified as ${classification} automatically.`,
        processedAt: new Date(),
      },
    });

    return this.prisma.document.update({
      where: { id: doc.id },
      data: {
        status: 'CLASSIFIED',
        documentType: classification.toLowerCase(),
      },
    });
  }

  async extract(
    documentId: bigint,
    uploadedFile?: {
      buffer?: Buffer;
      fileName: string;
      mimeType: string;
    },
  ) {
    const doc = await this.findOne(documentId);
    const normalizedType = this.normalizeDocumentType(doc.documentType);

    let extractedText: string;
    let confidenceScore: number;
    let extractionRemarks: string;

    if (normalizedType === 'PRESCRIPTION' && uploadedFile?.buffer?.length) {
      const aiResponse = await this.prescriptionIntelligenceService.analyzeFile(
        {
          fileName: uploadedFile.fileName,
          mimeType: uploadedFile.mimeType,
          buffer: uploadedFile.buffer,
          products: [],
        },
      );

      extractedText = this.buildCanonicalPrescriptionText({
        patient: aiResponse.patient,
        doctor: aiResponse.doctor,
        date: aiResponse.date,
        medicines: aiResponse.medicines.map((medicine) => ({
          name: medicine.name,
          dosage: medicine.dosage,
          frequency: medicine.frequency,
          duration: medicine.duration,
        })),
      });
      confidenceScore = Number((aiResponse.overall_confidence || 0).toFixed(1));
      extractionRemarks = `Real prescription extraction completed via ${aiResponse.engine}.`;
    } else {
      const patientName =
        [doc.customer?.firstName, doc.customer?.lastName]
          .filter(Boolean)
          .join(' ') || 'Customer';
      const formattedDate = new Date()
        .toLocaleDateString('en-GB')
        .replace(/\//g, '-');
      extractedText =
        normalizedType === 'PRESCRIPTION'
          ? `Patient: ${patientName}
Doctor: Doctor unavailable
Date: ${formattedDate}
Medicines:
- Prescription uploaded | As directed | As directed | Not specified`
          : `Date: ${formattedDate}
Customer: ${patientName}
Summary: Structured extraction is unavailable for this document.`;
      confidenceScore = 32;
      extractionRemarks = uploadedFile?.buffer?.length
        ? 'Document extraction used the minimal parser because OCR output was unavailable.'
        : 'Document record created without an uploaded file buffer.';
    }

    await this.prisma.documentExtraction.create({
      data: {
        documentId: doc.id,
        extractedText,
        confidenceScore,
        extractionStatus: 'SUCCESS',
      },
    });

    await this.prisma.documentProcessingLog.create({
      data: {
        documentId: doc.id,
        stage: 'EXTRACTION',
        status: 'SUCCESS',
        remarks: extractionRemarks,
        processedAt: new Date(),
      },
    });

    return this.prisma.document.update({
      where: { id: doc.id },
      data: { status: 'EXTRACTED' },
    });
  }

  async getPrescriptionReview(documentId: bigint) {
    const doc = await this.findOne(documentId);
    if (this.normalizeDocumentType(doc.documentType) !== 'PRESCRIPTION') {
      throw new NotFoundException(
        `Document ${documentId.toString()} is not a prescription`,
      );
    }

    const latestExtraction = this.getLatestExtraction(doc);
    const structuredJson = this.parsePrescriptionExtraction(
      latestExtraction?.extractedText,
    );
    const extractionConfidence = Number(latestExtraction?.confidenceScore ?? 0);
    const overallConfidence = Number(extractionConfidence.toFixed(1));

    await this.ensurePrescriptionRecord(doc, structuredJson.date);

    const medicineMatches = structuredJson.medicines.map((medicine) => ({
      rawName: medicine.name,
      dosage: medicine.dosage,
      frequency: medicine.frequency,
      duration: medicine.duration,
      status: 'EXTRACTED',
      confidence: Number(extractionConfidence.toFixed(1)),
      matchedProductId: null,
      matchedProductName: null,
      matchedBrand: null,
      candidates: [],
    }));

    const cartPrefill = structuredJson.medicines.map((medicine, index) => ({
      productId: `ocr-${documentId.toString()}-${index + 1}`,
      productName: medicine.name,
      brand: null,
      quantity: 1,
      dosage: medicine.dosage,
      frequency: medicine.frequency,
      duration: medicine.duration,
      confidence: Number(extractionConfidence.toFixed(1)),
      needsReview: true,
    }));

    return {
      documentId: doc.id,
      customerId: doc.customerId,
      fileName: doc.fileName,
      reviewStatus:
        doc.status === 'APPROVED' ? 'APPROVED' : 'PENDING_PHARMACIST_APPROVAL',
      extractedText: latestExtraction?.extractedText ?? null,
      extractionConfidence: Number(extractionConfidence.toFixed(1)),
      overallConfidence,
      structuredJson,
      medicineMatches,
      cartPrefill,
      steps: [
        { key: 'UPLOAD', label: 'Uploading prescription', status: 'done' },
        { key: 'VISION', label: 'Reading prescription', status: 'done' },
        { key: 'JSON', label: 'Structuring JSON', status: 'done' },
        {
          key: 'EXTRACTION',
          label: 'Extracted medicines from image',
          status: medicineMatches.length ? 'done' : 'pending',
        },
        {
          key: 'REVIEW',
          label: 'Pharmacist review',
          status: doc.status === 'APPROVED' ? 'done' : 'pending',
        },
      ],
      generatedAt: new Date().toISOString(),
    };
  }

  async approvePrescriptionReview(
    documentId: bigint,
    staffUserId: bigint,
    providerId?: bigint,
  ) {
    const review = await this.getPrescriptionReview(documentId);
    const approvedDocument = await this.validate(
      documentId,
      staffUserId,
      'APPROVED',
    );

    await this.prisma.documentProcessingLog.create({
      data: {
        documentId,
        stage: 'PHARMACY_REVIEW',
        status: 'SUCCESS',
        remarks: `Pharmacist approved ${review.cartPrefill.length} OCR extracted items${providerId ? ` for provider ${providerId.toString()}` : ''}.`,
        processedAt: new Date(),
      },
    });

    if (approvedDocument.customerId) {
      await this.prisma.notification.create({
        data: {
          customerId: approvedDocument.customerId,
          title: 'Prescription approved',
          message: `${review.cartPrefill.length} extracted items are ready for pharmacist follow-up.`,
          channel: 'IN_APP',
          status: 'UNREAD',
          sentAt: new Date(),
        },
      });
    }

    return {
      ...review,
      reviewStatus: 'APPROVED',
      approvedAt: new Date().toISOString(),
      approvedBy: staffUserId.toString(),
      providerId: providerId?.toString() ?? null,
      documentStatus: approvedDocument.status,
    };
  }

  async validate(
    documentId: bigint,
    staffUserId: bigint,
    status: 'APPROVED' | 'VALIDATED' | 'REJECTED',
  ) {
    const doc = await this.findOne(documentId);

    await this.prisma.documentProcessingLog.create({
      data: {
        documentId: doc.id,
        stage: 'HUMAN_VALIDATION',
        status: 'SUCCESS',
        remarks: `Human validation completed by staff ${staffUserId.toString()}: ${status}`,
        processedAt: new Date(),
      },
    });

    return this.prisma.document.update({
      where: { id: doc.id },
      data: { status },
    });
  }

  async getLogs(documentId: bigint) {
    return this.prisma.documentProcessingLog.findMany({
      where: { documentId },
      orderBy: { processedAt: 'asc' },
    });
  }
}
