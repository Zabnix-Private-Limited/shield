import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  HttpCode,
} from '@nestjs/common';
import { DocumentService } from './document.service';

@Controller()
export class DocumentController {
  constructor(private documentService: DocumentService) {}

  @Post('documents/upload')
  async upload(@Body() body: any) {
    const uploaderId = body.uploaded_by ? BigInt(body.uploaded_by) : undefined;
    const doc = await this.documentService.upload({
      customerId: BigInt(body.customer_id),
      fileName: body.file_name || 'prescription.pdf',
      fileSize: Number(body.file_size || 1024),
      mimeType: body.mime_type || 'application/pdf',
      documentType: body.document_type || 'prescription',
      uploadedBy: uploaderId,
    });
    return {
      success: true,
      message: 'Document metadata uploaded successfully',
      data: doc,
    };
  }

  @Get('documents')
  async list(@Query('customer_id') customerId?: string) {
    const targetCustomerId = customerId ? BigInt(customerId) : undefined;
    const docs = await this.documentService.list(targetCustomerId);
    return {
      success: true,
      message: 'Documents list retrieved',
      data: docs,
    };
  }

  @Get('documents/:id')
  async findOne(@Param('id') id: string) {
    const doc = await this.documentService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Document details retrieved',
      data: doc,
    };
  }

  @Get('documents/:id/download')
  async download(@Param('id') id: string) {
    const doc = await this.documentService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Document download URL retrieved',
      data: {
        url: doc.storagePath,
      },
    };
  }

  @Delete('documents/:id')
  @HttpCode(200)
  async softDelete(@Param('id') id: string) {
    await this.documentService.softDelete(BigInt(id));
    return {
      success: true,
      message: 'Document soft-deleted successfully',
    };
  }

  @Post('document-intelligence/classify')
  async classify(@Body() body: any) {
    const doc = await this.documentService.classify(BigInt(body.document_id));
    return {
      success: true,
      message: 'Document intelligence classification complete',
      data: doc,
    };
  }

  @Post('document-intelligence/extract')
  async extract(@Body() body: any) {
    const doc = await this.documentService.extract(BigInt(body.document_id));
    return {
      success: true,
      message: 'Document intelligence text extraction complete',
      data: doc,
    };
  }

  @Post('document-intelligence/validate')
  async validate(@Body() body: any) {
    const staffId = body.staff_id ? BigInt(body.staff_id) : BigInt(1);
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
