import { Injectable } from '@nestjs/common';
import { mkdir, writeFile } from 'fs/promises';
import { join } from 'path';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { getAppEnv } from '../config/app-env';

@Injectable()
export class StorageService {
  private readonly localUploadBaseRoot = join(process.cwd(), 'uploads');
  private readonly localUploadRoot = join(
    process.cwd(),
    'uploads',
    'documents',
  );
  private readonly env = getAppEnv();
  private readonly r2Client = this.isR2Configured()
    ? new S3Client({
        region: 'auto',
        endpoint: this.env.r2Endpoint,
        credentials: {
          accessKeyId: this.env.r2AccessKeyId,
          secretAccessKey: this.env.r2SecretAccessKey,
        },
      })
    : null;

  isR2Configured() {
    return Boolean(
      this.env.r2AccessKeyId &&
      this.env.r2SecretAccessKey &&
      this.env.r2Bucket &&
      this.env.r2Endpoint,
    );
  }

  private safeFileName(fileName: string) {
    return fileName.replace(/[^a-zA-Z0-9._-]+/g, '_');
  }

  buildObjectKey(data: {
    customerId: bigint;
    documentUuid: string;
    fileName: string;
    documentType?: string | null;
    createdAt?: Date;
  }) {
    const year = (data.createdAt ?? new Date()).getUTCFullYear();
    const safeFileName = this.safeFileName(data.fileName);
    const normalizedType = (data.documentType ?? '').trim().toUpperCase();

    switch (normalizedType) {
      case 'PRESCRIPTION':
        return `prescriptions/${data.customerId.toString()}/${year}/${data.documentUuid}_${safeFileName}`;
      case 'LAB_REPORT':
        return `lab-reports/${data.customerId.toString()}/${year}/${data.documentUuid}_${safeFileName}`;
      case 'DENTAL_REPORT':
      case 'DENTAL_RECORD':
        return `doctor-notes/${data.customerId.toString()}/${year}/${data.documentUuid}_${safeFileName}`;
      case 'INVOICE':
      case 'PHARMACY_BILL':
        return `exports/invoices/${data.customerId.toString()}/${year}/${data.documentUuid}_${safeFileName}`;
      default:
        return `customers/${data.customerId.toString()}/documents/${year}/${data.documentUuid}_${safeFileName}`;
    }
  }

  buildScopedObjectKey(data: {
    scope: string;
    ownerId: string;
    objectUuid: string;
    fileName: string;
    createdAt?: Date;
  }) {
    const year = (data.createdAt ?? new Date()).getUTCFullYear();
    const safeScope = data.scope.replace(/[^a-zA-Z0-9/_-]+/g, '-');
    const safeOwnerId = data.ownerId.replace(/[^a-zA-Z0-9._-]+/g, '-');
    const safeFileName = this.safeFileName(data.fileName);
    return `${safeScope}/${safeOwnerId}/${year}/${data.objectUuid}_${safeFileName}`;
  }

  async persistPrivateObject(data: {
    customerId: bigint;
    documentUuid: string;
    fileName: string;
    documentType?: string | null;
    mimeType: string;
    buffer?: Buffer;
  }) {
    if (!data.buffer?.length) {
      return null;
    }

    const objectKey = this.buildObjectKey(data);

    if (this.r2Client) {
      await this.r2Client.send(
        new PutObjectCommand({
          Bucket: this.env.r2Bucket,
          Key: objectKey,
          Body: data.buffer,
          ContentType: data.mimeType,
        }),
      );

      return {
        storagePath: `r2://${this.env.r2Bucket}/${objectKey}`,
        objectKey,
        provider: 'R2' as const,
      };
    }

    const customerDirectory = join(
      this.localUploadRoot,
      `customer-${data.customerId.toString()}`,
    );
    await mkdir(customerDirectory, { recursive: true });

    const absolutePath = join(
      customerDirectory,
      `${data.documentUuid}_${this.safeFileName(data.fileName)}`,
    );
    await writeFile(absolutePath, data.buffer);

    return {
      storagePath: `/uploads/documents/customer-${data.customerId.toString()}/${data.documentUuid}_${this.safeFileName(data.fileName)}`,
      absolutePath,
      provider: 'LOCAL' as const,
    };
  }

  async persistScopedPrivateObject(data: {
    scope: string;
    ownerId: string;
    objectUuid: string;
    fileName: string;
    mimeType: string;
    buffer?: Buffer;
  }) {
    if (!data.buffer?.length) {
      return null;
    }

    const objectKey = this.buildScopedObjectKey(data);

    if (this.r2Client) {
      await this.r2Client.send(
        new PutObjectCommand({
          Bucket: this.env.r2Bucket,
          Key: objectKey,
          Body: data.buffer,
          ContentType: data.mimeType,
        }),
      );

      return {
        storagePath: `r2://${this.env.r2Bucket}/${objectKey}`,
        objectKey,
        provider: 'R2' as const,
      };
    }

    const scopedDirectory = join(
      this.localUploadBaseRoot,
      ...data.scope.split('/'),
      data.ownerId,
    );
    await mkdir(scopedDirectory, { recursive: true });

    const absolutePath = join(
      scopedDirectory,
      `${data.objectUuid}_${this.safeFileName(data.fileName)}`,
    );
    await writeFile(absolutePath, data.buffer);

    return {
      storagePath: `/uploads/${data.scope}/${data.ownerId}/${data.objectUuid}_${this.safeFileName(data.fileName)}`,
      absolutePath,
      provider: 'LOCAL' as const,
    };
  }

  async createDownloadUrl(
    storagePath: string,
    expiresInSeconds = 300,
  ): Promise<string | null> {
    if (storagePath.startsWith('r2://') && this.r2Client) {
      const prefix = `r2://${this.env.r2Bucket}/`;
      const objectKey = storagePath.startsWith(prefix)
        ? storagePath.slice(prefix.length)
        : storagePath.replace(/^r2:\/\/[^/]+\//, '');

      return getSignedUrl(
        this.r2Client,
        new GetObjectCommand({
          Bucket: this.env.r2Bucket,
          Key: objectKey,
        }),
        { expiresIn: expiresInSeconds },
      );
    }

    // Local development storage has no authenticated streaming endpoint. Never
    // return a raw filesystem/static path as though it were a secure URL.
    return null;
  }

  async readObjectBuffer(
    storagePath: string,
  ): Promise<{ buffer: Buffer; contentType: string } | null> {
    if (storagePath.startsWith('r2://') && this.r2Client) {
      const prefix = `r2://${this.env.r2Bucket}/`;
      const objectKey = storagePath.startsWith(prefix)
        ? storagePath.slice(prefix.length)
        : storagePath.replace(/^r2:\/\/[^/]+\//, '');

      try {
        const result = await this.r2Client.send(
          new GetObjectCommand({
            Bucket: this.env.r2Bucket,
            Key: objectKey,
          }),
        );
        if (!result.Body) return null;
        const bytes = await result.Body.transformToByteArray();
        return {
          buffer: Buffer.from(bytes),
          contentType: result.ContentType || 'image/png',
        };
      } catch (err) {
        return null;
      }
    }

    if (storagePath.startsWith('/uploads/')) {
      const absolutePath = join(process.cwd(), storagePath);
      try {
        const { readFile } = await import('fs/promises');
        const buffer = await readFile(absolutePath);
        const ext = absolutePath.split('.').pop()?.toLowerCase();
        const contentType =
          ext === 'jpg' || ext === 'jpeg' ? 'image/jpeg' : 'image/png';
        return { buffer, contentType };
      } catch (err) {
        return null;
      }
    }
    return null;
  }
}
