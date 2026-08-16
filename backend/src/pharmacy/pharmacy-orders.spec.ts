import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { PharmacyController } from './pharmacy.controller';
import { PharmacyService } from './pharmacy.service';
import { ProviderScopeService } from '../auth/provider-scope.service';

describe('PharmacyService Operational Order Persistence & Isolation', () => {
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
      assertProviderCanAccessPurchase: jest.fn(),
      scopePurchaseWhere: jest.fn().mockImplementation((where) => where),
      isProviderPrincipal: jest.fn().mockReturnValue(false),
    } as any;

    pricingService = {
      evaluateServicePrice: jest.fn(),
    };

    referralService = {
      qualifyRewardFromTransaction: jest.fn(),
    };

    walletService = {
      ensureSufficientCashBalance: jest.fn(),
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
    it('creates an operational order WITHOUT cash wallet settlement or referral reward qualification', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({
        id: 10n,
        status: 'ACTIVE',
        providerType: 'PHARMACY',
      });
      prisma.product.findMany.mockResolvedValue([
        { id: 101n, sellingPrice: 250.0, mrp: 300.0, productName: 'Vitamin C', status: 'ACTIVE' },
      ]);
      prisma.purchase.create.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        invoiceNumber: 'ORD-1234',
        purchaseKind: 'CUSTOMER_ORDER',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
        totalAmount: 500.0,
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
      expect(order.orderStatus).toBe('PLACED');
      expect(order.paymentStatus).toBe('PENDING');

      // INVARIANT: Customer order placement must NEVER debit cash wallet or qualify referral rewards
      expect(walletService.ensureSufficientCashBalance).not.toHaveBeenCalled();
      expect(prisma.cashWalletTransaction.create).not.toHaveBeenCalled();
      expect(referralService.qualifyRewardFromTransaction).not.toHaveBeenCalled();
    });

    it('rejects provider that is not an active PHARMACY', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({
        id: 10n,
        status: 'ACTIVE',
        providerType: 'DOCTOR',
      });

      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          items: [{ productId: 101n, quantity: 1 }],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects invalid, zero, or negative quantities', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({
        id: 10n,
        status: 'ACTIVE',
        providerType: 'PHARMACY',
      });
      prisma.product.findMany.mockResolvedValue([
        { id: 101n, sellingPrice: 250.0, productName: 'Vitamin C', status: 'ACTIVE' },
      ]);

      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          items: [{ productId: 101n, quantity: -2 }],
        }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          items: [{ productId: 101n, quantity: 1.5 }],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects product with missing or zero authoritative price', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({
        id: 10n,
        status: 'ACTIVE',
        providerType: 'PHARMACY',
      });
      prisma.product.findMany.mockResolvedValue([
        { id: 102n, sellingPrice: 0, mrp: null, productName: 'Free Product', status: 'ACTIVE' },
      ]);

      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          items: [{ productId: 102n, quantity: 1 }],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('returns existing order when idempotencyKey matches', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({
        id: 10n,
        status: 'ACTIVE',
        providerType: 'PHARMACY',
      });
      prisma.purchase.findFirst.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        invoiceNumber: 'ORD-KEY-abc123idempotentKey',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
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

    it('creates exactly ONE Purchase row when two concurrent requests use the SAME idempotency key', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({
        id: 10n,
        status: 'ACTIVE',
        providerType: 'PHARMACY',
      });
      prisma.product.findMany.mockResolvedValue([
        { id: 101n, sellingPrice: 250.0, mrp: 300.0, productName: 'Vitamin C', status: 'ACTIVE' },
      ]);
      prisma.purchase.findFirst.mockResolvedValue(null);
      prisma.purchase.create.mockImplementation(async () => {
        await new Promise((resolve) => setTimeout(resolve, 50));
        return {
          id: 501n,
          customerId: 1n,
          providerId: 10n,
          invoiceNumber: 'ORD-KEY-concurrentKey123',
          orderStatus: 'PLACED',
          paymentStatus: 'PENDING',
          payableAmount: 250.0,
          provider: { providerName: 'Hyperpharmacy Main' },
          purchaseItems: [],
        };
      });

      const [res1, res2] = await Promise.all([
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          items: [{ productId: 101n, quantity: 1 }],
          idempotencyKey: 'concurrentKey123',
        }),
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          items: [{ productId: 101n, quantity: 1 }],
          idempotencyKey: 'concurrentKey123',
        }),
      ]);

      expect(res1.id).toBe('501');
      expect(res2.id).toBe('501');
      expect(prisma.purchase.create).toHaveBeenCalledTimes(1);
    });
  });

  describe('listPharmacyOrders Provider Isolation', () => {
    it('queries purchaseKind CUSTOMER_ORDER filtered by ProviderScopeService', async () => {
      prisma.purchase.findMany.mockResolvedValue([]);
      await service.listPharmacyOrders({ principalType: 'USER', roleCode: 'PHARMACY_PROVIDER' } as any);

      expect(providerScopeService.scopePurchaseWhere).toHaveBeenCalledWith(
        { purchaseKind: 'CUSTOMER_ORDER' },
        expect.anything(),
      );
    });
  });

  describe('updateOrderStatus', () => {
    it('updates orderStatus ONLY and leaves paymentStatus unchanged', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
      });
      prisma.purchase.update.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
        orderStatus: 'READY',
        paymentStatus: 'PENDING',
        provider: { providerName: 'Hyperpharmacy Main' },
        purchaseItems: [],
      });

      const updated = await service.updateOrderStatus(501n, 'READY', {
        principalType: 'USER',
        userId: '20',
      } as any);

      expect(providerScopeService.assertProviderCanAccessPurchase).toHaveBeenCalledWith(
        501n,
        expect.anything(),
      );
      expect(prisma.purchase.update).toHaveBeenCalledWith({
        where: { id: 501n },
        data: { orderStatus: 'READY' },
        include: expect.anything(),
      });
      expect(updated.orderStatus).toBe('READY');
      expect(updated.paymentStatus).toBe('PENDING');
    });

    it('throws ForbiddenException when provider scope check on purchase fails', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        providerId: 10n,
      });
      providerScopeService.assertProviderCanAccessPurchase.mockRejectedValue(
        new ForbiddenException('You are not authorized to access this purchase or order.'),
      );

      await expect(
        service.updateOrderStatus(501n, 'ACCEPTED', {
          principalType: 'USER',
          userId: '99',
        } as any),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('PharmacyController Principal Authorization', () => {
    let controller: PharmacyController;

    beforeEach(() => {
      controller = new PharmacyController(service, providerScopeService);
    });

    it('rejects Non-Customer principals (Agent, Provider, Admin) on POST /customer/orders', async () => {
      const agentPrincipal = { principalType: 'USER', userType: 'AGENT', userId: '10' } as any;
      const providerPrincipal = { principalType: 'USER', userType: 'SERVICE_PROVIDER', userId: '20' } as any;
      const adminPrincipal = { principalType: 'USER', userType: 'STAFF', userId: '1' } as any;

      await expect(
        controller.createCustomerOrder({ provider_id: '10', items: [{ productId: '101', quantity: 1 }] }, agentPrincipal),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        controller.createCustomerOrder({ provider_id: '10', items: [{ productId: '101', quantity: 1 }] }, providerPrincipal),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        controller.createCustomerOrder({ provider_id: '10', items: [{ productId: '101', quantity: 1 }] }, adminPrincipal),
      ).rejects.toThrow(ForbiddenException);
    });

    it('allows CUSTOMER principal on POST /customer/orders', async () => {
      const customerPrincipal = { principalType: 'CUSTOMER', customerId: '1' } as any;
      jest.spyOn(service, 'createCustomerOrder').mockResolvedValue({ id: '501' } as any);

      const res = await controller.createCustomerOrder(
        { provider_id: '10', items: [{ productId: '101', quantity: 1 }] },
        customerPrincipal,
      );

      expect(res.success).toBe(true);
      expect(res.data.id).toBe('501');
    });
  });
});
