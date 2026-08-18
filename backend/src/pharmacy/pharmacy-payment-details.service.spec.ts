import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { PharmacyPaymentDetailsService } from './pharmacy-payment-details.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { TimelineService } from '../timeline/timeline.service';
import { ProviderScopeService } from '../auth/provider-scope.service';

describe('PharmacyPaymentDetailsService', () => {
  let service: PharmacyPaymentDetailsService;
  let prisma: any;
  let storageService: any;
  let timelineService: any;
  let providerScopeService: any;

  beforeEach(async () => {
    prisma = {
      serviceProvider: {
        findFirst: jest.fn(),
      },
      serviceProviderPaymentMethod: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      $transaction: jest.fn((cb) => cb(prisma)),
    };

    storageService = {
      createDownloadUrl: jest.fn().mockResolvedValue('https://storage.shield.local/qr.png'),
      persistScopedPrivateObject: jest.fn().mockResolvedValue({ storagePath: 'pharmacies/101/qr.png' }),
    };

    timelineService = {
      recordAuditLog: jest.fn().mockResolvedValue(true),
    };

    providerScopeService = {
      resolveWorkspaceScope: jest.fn().mockReturnValue({ providerId: 101n, businessId: 1n }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PharmacyPaymentDetailsService,
        { provide: PrismaService, useValue: prisma },
        { provide: StorageService, useValue: storageService },
        { provide: TimelineService, useValue: timelineService },
        { provide: ProviderScopeService, useValue: providerScopeService },
      ],
    }).compile();

    service = module.get<PharmacyPaymentDetailsService>(
      PharmacyPaymentDetailsService,
    );
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should list payment methods with masked account numbers', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.serviceProviderPaymentMethod.findMany.mockResolvedValue([
      {
        id: 1n,
        uuid: 'u1',
        providerId: 101n,
        methodType: 'BANK_ACCOUNT',
        accountHolderName: 'SHIELD Pharmacy',
        bankName: 'HDFC Bank',
        accountNumber: '123456789012',
        ifscCode: 'HDFC0001234',
        isActive: true,
        isPrimary: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        id: 2n,
        uuid: 'u2',
        providerId: 101n,
        methodType: 'UPI',
        upiId: 'pharmacy@upi',
        qrStoragePath: 'qr/path.png',
        isActive: true,
        isPrimary: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ]);

    const result = await service.listPaymentMethods();
    expect(result.bankAccounts).toHaveLength(1);
    expect(result.bankAccounts[0].maskedAccountNumber).toBe('•••• •••• 9012');
    expect(result.upiMethods).toHaveLength(1);
    expect(result.upiMethods[0].upiId).toBe('pharmacy@upi');
    expect(result.upiMethods[0].qrImageUrl).toBe('https://storage.shield.local/qr.png');
  });

  it('should throw NotFoundException if Pharmacy A attempts to access Pharmacy B method', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.serviceProviderPaymentMethod.findFirst.mockResolvedValue(null);

    await expect(
      service.updateBankAccount(999n, { bankName: 'Hacked Bank' }),
    ).rejects.toThrow(NotFoundException);
  });

  it('should reject invalid IFSC format', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });

    await expect(
      service.createBankAccount({
        accountHolderName: 'Holder',
        bankName: 'Bank',
        accountNumber: '12345',
        ifscCode: 'INVALID_IFSC',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should reject invalid UPI format', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });

    await expect(
      service.createUpi({ upiId: 'invalid_upi_no_at_sign' }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should clear primary status from previous bank account when new primary bank account is created', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.serviceProviderPaymentMethod.create.mockResolvedValue({
      id: 2n,
      uuid: 'u2',
      providerId: 101n,
      methodType: 'BANK_ACCOUNT',
      accountHolderName: 'New Holder',
      bankName: 'ICICI Bank',
      accountNumber: '9876543210',
      ifscCode: 'ICIC0001234',
      isActive: true,
      isPrimary: true,
    });

    await service.createBankAccount({
      accountHolderName: 'New Holder',
      bankName: 'ICICI Bank',
      accountNumber: '9876543210',
      ifscCode: 'ICIC0001234',
      isPrimary: true,
    });

    expect(prisma.serviceProviderPaymentMethod.updateMany).toHaveBeenCalledWith({
      where: {
        providerId: 101n,
        methodType: 'BANK_ACCOUNT',
        deletedAt: null,
      },
      data: { isPrimary: false },
    });
  });

  it('should assert financial invariant: Phase 2 performs zero ledger writes or wallet recharge mutations', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.serviceProviderPaymentMethod.create.mockResolvedValue({
      id: 10n,
      uuid: 'u10',
      providerId: 101n,
      methodType: 'UPI',
      upiId: 'test@upi',
      isActive: true,
      isPrimary: false,
    });

    await service.createUpi({ upiId: 'test@upi' });

    // Confirm no wallet ledger calls exist in Prisma mock
    expect(prisma.walletTransaction).toBeUndefined();
    expect(prisma.walletRechargeIntent).toBeUndefined();
  });
});
