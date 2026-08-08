import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  BadRequestException,
  ForbiddenException,
  Query,
  HttpCode,
  UploadedFile,
  UseInterceptors,
  UnauthorizedException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AgentScopeService } from '../auth/agent-scope.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { DocumentService } from './document.service';

@Controller()
export class DocumentController {
  private static readonly customerDocumentTypes = new Set([
    'PRESCRIPTION',
    'LAB_REPORT',
    'DENTAL_RECORD',
    'DENTAL_REPORT',
    'INVOICE',
    'PHARMACY_BILL',
    'OTHER',
  ]);

  private static readonly acceptedFiles = new Map<string, string[]>([
    ['application/pdf', ['pdf']],
    ['image/jpeg', ['jpg', 'jpeg']],
    ['image/png', ['png']],
    ['image/webp', ['webp']],
  ]);

  constructor(
    private documentService: DocumentService,
    private readonly agentScopeService: AgentScopeService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  private async assertCustomerOwnDocument(
    documentId: bigint,
    principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType !== 'CUSTOMER') return;
    if (!principal.customerId) {
      throw new ForbiddenException(
        'Authenticated customer context is required.',
      );
    }
    if (
      !(await this.documentService.documentBelongsToCustomer(
        documentId,
        BigInt(principal.customerId),
      ))
    ) {
      throw new ForbiddenException(
        'Customers can only access their own documents.',
      );
    }
  }

  private customerSafeDocument<T>(value: T, principal?: ShieldPrincipal): T {
    if (principal?.principalType !== 'CUSTOMER' || !value) return value;
    if (Array.isArray(value)) {
      return value.map((item) =>
        this.customerSafeDocument(item, principal),
      ) as T;
    }
    const document = value as any;
    return {
      id: document.id,
      uuid: document.uuid,
      title: document.fileName ?? 'Document',
      fileName: document.fileName ?? 'Document',
      documentType: document.documentType ?? 'OTHER',
      status: document.status ?? 'UPLOADED',
      fileSize: document.fileSize ?? null,
      mimeType: document.mimeType ?? null,
      createdAt: document.createdAt ?? null,
    } as T;
  }

  private customerUploadMetadata(file: any, body: any) {
    if (!file?.buffer?.length || !file.originalname) {
      throw new BadRequestException('A document file is required.');
    }

    const fileName = String(file.originalname).trim();
    const extension = fileName.split('.').pop()?.toLowerCase() ?? '';
    const mimeType = String(file.mimetype ?? '').toLowerCase();
    const allowedExtensions = DocumentController.acceptedFiles.get(mimeType);
    if (
      !allowedExtensions ||
      !allowedExtensions.includes(extension) ||
      fileName.includes('/') ||
      fileName.includes('\\') ||
      fileName.includes('..')
    ) {
      throw new BadRequestException(
        'Only PDF, JPEG, PNG, and WebP document files are accepted.',
      );
    }

    const documentType = String(body.document_type ?? '')
      .trim()
      .toUpperCase();
    if (!DocumentController.customerDocumentTypes.has(documentType)) {
      throw new BadRequestException('Unsupported document category.');
    }

    return { fileName, mimeType, documentType };
  }

  private assertNotCustomerInternalProcessing(principal?: ShieldPrincipal) {
    if (principal?.principalType === 'CUSTOMER') {
      throw new ForbiddenException(
        'Document processing details are not available in the customer archive.',
      );
    }
  }

  @RequirePermissions('documents.create')
  @Post('documents/upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: multer.memoryStorage(),
      limits: { fileSize: 15 * 1024 * 1024 },
    }),
  )
  async upload(
    @UploadedFile() file: any,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const customerUpload = this.customerUploadMetadata(file, body);
    const uploaderId =
      principal?.userId != null
        ? BigInt(principal.userId)
        : body.uploaded_by
          ? BigInt(body.uploaded_by)
          : undefined;
    if (principal?.principalType === 'CUSTOMER') {
      if (!principal.customerId) {
        throw new ForbiddenException(
          'Authenticated customer context is required.',
        );
      }
      body.customer_id = principal.customerId;
    }
    await this.agentScopeService.assertAgentCanAccessCustomer(
      BigInt(body.customer_id),
      principal,
    );
    await this.providerScopeService.assertProviderCanAccessCustomer(
      BigInt(body.customer_id),
      principal,
    );
    const doc = await this.documentService.upload({
      customerId: BigInt(body.customer_id),
      fileName: customerUpload.fileName,
      fileSize: Number(file.size),
      mimeType: customerUpload.mimeType,
      documentType: customerUpload.documentType,
      uploadedBy: uploaderId,
      fileBuffer: file?.buffer,
    });
    return {
      success: true,
      message: 'Document uploaded successfully',
      data: this.customerSafeDocument(doc, principal),
    };
  }

  @RequirePermissions('documents.view')
  @Get('documents')
  async list(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType === 'CUSTOMER' && !principal.customerId) {
      throw new ForbiddenException(
        'Authenticated customer context is required.',
      );
    }
    const targetCustomerId =
      principal?.principalType === 'CUSTOMER'
        ? BigInt(principal.customerId!)
        : customerId
          ? BigInt(customerId)
          : undefined;
    if (targetCustomerId) {
      await this.agentScopeService.assertAgentCanAccessCustomer(
        targetCustomerId,
        principal,
      );
      await this.providerScopeService.assertProviderCanAccessCustomer(
        targetCustomerId,
        principal,
      );
    }
    const docs = await this.documentService.list(targetCustomerId, principal);
    return {
      success: true,
      message: 'Documents list retrieved',
      data: this.customerSafeDocument(docs, principal),
    };
  }

  @RequirePermissions('documents.view')
  @Get('documents/:id')
  async findOne(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.assertCustomerOwnDocument(BigInt(id), principal);
    await this.agentScopeService.assertAgentCanAccessDocument(
      BigInt(id),
      principal,
    );
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(id),
      principal,
    );
    const doc = await this.documentService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Document details retrieved',
      data: this.customerSafeDocument(doc, principal),
    };
  }

  @RequirePermissions('documents.view')
  @Get('documents/:id/download')
  async download(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.assertCustomerOwnDocument(BigInt(id), principal);
    await this.agentScopeService.assertAgentCanAccessDocument(
      BigInt(id),
      principal,
    );
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(id),
      principal,
    );
    const url = await this.documentService.getDownloadUrl(BigInt(id));
    return {
      success: true,
      message: 'Document download URL retrieved',
      data: {
        url,
      },
    };
  }

  @RequirePermissions('documents.delete')
  @Delete('documents/:id')
  @HttpCode(200)
  async softDelete(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.assertCustomerOwnDocument(BigInt(id), principal);
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(id),
      principal,
    );
    await this.documentService.softDelete(BigInt(id));
    return {
      success: true,
      message: 'Document soft-deleted successfully',
    };
  }

  @RequirePermissions('documents.approve')
  @Post('document-intelligence/classify')
  async classify(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(body.document_id),
      principal,
    );
    const doc = await this.documentService.classify(BigInt(body.document_id));
    return {
      success: true,
      message: 'Document intelligence classification complete',
      data: doc,
    };
  }

  @RequirePermissions('documents.view')
  @Post('document-intelligence/extract')
  async extract(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.assertCustomerOwnDocument(BigInt(body.document_id), principal);
    this.assertNotCustomerInternalProcessing(principal);
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(body.document_id),
      principal,
    );
    const doc = await this.documentService.extract(BigInt(body.document_id));
    return {
      success: true,
      message: 'Document intelligence text extraction complete',
      data: doc,
    };
  }

  @RequirePermissions('documents.view')
  @Post('document-intelligence/validate')
  async validate(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const staffId = body.staff_id
      ? BigInt(body.staff_id)
      : principal?.userId
        ? BigInt(principal.userId)
        : undefined;

    if (!staffId) {
      throw new UnauthorizedException('Authentication required');
    }
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(body.document_id),
      principal,
    );

    const doc = await this.documentService.validate(
      BigInt(body.document_id),
      staffId,
      body.status || 'APPROVED',
    );
    return {
      success: true,
      message: 'Document extraction validation saved',
      data: doc,
    };
  }

  @RequirePermissions('medical_records.view')
  @Get('document-intelligence/prescription-review/:documentId')
  async getPrescriptionReview(
    @Param('documentId') documentId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.assertCustomerOwnDocument(BigInt(documentId), principal);
    this.assertNotCustomerInternalProcessing(principal);
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(documentId),
      principal,
    );
    const review = await this.documentService.getPrescriptionReview(
      BigInt(documentId),
    );
    return {
      success: true,
      message: 'Prescription review summary retrieved',
      data: review,
    };
  }

  @RequirePermissions('medical_records.approve')
  @Post('document-intelligence/prescription-review/:documentId/approve')
  async approvePrescriptionReview(
    @Param('documentId') documentId: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const staffId = body.staff_id
      ? BigInt(body.staff_id)
      : principal?.userId
        ? BigInt(principal.userId)
        : undefined;

    if (!staffId) {
      throw new UnauthorizedException('Authentication required');
    }
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(documentId),
      principal,
    );

    const providerId = body.provider_id ? BigInt(body.provider_id) : undefined;
    const review = await this.documentService.approvePrescriptionReview(
      BigInt(documentId),
      staffId,
      providerId,
    );
    return {
      success: true,
      message: 'Prescription approved and pharmacy cart prefill prepared',
      data: review,
    };
  }

  @RequirePermissions('documents.view')
  @Get('document-intelligence/logs/:documentId')
  async getLogs(
    @Param('documentId') documentId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.assertCustomerOwnDocument(BigInt(documentId), principal);
    this.assertNotCustomerInternalProcessing(principal);
    await this.providerScopeService.assertProviderCanAccessDocument(
      BigInt(documentId),
      principal,
    );
    const logs = await this.documentService.getLogs(BigInt(documentId));
    return {
      success: true,
      message: 'Processing logs retrieved',
      data: logs,
    };
  }
}
