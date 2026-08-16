import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { PharmacyService } from './pharmacy.service';
import { ProviderScopeService } from '../auth/provider-scope.service';

describe('PharmacyService Order Persistence & Queue', () => {
  let service: PharmacyService;
  let prisma: any;
  let providerScopeService: jest.Mocked<ProviderScopeService>;
  let pricingService: any;
  let referralService: any;
  let walletService: any;

  beforeEach(() => {
    prisma = {
      $transaction: jest.fn().mockImplementation((cb) => cb(prisma)),
      customer: {
        findUnique: jest.fn().mockResolvedValue({ id: 1n, membership: null, wallet: { id: 10n } }),
      },
      serviceProvider: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
      },
      product: {
        findMany: jest.fn(),
      },
      purchase: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn().mockResolvedValue({ id: 501n }),
        update: jest.fn(),
      },
      purchaseItem: {
        create: jest.fn(),
        createMany: jest.fn(),
      },
      cashWalletTransaction: {
        create: jest.fn(),
      },
    };

    providerScopeService = {
      assertProviderCanAccessCustomer: jest.fn(),
      isProviderPrincipal: jest.fn().mockReturnValue(false),
    } as any;

    pricingService = {
      evaluateServicePrice: jest.fn().mockResolvedValue({
        originalAmount: 500,
        discountAmount: 0,
        finalPayableAmount: 500,
        payableAmount: 500,
        benefitAmount: 0,
      }),
    };

    referralService = {
      qualifyRewardFromTransaction: jest.fn().mockResolvedValue(undefined),
    };

    walletService = {
      ensureSufficientCashBalance: jest.fn().mockResolvedValue(undefined),
    };

    service = new PharmacyService(
      prisma,
      providerScopeService,
      pricingService,
      referralService,
      walletService,
    );
  });

  describe('createCustomerOrder', () => {
    it('creates a new customer order and calculates line items using sellingPrice', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE' });
      prisma.product.findMany.mockResolvedValue([
        { id: 101n, sellingPrice: 250.0, mrp: 300.0, productName: 'Vitamin C' },
      ]);
      prisma.purchase.create.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        invoiceNumber: 'ORD-1234',
        payableAmount: 500.0,
      });
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        invoiceNumber: 'ORD-1234',
        payableAmount: 500.0,
        provider: { providerName: 'Hyperpharmacy Main' },
        purchaseItems: [
          {
            id: 901n,
            productId: 101n,
            quantity: 2,
            unitPrice: 250.0,
            totalPrice: 500.0,
            product: { productName: 'Vitamin C' },
          },
        ],
      });

      const order = await service.createCustomerOrder({
        customerId: 1n,
        providerId: 10n,
        items: [{ productId: 101n, quantity: 2 }],
        deliveryAddress: '123 Health Ave',
        customerNotes: 'Please deliver before 5 PM',
      });

      expect(order).toBeDefined();
      expect(order.id).toBe('501');
      expect(order.providerName).toBe('Hyperpharmacy Main');
      expect(prisma.purchase.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            customerId: 1n,
            providerId: 10n,
          }),
        }),
      );
    });

    it('returns existing order when idempotencyKey matches', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE' });
      prisma.purchase.findFirst.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        invoiceNumber: 'ORD-KEY-abc123idempotentKey',
        payableAmount: 250.0,
        provider: { providerName: 'Hyperpharmacy Main' },
        purchaseItems: [],
      });

      const order = await service.createCustomerOrder({
        customerId: 1n,
        providerId: 10n,
        items: [{ productId: 101n, quantity: 1 }],
        idempotencyKey: 'abc123idempotentKey',
      });

      expect(order.id).toBe('501');
      expect(prisma.purchase.create).not.toHaveBeenCalled();
    });

    it('rejects order when items array is empty', async () => {
      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          items: [],
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('updateOrderStatus', () => {
    it('updates order paymentStatus when provider scope check passes', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        paymentStatus: 'REQUESTED',
      });
      prisma.purchase.update.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        paymentStatus: 'READY',
        provider: { providerName: 'Hyperpharmacy Main' },
        purchaseItems: [],
      });

      const updated = await service.updateOrderStatus(501n, 'READY', {
        principalType: 'USER',
        userId: '20',
      } as any);

      expect(providerScopeService.assertProviderCanAccessCustomer).toHaveBeenCalledWith(
        1n,
        expect.anything(),
      );
      expect(updated.paymentStatus).toBe('READY');
    });

    it('throws ForbiddenException when provider scope check fails', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
      });
      providerScopeService.assertProviderCanAccessCustomer.mockRejectedValue(
        new ForbiddenException('Access denied to customer records.'),
      );

      await expect(
        service.updateOrderStatus(501n, 'ACCEPTED', {
          principalType: 'USER',
          userId: '99',
        } as any),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
