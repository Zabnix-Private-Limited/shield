import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class DocumentService {
  constructor(private prisma: PrismaService) {}

  async upload(data: {
    customerId: bigint;
    fileName: string;
    fileSize: number;
    mimeType: string;
    documentType: string;
    uploadedBy?: bigint;
  }) {
    const docUuid = randomUUID();
    // Simulate Cloudflare R2 public URL
    const storagePath = `https://pub-r2.shield.sahakar.com/documents/customer-${data.customerId}/${docUuid}_${data.fileName}`;

    return this.prisma.document.create({
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
  }

  async list(customerId?: bigint) {
    const whereClause: any = {
      NOT: { status: 'DELETED' },
    };
    if (customerId) {
      whereClause.customerId = customerId;
    }
    return this.prisma.document.findMany({
      where: whereClause,
      include: {
        customer: true,
        uploadedByUser: true,
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

  async softDelete(id: bigint) {
    const doc = await this.findOne(id);
    return this.prisma.document.update({
      where: { id: doc.id },
      data: { status: 'DELETED' },
    });
  }

  async classify(documentId: bigint) {
    const doc = await this.findOne(documentId);
    const mockClassifications = ['PRESCRIPTION', 'LAB_REPORT', 'PHARMACY_BILL', 'INVOICE', 'DENTAL_REPORT'];
    const classification = mockClassifications[Number(doc.id % BigInt(mockClassifications.length))];

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

  async extract(documentId: bigint) {
    const doc = await this.findOne(documentId);
    const mockText = `--- SHIELD EXTRACTED HEALTH RECORD ---
Date: ${new Date().toLocaleDateString()}
Patient ID: CUST-123456
Diagnosis Summary: LifeStyle Management & Follow-up
Prescribed Items: Paracetamol 650mg, Metformin 500mg, Atorvastatin 10mg
Lab Results: HbA1c 6.4%, BP 130/80 mmHg`;

    await this.prisma.documentExtraction.create({
      data: {
        documentId: doc.id,
        extractedText: mockText,
        confidenceScore: 94.8,
        extractionStatus: 'SUCCESS',
      },
    });

    await this.prisma.documentProcessingLog.create({
      data: {
        documentId: doc.id,
        stage: 'EXTRACTION',
        status: 'SUCCESS',
        remarks: 'Selectable text OCR extraction completed.',
        processedAt: new Date(),
      },
    });

    return this.prisma.document.update({
      where: { id: doc.id },
      data: { status: 'EXTRACTED' },
    });
  }

  async validate(documentId: bigint, staffUserId: bigint, status: 'APPROVED' | 'VALIDATED' | 'REJECTED') {
    const doc = await this.findOne(documentId);

    await this.prisma.documentProcessingLog.create({
      data: {
        documentId: doc.id,
        stage: 'HUMAN_VALIDATION',
        status: 'SUCCESS',
        remarks: `Human validation completed by staff: ${status}`,
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
