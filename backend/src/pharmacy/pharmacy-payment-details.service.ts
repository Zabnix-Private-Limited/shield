import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { TimelineService } from '../timeline/timeline.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { ShieldPrincipal } from '../auth/auth.types';
import {
  CreateBankAccountDto,
  CreateUpiDto,
  UpdateBankAccountDto,
  UpdateUpiDto,
} from './dto/pharmacy-payment-details.dto';

export interface MaskedBankAccountProjection {
  id: string;
  uuid: string;
  methodType: 'BANK_ACCOUNT';
  displayLabel?: string;
  accountHolderName: string;
  bankName: string;
  maskedAccountNumber: string;
  ifscCode: string;
  branchName?: string;
  isActive: boolean;
  isPrimary: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface UpiMethodProjection {
  id: string;
  uuid: string;
  methodType: 'UPI';
  displayLabel?: string;
  upiId: string;
  qrImageUrl?: string;
  qrFileName?: string;
  isActive: boolean;
  isPrimary: boolean;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class PharmacyPaymentDetailsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly timelineService: TimelineService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  private maskAccountNumber(accountNumber?: string | null): string {
    if (!accountNumber) return '';
    const clean = accountNumber.trim();
    if (clean.length <= 4) return clean;
    const lastFour = clean.slice(-4);
    return `•••• •••• ${lastFour}`;
  }

  private validateIfsc(ifsc: string) {
    const clean = ifsc.trim().toUpperCase();
    const ifscRegex = /^[A-Z]{4}0[A-Z0-9]{6}$/;
    if (!ifscRegex.test(clean)) {
      throw new BadRequestException(
        'Invalid IFSC code format. Expected format: 4 uppercase letters, 0, then 6 alphanumeric characters (e.g. HDFC0001234).',
      );
    }
    return clean;
  }

  private validateUpi(upiId: string) {
    const clean = upiId.trim().toLowerCase();
    const upiRegex = /^[\w\.\-]+@[\w\.\-]+$/;
    if (!upiRegex.test(clean)) {
      throw new BadRequestException(
        'Invalid UPI ID format. Expected format: pharmacy@upi',
      );
    }
    return clean;
  }

  private async getPharmacyProviderId(principal?: ShieldPrincipal): Promise<bigint> {
    const scope = this.providerScopeService.resolveWorkspaceScope(principal, {});
    let provider: any = null;

    if (scope.providerId) {
      provider = await this.prisma.serviceProvider.findFirst({
        where: { id: scope.providerId, status: 'ACTIVE' },
      });
    } else if (scope.businessId) {
      provider = await this.prisma.serviceProvider.findFirst({
        where: { businessId: scope.businessId, providerType: 'PHARMACY', status: 'ACTIVE' },
      });
    } else {
      provider = await this.prisma.serviceProvider.findFirst({
        where: { providerType: 'PHARMACY', status: 'ACTIVE' },
      });
    }

    if (!provider) {
      throw new NotFoundException(
        'Active pharmacy service provider context not found.',
      );
    }
    return provider.id;
  }

  private async verifyMethodOwnership(
    methodId: bigint,
    providerId: bigint,
  ): Promise<any> {
    const method = await (this.prisma as any).serviceProviderPaymentMethod.findFirst({
      where: {
        id: methodId,
        providerId,
        deletedAt: null,
      },
    });

    if (!method) {
      throw new NotFoundException(
        'Payment method not found or access denied for this pharmacy.',
      );
    }
    return method;
  }

  async listPaymentMethods(principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);

    const methods = await (this.prisma as any).serviceProviderPaymentMethod.findMany({
      where: {
        providerId,
        deletedAt: null,
      },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'desc' }],
    });

    const bankAccounts: MaskedBankAccountProjection[] = [];
    const upiMethods: UpiMethodProjection[] = [];

    for (const m of methods) {
      if (m.methodType === 'BANK_ACCOUNT') {
        bankAccounts.push({
          id: m.id.toString(),
          uuid: m.uuid,
          methodType: 'BANK_ACCOUNT',
          displayLabel: m.displayLabel || undefined,
          accountHolderName: m.accountHolderName || '',
          bankName: m.bankName || '',
          maskedAccountNumber: this.maskAccountNumber(m.accountNumber),
          ifscCode: m.ifscCode || '',
          branchName: m.branchName || undefined,
          isActive: m.isActive,
          isPrimary: m.isPrimary,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        });
      } else if (m.methodType === 'UPI') {
        let qrImageUrl: string | undefined;
        if (m.qrStoragePath) {
          const downloadUrl = await this.storageService.createDownloadUrl(m.qrStoragePath);
          if (downloadUrl) qrImageUrl = downloadUrl;
        }

        upiMethods.push({
          id: m.id.toString(),
          uuid: m.uuid,
          methodType: 'UPI',
          displayLabel: m.displayLabel || undefined,
          upiId: m.upiId || '',
          qrImageUrl,
          qrFileName: m.qrFileName || undefined,
          isActive: m.isActive,
          isPrimary: m.isPrimary,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        });
      }
    }

    return { bankAccounts, upiMethods };
  }

  async createBankAccount(dto: CreateBankAccountDto, principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);
    if (!dto.accountHolderName?.trim()) {
      throw new BadRequestException('Account holder name is required.');
    }
    if (!dto.bankName?.trim()) {
      throw new BadRequestException('Bank name is required.');
    }
    if (!dto.accountNumber?.trim()) {
      throw new BadRequestException('Account number is required.');
    }
    if (!dto.ifscCode?.trim()) {
      throw new BadRequestException('IFSC code is required.');
    }

    const normalizedIfsc = this.validateIfsc(dto.ifscCode);
    const cleanAccountNumber = dto.accountNumber.trim();

    return this.prisma.$transaction(async (tx) => {
      const isPrimary = dto.isPrimary ?? false;
      const isActive = dto.isActive ?? true;

      if (isPrimary) {
        await (tx as any).serviceProviderPaymentMethod.updateMany({
          where: {
            providerId,
            methodType: 'BANK_ACCOUNT',
            deletedAt: null,
          },
          data: { isPrimary: false },
        });
      }

      const created = await (tx as any).serviceProviderPaymentMethod.create({
        data: {
          providerId,
          methodType: 'BANK_ACCOUNT',
          displayLabel: dto.displayLabel?.trim(),
          accountHolderName: dto.accountHolderName.trim(),
          bankName: dto.bankName.trim(),
          accountNumber: cleanAccountNumber,
          ifscCode: normalizedIfsc,
          branchName: dto.branchName?.trim(),
          isActive,
          isPrimary: isActive ? isPrimary : false,
        },
      });

      await this.timelineService.recordAuditLog({
        action: 'BANK_ACCOUNT_CREATED',
        entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
        entityId: created.id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: {
          bankName: dto.bankName.trim(),
          maskedAccountNumber: this.maskAccountNumber(cleanAccountNumber),
          providerId: providerId.toString(),
        },
      });

      return {
        id: created.id.toString(),
        uuid: created.uuid,
        methodType: 'BANK_ACCOUNT',
        displayLabel: created.displayLabel,
        accountHolderName: created.accountHolderName,
        bankName: created.bankName,
        maskedAccountNumber: this.maskAccountNumber(created.accountNumber),
        ifscCode: created.ifscCode,
        branchName: created.branchName,
        isActive: created.isActive,
        isPrimary: created.isPrimary,
      };
    });
  }

  async updateBankAccount(
    id: bigint,
    dto: UpdateBankAccountDto,
    principal?: ShieldPrincipal,
  ) {
    const providerId = await this.getPharmacyProviderId(principal);
    const existing = await this.verifyMethodOwnership(id, providerId);

    const ifscCode = dto.ifscCode ? this.validateIfsc(dto.ifscCode) : existing.ifscCode;

    return this.prisma.$transaction(async (tx) => {
      const isPrimary = dto.isPrimary ?? existing.isPrimary;
      const isActive = dto.isActive ?? existing.isActive;

      if (isPrimary && !existing.isPrimary) {
        await (tx as any).serviceProviderPaymentMethod.updateMany({
          where: {
            providerId,
            methodType: 'BANK_ACCOUNT',
            deletedAt: null,
          },
          data: { isPrimary: false },
        });
      }

      const updated = await (tx as any).serviceProviderPaymentMethod.update({
        where: { id },
        data: {
          accountHolderName: dto.accountHolderName?.trim() ?? existing.accountHolderName,
          bankName: dto.bankName?.trim() ?? existing.bankName,
          accountNumber: dto.accountNumber?.trim() ?? existing.accountNumber,
          ifscCode,
          branchName: dto.branchName?.trim() ?? existing.branchName,
          displayLabel: dto.displayLabel?.trim() ?? existing.displayLabel,
          isActive,
          isPrimary: isActive ? isPrimary : false,
          updatedAt: new Date(),
        },
      });

      await this.timelineService.recordAuditLog({
        action: 'BANK_ACCOUNT_UPDATED',
        entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
        entityId: id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: { methodId: id.toString(), providerId: providerId.toString() },
      });

      return {
        id: updated.id.toString(),
        uuid: updated.uuid,
        methodType: 'BANK_ACCOUNT',
        displayLabel: updated.displayLabel,
        accountHolderName: updated.accountHolderName,
        bankName: updated.bankName,
        maskedAccountNumber: this.maskAccountNumber(updated.accountNumber),
        ifscCode: updated.ifscCode,
        branchName: updated.branchName,
        isActive: updated.isActive,
        isPrimary: updated.isPrimary,
      };
    });
  }

  async createUpi(dto: CreateUpiDto, principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);
    if (!dto.upiId?.trim()) {
      throw new BadRequestException('UPI ID is required.');
    }
    const cleanUpi = this.validateUpi(dto.upiId);

    return this.prisma.$transaction(async (tx) => {
      const isPrimary = dto.isPrimary ?? false;
      const isActive = dto.isActive ?? true;

      if (isPrimary) {
        await (tx as any).serviceProviderPaymentMethod.updateMany({
          where: {
            providerId,
            methodType: 'UPI',
            deletedAt: null,
          },
          data: { isPrimary: false },
        });
      }

      const created = await (tx as any).serviceProviderPaymentMethod.create({
        data: {
          providerId,
          methodType: 'UPI',
          displayLabel: dto.displayLabel?.trim(),
          upiId: cleanUpi,
          isActive,
          isPrimary: isActive ? isPrimary : false,
        },
      });

      await this.timelineService.recordAuditLog({
        action: 'UPI_CREATED',
        entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
        entityId: created.id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: { upiId: cleanUpi, providerId: providerId.toString() },
      });

      return {
        id: created.id.toString(),
        uuid: created.uuid,
        methodType: 'UPI',
        displayLabel: created.displayLabel,
        upiId: created.upiId,
        isActive: created.isActive,
        isPrimary: created.isPrimary,
      };
    });
  }

  async updateUpi(id: bigint, dto: UpdateUpiDto, principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);
    const existing = await this.verifyMethodOwnership(id, providerId);
    const cleanUpi = dto.upiId ? this.validateUpi(dto.upiId) : existing.upiId;

    return this.prisma.$transaction(async (tx) => {
      const isPrimary = dto.isPrimary ?? existing.isPrimary;
      const isActive = dto.isActive ?? existing.isActive;

      if (isPrimary && !existing.isPrimary) {
        await (tx as any).serviceProviderPaymentMethod.updateMany({
          where: {
            providerId,
            methodType: 'UPI',
            deletedAt: null,
          },
          data: { isPrimary: false },
        });
      }

      const updated = await (tx as any).serviceProviderPaymentMethod.update({
        where: { id },
        data: {
          upiId: cleanUpi,
          displayLabel: dto.displayLabel?.trim() ?? existing.displayLabel,
          isActive,
          isPrimary: isActive ? isPrimary : false,
          updatedAt: new Date(),
        },
      });

      await this.timelineService.recordAuditLog({
        action: 'UPI_UPDATED',
        entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
        entityId: id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: { methodId: id.toString(), providerId: providerId.toString() },
      });

      return {
        id: updated.id.toString(),
        uuid: updated.uuid,
        methodType: 'UPI',
        displayLabel: updated.displayLabel,
        upiId: updated.upiId,
        isActive: updated.isActive,
        isPrimary: updated.isPrimary,
      };
    });
  }

  async uploadUpiQr(
    id: bigint,
    file: Express.Multer.File,
    principal?: ShieldPrincipal,
  ) {
    const providerId = await this.getPharmacyProviderId(principal);
    const existing = await this.verifyMethodOwnership(id, providerId);

    if (existing.methodType !== 'UPI') {
      throw new BadRequestException('QR image can only be uploaded for UPI methods.');
    }

    if (!file || !file.mimetype.startsWith('image/')) {
      throw new BadRequestException('Only image files (PNG/JPEG) are allowed for QR upload.');
    }

    const persistResult = await this.storageService.persistScopedPrivateObject({
      scope: 'pharmacies/payment-methods',
      ownerId: providerId.toString(),
      objectUuid: existing.uuid,
      fileName: file.originalname,
      mimeType: file.mimetype,
      buffer: file.buffer,
    });

    if (!persistResult?.storagePath) {
      throw new BadRequestException('Failed to upload QR image file.');
    }

    const updated = await (this.prisma as any).serviceProviderPaymentMethod.update({
      where: { id },
      data: {
        qrStoragePath: persistResult.storagePath,
        qrFileName: file.originalname,
        qrMimeType: file.mimetype,
        updatedAt: new Date(),
      },
    });

    const qrImageUrl = await this.storageService.createDownloadUrl(
      persistResult.storagePath,
    );

    await this.timelineService.recordAuditLog({
      action: 'UPI_QR_UPLOADED',
      entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
      entityId: id,
      userId: principal?.userId ? BigInt(principal.userId) : undefined,
      newData: { methodId: id.toString(), providerId: providerId.toString() },
    });

    return {
      id: updated.id.toString(),
      uuid: updated.uuid,
      methodType: 'UPI',
      upiId: updated.upiId,
      qrImageUrl: qrImageUrl || undefined,
      qrFileName: updated.qrFileName,
    };
  }

  async removeUpiQr(id: bigint, principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);
    const existing = await this.verifyMethodOwnership(id, providerId);

    const updated = await (this.prisma as any).serviceProviderPaymentMethod.update({
      where: { id },
      data: {
        qrStoragePath: null,
        qrFileName: null,
        qrMimeType: null,
        updatedAt: new Date(),
      },
    });

    await this.timelineService.recordAuditLog({
      action: 'UPI_QR_REMOVED',
      entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
      entityId: id,
      userId: principal?.userId ? BigInt(principal.userId) : undefined,
      newData: { methodId: id.toString(), providerId: providerId.toString() },
    });

    return {
      id: updated.id.toString(),
      uuid: updated.uuid,
      methodType: 'UPI',
      upiId: updated.upiId,
      qrImageUrl: null,
    };
  }

  async setPrimaryMethod(id: bigint, principal?: ShieldPrincipal) {
    const providerId = await this.getPharmacyProviderId(principal);
    const existing = await this.verifyMethodOwnership(id, providerId);

    if (!existing.isActive) {
      throw new BadRequestException('Inactive payment method cannot be set as primary.');
    }

    return this.prisma.$transaction(async (tx) => {
      await (tx as any).serviceProviderPaymentMethod.updateMany({
        where: {
          providerId,
          methodType: existing.methodType,
          deletedAt: null,
        },
        data: { isPrimary: false },
      });

      const updated = await (tx as any).serviceProviderPaymentMethod.update({
        where: { id },
        data: { isPrimary: true, updatedAt: new Date() },
      });

      await this.timelineService.recordAuditLog({
        action: `${existing.methodType}_PRIMARY_SET`,
        entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
        entityId: id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: { methodId: id.toString(), providerId: providerId.toString() },
      });

      return updated;
    });
  }

  async toggleActiveMethod(
    id: bigint,
    isActive: boolean,
    principal?: ShieldPrincipal,
  ) {
    const providerId = await this.getPharmacyProviderId(principal);
    const existing = await this.verifyMethodOwnership(id, providerId);

    return this.prisma.$transaction(async (tx) => {
      const updated = await (tx as any).serviceProviderPaymentMethod.update({
        where: { id },
        data: {
          isActive,
          isPrimary: isActive ? existing.isPrimary : false,
          updatedAt: new Date(),
        },
      });

      await this.timelineService.recordAuditLog({
        action: isActive ? `${existing.methodType}_ACTIVATED` : `${existing.methodType}_DEACTIVATED`,
        entityType: 'SERVICE_PROVIDER_PAYMENT_METHOD',
        entityId: id,
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        newData: { methodId: id.toString(), isActive, providerId: providerId.toString() },
      });

      return updated;
    });
  }

  async getCustomerSafePaymentDetails(providerId: bigint) {
    const provider = await this.prisma.serviceProvider.findFirst({
      where: {
        id: providerId,
        status: 'ACTIVE',
        providerType: 'PHARMACY',
      },
    });

    if (!provider) {
      throw new NotFoundException('Active pharmacy service provider not found.');
    }

    const methods = await (this.prisma as any).serviceProviderPaymentMethod.findMany({
      where: {
        providerId,
        isActive: true,
        deletedAt: null,
      },
      orderBy: [{ isPrimary: 'desc' }, { createdAt: 'desc' }],
    });

    const bankAccounts = [];
    const upiMethods = [];

    for (const m of methods) {
      if (m.methodType === 'BANK_ACCOUNT') {
        bankAccounts.push({
          id: m.id.toString(),
          methodType: 'BANK_ACCOUNT',
          displayLabel: m.displayLabel || undefined,
          accountHolderName: m.accountHolderName || '',
          bankName: m.bankName || '',
          maskedAccountNumber: this.maskAccountNumber(m.accountNumber),
          ifscCode: m.ifscCode || '',
          branchName: m.branchName || undefined,
          isPrimary: m.isPrimary,
        });
      } else if (m.methodType === 'UPI') {
        let qrImageUrl: string | undefined;
        if (m.qrStoragePath) {
          const downloadUrl = await this.storageService.createDownloadUrl(m.qrStoragePath);
          if (downloadUrl) qrImageUrl = downloadUrl;
        }

        upiMethods.push({
          id: m.id.toString(),
          methodType: 'UPI',
          displayLabel: m.displayLabel || undefined,
          upiId: m.upiId || '',
          qrImageUrl,
          isPrimary: m.isPrimary,
        });
      }
    }

    return { providerId: providerId.toString(), bankAccounts, upiMethods };
  }
}
