import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { PharmacyPaymentsService } from './pharmacy-payments.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { TimelineService } from '../timeline/timeline.service';
import { ProviderScopeService } from '../auth/provider-scope.service';

describe('PharmacyPaymentsService', () => {
  let service: PharmacyPaymentsService;
  let prisma: any;
  let storageService: any;
  let timelineService: any;
  let providerScopeService: any;

  beforeEach(async () => {
    prisma = {
      serviceProvider: {
        findFirst: jest.fn(),
      },
      purchase: {
        count: jest.fn().mockResolvedValue(2),
        aggregate: jest.fn().mockResolvedValue({ _sum: { payableAmount: 500 } }),
        findMany: jest.fn().mockResolvedValue([]),
      },
      walletRechargeIntent: {
        count: jest.fn().mockResolvedValue(1),
        aggregate: jest.fn().mockResolvedValue({ _sum: { amount: 200 } }),
        findMany: jest.fn().mockResolvedValue([]),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      serviceProviderPaymentMethod: {
        count: jest.fn().mockResolvedValue(1),
      },
      customer: {
        findUnique: jest.fn(),
      },
      cashWalletTransaction: {
        create: jest.fn().mockResolvedValue({ id: 10n }),
      },
      walletTransaction: {
        create: jest.fn().mockResolvedValue({ id: 11n }),
      },
      $transaction: jest.fn((cb) => cb(prisma)),
    };

    storageService = {
      createDownloadUrl: jest.fn().mockResolvedValue('https://storage.shield.local/proof.png'),
    };

    timelineService = {
      recordAuditLog: jest.fn().mockResolvedValue(true),
    };

    providerScopeService = {
      resolveWorkspaceScope: jest.fn().mockReturnValue({ providerId: 101n, businessId: 1n }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PharmacyPaymentsService,
        { provide: PrismaService, useValue: prisma },
        { provide: StorageService, useValue: storageService },
        { provide: TimelineService, useValue: timelineService },
        { provide: ProviderScopeService, useValue: providerScopeService },
      ],
    }).compile();

    service = module.get<PharmacyPaymentsService>(PharmacyPaymentsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should aggregate pharmacy dashboard metrics correctly', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });

    const res = await service.getPharmacyDashboard();
    expect(res.orders.new).toBe(2);
    expect(res.orders.orderValueToday).toBe(500);
    expect(res.payments.pendingVerification).toBe(1);
    expect(res.paymentConfiguration.bankConfigured).toBe(true);
    expect(res.paymentConfiguration.upiConfigured).toBe(true);
  });

  it('should approve pending payment, credit cash wallet, and set status APPROVED atomically', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.walletRechargeIntent.updateMany.mockResolvedValue({ count: 1 }); // Atomic state claim succeeded
    prisma.walletRechargeIntent.findFirst.mockResolvedValue({
      id: 50n,
      uuid: 'intent-uuid-1',
      providerId: 101n,
      walletId: 5n,
      amount: 1500.0,
      paymentChannel: 'UPI',
      status: 'APPROVED',
    });

    const res = await service.approvePayment(50n);

    expect(res.status).toBe('APPROVED');
    expect(prisma.walletRechargeIntent.updateMany).toHaveBeenCalledWith({
      where: { id: 50n, providerId: 101n, status: 'PENDING' },
      data: expect.objectContaining({ status: 'APPROVED' }),
    });
    expect(prisma.cashWalletTransaction.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        walletId: 5n,
        transactionType: 'RECHARGE',
        amount: 1500.0,
        referenceType: 'MANUAL_RECHARGE_APPROVAL',
        referenceId: 50n,
      }),
    });
  });

  it('should prevent double approval via atomic conditional claim (count === 0)', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.walletRechargeIntent.updateMany.mockResolvedValue({ count: 0 }); // Claim failed! Already approved/rejected
    prisma.walletRechargeIntent.findFirst.mockResolvedValue({
      id: 50n,
      providerId: 101n,
      walletId: 5n,
      status: 'APPROVED', // Already approved!
    });

    await expect(service.approvePayment(50n)).rejects.toThrow(BadRequestException);
    expect(prisma.cashWalletTransaction.create).not.toHaveBeenCalled();
  });

  it('should reject payment with reason and perform ZERO wallet credit atomically', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.walletRechargeIntent.updateMany.mockResolvedValue({ count: 1 });
    prisma.walletRechargeIntent.findFirst.mockResolvedValue({
      id: 60n,
      uuid: 'intent-uuid-2',
      providerId: 101n,
      walletId: 5n,
      amount: 500.0,
      status: 'REJECTED',
    });

    const res = await service.rejectPayment(60n, {
      rejectionReason: 'Invalid UTR reference number',
    });

    expect(res.status).toBe('REJECTED');
    expect(res.rejectionReason).toBe('Invalid UTR reference number');
    expect(prisma.cashWalletTransaction.create).not.toHaveBeenCalled();
  });

  it('should enforce provider isolation when accessing payment details', async () => {
    prisma.serviceProvider.findFirst.mockResolvedValue({ id: 101n, status: 'ACTIVE' });
    prisma.walletRechargeIntent.findFirst.mockResolvedValue(null); // Access denied / wrong provider

    await expect(service.getPaymentDetail(999n)).rejects.toThrow(NotFoundException);
  });

  describe('Business-Day Timezone Semantics', () => {
    it('computes correct startUtc and endUtc boundaries for Asia/Kolkata timezone', () => {
      // 00:15 IST on Aug 18, 2026 is 18:45 UTC on Aug 17, 2026
      const earlyMorningIst = new Date('2026-08-17T18:45:00.000Z');
      const { startUtc, endUtc } = service.getBusinessDayInterval('Asia/Kolkata', earlyMorningIst);

      // Start of Aug 18 IST (00:00 IST) is Aug 17, 18:30 UTC
      expect(startUtc.toISOString()).toBe('2026-08-17T18:30:00.000Z');
      // End of Aug 18 IST (00:00 IST next day) is Aug 18, 18:30 UTC
      expect(endUtc.toISOString()).toBe('2026-08-18T18:30:00.000Z');

      // The early morning IST event (18:45 UTC) MUST fall inside [startUtc, endUtc)
      expect(earlyMorningIst.getTime()).toBeGreaterThanOrEqual(startUtc.getTime());
      expect(earlyMorningIst.getTime()).toBeLessThan(endUtc.getTime());
    });

    it('places an event just before midnight IST into the prior business day interval', () => {
      // 23:45 IST on Aug 17, 2026 is 18:15 UTC on Aug 17, 2026
      const lateNightIst = new Date('2026-08-17T18:15:00.000Z');
      const { startUtc } = service.getBusinessDayInterval('Asia/Kolkata', new Date('2026-08-17T18:45:00.000Z')); // Aug 18 IST day

      // 18:15 UTC is BEFORE 18:30 UTC start of Aug 18 IST, so it belongs to Aug 17 IST business day
      expect(lateNightIst.getTime()).toBeLessThan(startUtc.getTime());
    });
  });
});
