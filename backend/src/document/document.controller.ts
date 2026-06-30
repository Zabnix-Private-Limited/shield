import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
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
import { DocumentService } from './document.service';

@Controller()
export class DocumentController {
  constructor(private documentService: DocumentService) {}

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
    const uploaderId =
      principal?.userId != null
        ? BigInt(principal.userId)
        : body.uploaded_by
          ? BigInt(body.uploaded_by)
          : undefined;
    if (principal?.principalType === 'CUSTOMER') {
      body.customer_id = principal.customerId;
    }
    const doc = await this.documentService.upload({
      customerId: BigInt(body.customer_id),
      fileName: file?.originalname || body.file_name || 'prescription.pdf',
      fileSize: Number(file?.size || body.file_size || 1024),
      mimeType: file?.mimetype || body.mime_type || 'application/pdf',
      documentType: body.document_type || 'prescription',
      uploadedBy: uploaderId,
      fileBuffer: file?.buffer,
    });
    return {
      success: true,
      message: 'Document uploaded successfully',
      data: doc,
    };
  }

  @RequirePermissions('documents.view')
  @Get('documents')
  async list(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const targetCustomerId =
      principal?.principalType === 'CUSTOMER'
        ? BigInt(principal.customerId!)
        : customerId
          ? BigInt(customerId)
          : undefined;
    const docs = await this.documentService.list(targetCustomerId);
    return {
      success: true,
      message: 'Documents list retrieved',
      data: docs,
    };
  }

  @RequirePermissions('documents.view')
  @Get('documents/:id')
  async findOne(@Param('id') id: string) {
    const doc = await this.documentService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Document details retrieved',
      data: doc,
    };
  }

  @RequirePermissions('documents.view')
  @Get('documents/:id/download')
  async download(@Param('id') id: string) {
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
  async softDelete(@Param('id') id: string) {
    await this.documentService.softDelete(BigInt(id));
    return {
      success: true,
      message: 'Document soft-deleted successfully',
    };
  }

  @RequirePermissions('documents.approve')
  @Post('document-intelligence/classify')
  async classify(@Body() body: any) {
    const doc = await this.documentService.classify(BigInt(body.document_id));
    return {
      success: true,
      message: 'Document intelligence classification complete',
      data: doc,
    };
  }

  @RequirePermissions('documents.view')
  @Post('document-intelligence/extract')
  async extract(@Body() body: any) {
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
  async getPrescriptionReview(@Param('documentId') documentId: string) {
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
  async getLogs(@Param('documentId') documentId: string) {
    const logs = await this.documentService.getLogs(BigInt(documentId));
    return {
      success: true,
      message: 'Processing logs retrieved',
      data: logs,
    };
  }
}
