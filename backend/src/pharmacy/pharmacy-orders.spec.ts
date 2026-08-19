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
      $queryRawUnsafe: jest.fn(),
      $executeRawUnsafe: jest.fn(),
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
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
        count: jest.fn().mockResolvedValue(0),
        aggregate: jest.fn(),
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
      {
        persistScopedPrivateObject: jest.fn(),
        readObjectBuffer: jest.fn(),
        deletePrivateObject: jest.fn().mockResolvedValue(true),
        validateContentSignature: jest.fn().mockReturnValue({ isValid: true, detectedMime: 'application/pdf' }),
      } as any,
      { send: jest.fn() } as any,
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

      expect(providerScopeService.scopePurchaseWhere).toHaveBeenCalled();
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
        orderStatus: 'ACCEPTED',
        paymentStatus: 'PENDING',
        provider: { providerName: 'Hyperpharmacy Main' },
        purchaseItems: [],
      });

      const updated = await service.updateOrderStatus(501n, 'ACCEPTED', undefined, {
        principalType: 'USER',
        userId: '20',
      } as any);

      expect(providerScopeService.assertProviderCanAccessPurchase).toHaveBeenCalled();
      expect(prisma.purchase.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 501n },
          data: expect.objectContaining({ orderStatus: 'ACCEPTED' }),
        }),
      );
      expect(updated.status).toBe('ACCEPTED');
      expect(updated.paymentStatus).toBe('PENDING');
    });

    it('rejects invalid jump from PLACED directly to READY', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        orderStatus: 'PLACED',
      });

      await expect(
        service.updateOrderStatus(501n, 'READY', undefined, {
          principalType: 'USER',
          userId: '20',
        } as any),
      ).rejects.toThrow('Invalid order status transition from PLACED to READY.');
    });

    it('rejects backward transition from READY to PREPARING', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        orderStatus: 'READY',
      });

      await expect(
        service.updateOrderStatus(501n, 'PREPARING', undefined, {
          principalType: 'USER',
          userId: '20',
        } as any),
      ).rejects.toThrow('Invalid order status transition from READY to PREPARING.');
    });

    it('rejects dispatching order with null or non-HOME_DELIVERY fulfillment preference for delivery', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        orderStatus: 'READY',
        billingSnapshot: { fulfillmentPreference: null },
      });

      await expect(
        service.updateOrderStatus(501n, 'OUT_FOR_DELIVERY', undefined, {
          principalType: 'USER',
          userId: '20',
        } as any),
      ).rejects.toThrow('Invalid order status transition from READY to OUT_FOR_DELIVERY.');
    });

    it('rejects dispatching COLLECT_FROM_PHARMACY order for delivery', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        orderStatus: 'READY',
        billingSnapshot: { fulfillmentPreference: 'COLLECT_FROM_PHARMACY' },
      });

      await expect(
        service.updateOrderStatus(501n, 'OUT_FOR_DELIVERY', undefined, {
          principalType: 'USER',
          userId: '20',
        } as any),
      ).rejects.toThrow('Orders with COLLECT_FROM_PHARMACY fulfillment preference cannot be dispatched for delivery.');
    });

    it('returns existing order on idempotent same-status retry without update', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        orderStatus: 'COMPLETED',
        paymentStatus: 'COMPLETED',
        billingSnapshot: {},
      });

      const res = await service.updateOrderStatus(501n, 'COMPLETED', undefined, {
        principalType: 'USER',
        userId: '20',
      } as any);

      expect(res.status).toBe('COMPLETED');
      expect(prisma.purchase.update).not.toHaveBeenCalled();
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
        service.updateOrderStatus(501n, 'ACCEPTED', undefined, {
          principalType: 'USER',
          userId: '99',
        } as any),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('listPharmacyOrderHistory & getPharmacyOrderHistoryDetail (Phase 4)', () => {
    it('queries terminal statuses (COMPLETED, CANCELLED, REJECTED) and enforces provider scope', async () => {
      prisma.purchase.count.mockResolvedValue(1);
      prisma.purchase.findMany.mockResolvedValue([
        {
          id: 701n,
          invoiceNumber: 'ORD-701',
          orderStatus: 'COMPLETED',
          payableAmount: 450.0,
          purchaseDate: new Date(),
          customer: { id: 10n, firstName: 'Alice', lastName: 'Smith', mobile: '9876543210', customerCode: 'CUST-10' },
          provider: { providerName: 'Hyperpharmacy Main' },
          purchaseItems: [],
        },
      ]);
      prisma.purchase.aggregate.mockResolvedValue({ _sum: { payableAmount: 450.0 }, _count: { id: 1 } });

      const res = await service.listPharmacyOrderHistory(
        { status: 'ALL_HISTORY', page: 1, pageSize: 20 },
        { principalType: 'USER', roleCode: 'PHARMACY_PROVIDER' } as any,
      );

      expect(providerScopeService.scopePurchaseWhere).toHaveBeenCalled();
      expect(prisma.purchase.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            orderStatus: expect.objectContaining({
              in: expect.arrayContaining(['COMPLETED', 'CANCELLED', 'REJECTED']),
            }),
          }),
          take: 20,
          skip: 0,
        }),
      );
      expect(res.items.length).toBe(1);
      expect(res.metrics.completedValue).toBe(450.0);
    });

    it('rejects non-terminal active orders when querying history detail', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        orderStatus: 'PLACED', // Active, not terminal history!
      });

      await expect(service.getPharmacyOrderHistoryDetail(501n)).rejects.toThrow(BadRequestException);
    });

    it('returns read-only detail for terminal completed order', async () => {
      prisma.purchase.findUnique.mockResolvedValue({
        id: 701n,
        invoiceNumber: 'ORD-701',
        orderStatus: 'COMPLETED',
        payableAmount: 450.0,
        purchaseDate: new Date(),
        customer: { id: 10n, firstName: 'Alice', lastName: 'Smith', mobile: '9876543210' },
        provider: { providerName: 'Hyperpharmacy Main' },
        purchaseItems: [],
      });

      const res = await service.getPharmacyOrderHistoryDetail(701n);
      expect(res.id).toBe('701');
      expect(res.status).toBe('COMPLETED');
    });
  });

  describe('Phase 5 — Customer Order Creation & Validation', () => {
    it('successfully creates a PRESCRIPTION order with valid prescription document and active pharmacy', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE', providerType: 'PHARMACY' });
      prisma.document = {
        findFirst: jest.fn().mockResolvedValue({ id: 99n, fileName: 'Rx_Doctor_Scan.pdf' }),
      };
      prisma.purchase.create.mockResolvedValue({
        id: 801n,
        invoiceNumber: 'ORD-1234',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
        purchaseKind: 'PRESCRIPTION',
        totalAmount: 0,
        payableAmount: 0,
        purchaseDate: new Date(),
        provider: { id: 10n, providerName: 'City Pharmacy' },
        purchaseItems: [{ id: 1001n, itemName: 'Rx_Doctor_Scan.pdf', quantity: 1, unitPrice: 0, totalPrice: 0 }],
        billingSnapshot: { orderSource: 'PRESCRIPTION', fulfillmentPreference: 'COLLECT_FROM_PHARMACY' },
      });

      const order = await service.createCustomerOrder({
        customerId: 1n,
        providerId: 10n,
        orderSource: 'PRESCRIPTION',
        documentId: 99n,
        fulfillmentPreference: 'COLLECT_FROM_PHARMACY',
      });

      expect(order.id).toBe('801');
      expect(order.orderSource).toBe('PRESCRIPTION');
      expect(order.fulfillmentPreference).toBe('COLLECT_FROM_PHARMACY');
      expect(prisma.purchase.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            customerId: 1n,
            providerId: 10n,
            purchaseKind: 'PRESCRIPTION',
            orderStatus: 'PLACED',
            paymentStatus: 'PENDING',
          }),
        }),
      );
    });

    it('successfully creates a MANUAL_ITEMS order with custom medicine requests', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE', providerType: 'PHARMACY' });
      prisma.purchase.create.mockResolvedValue({
        id: 802n,
        invoiceNumber: 'ORD-5678',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
        purchaseKind: 'MANUAL_ITEMS',
        totalAmount: 0,
        payableAmount: 0,
        purchaseDate: new Date(),
        provider: { id: 10n, providerName: 'City Pharmacy' },
        purchaseItems: [{ id: 1002n, itemName: 'Paracetamol 500mg', quantity: 2, unitPrice: 0, totalPrice: 0 }],
        billingSnapshot: { orderSource: 'MANUAL_ITEMS', fulfillmentPreference: 'HOME_DELIVERY', deliveryAddress: '123 Main St' },
      });

      const order = await service.createCustomerOrder({
        customerId: 1n,
        providerId: 10n,
        orderSource: 'MANUAL_ITEMS',
        items: [{ name: 'Paracetamol 500mg', quantity: 2 }],
        fulfillmentPreference: 'HOME_DELIVERY',
        deliveryAddress: '123 Main St',
      });

      expect(order.id).toBe('802');
      expect(order.orderSource).toBe('MANUAL_ITEMS');
      expect(order.fulfillmentPreference).toBe('HOME_DELIVERY');
      expect(order.deliveryAddress).toBe('123 Main St');
    });

    it('successfully creates a WELLNESS order with active catalogue products', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE', providerType: 'PHARMACY' });
      prisma.product.findMany.mockResolvedValue([
        { id: 201n, productName: 'Vitamin C 500mg', status: 'ACTIVE', sellingPrice: 150, mrp: 200 },
      ]);
      prisma.purchase.create.mockResolvedValue({
        id: 803n,
        invoiceNumber: 'ORD-9012',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
        purchaseKind: 'WELLNESS',
        totalAmount: 300,
        payableAmount: 300,
        purchaseDate: new Date(),
        provider: { id: 10n, providerName: 'City Pharmacy' },
        purchaseItems: [{ id: 1003n, productId: 201n, itemName: 'Vitamin C 500mg', quantity: 2, unitPrice: 150, totalPrice: 300 }],
        billingSnapshot: { orderSource: 'WELLNESS', fulfillmentPreference: 'COLLECT_FROM_PHARMACY' },
      });

      const order = await service.createCustomerOrder({
        customerId: 1n,
        providerId: 10n,
        orderSource: 'WELLNESS',
        items: [{ productId: 201n, quantity: 2 }],
        fulfillmentPreference: 'COLLECT_FROM_PHARMACY',
      });

      expect(order.id).toBe('803');
      expect(order.orderSource).toBe('WELLNESS');
      expect(order.totalAmount).toBe(300);
      expect(order.payableAmount).toBe(300);
    });

    it('rejects order creation when provider is inactive or not a pharmacy', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'INACTIVE', providerType: 'CLINIC' });

      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          orderSource: 'MANUAL_ITEMS',
          items: [{ name: 'Aspirin', quantity: 1 }],
        }),
      ).rejects.toThrow('Selected provider is unavailable or is not an active pharmacy.');
    });

    it('requires delivery address when HOME_DELIVERY is selected', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE', providerType: 'PHARMACY' });

      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          orderSource: 'MANUAL_ITEMS',
          items: [{ name: 'Aspirin', quantity: 1 }],
          fulfillmentPreference: 'HOME_DELIVERY',
        }),
      ).rejects.toThrow('Delivery address is required for home delivery.');
    });

    it('does not require delivery address when COLLECT_FROM_PHARMACY is selected', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE', providerType: 'PHARMACY' });
      prisma.purchase.create.mockResolvedValue({
        id: 804n,
        invoiceNumber: 'ORD-804',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
        purchaseKind: 'MANUAL_ITEMS',
        totalAmount: 0,
        payableAmount: 0,
        purchaseDate: new Date(),
        provider: { id: 10n, providerName: 'City Pharmacy' },
        purchaseItems: [],
        billingSnapshot: { orderSource: 'MANUAL_ITEMS', fulfillmentPreference: 'COLLECT_FROM_PHARMACY' },
      });

      const order = await service.createCustomerOrder({
        customerId: 1n,
        providerId: 10n,
        orderSource: 'MANUAL_ITEMS',
        items: [{ name: 'Aspirin', quantity: 1 }],
        fulfillmentPreference: 'COLLECT_FROM_PHARMACY',
      });

      expect(order.id).toBe('804');
      expect(order.fulfillmentPreference).toBe('COLLECT_FROM_PHARMACY');
    });

    it('rejects wellness products that are inactive or unorderable', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE', providerType: 'PHARMACY' });
      prisma.product.findMany.mockResolvedValue([
        { id: 202n, productName: 'Unpublished Item', status: 'INACTIVE', sellingPrice: null, mrp: null },
      ]);

      await expect(
        service.createCustomerOrder({
          customerId: 1n,
          providerId: 10n,
          orderSource: 'WELLNESS',
          items: [{ productId: 202n, quantity: 1 }],
        }),
      ).rejects.toThrow('unavailable, inactive, or missing a valid orderable price');
    });

    it('re-uses existing order idempotently when identical idempotency key is submitted twice', async () => {
      prisma.serviceProvider.findUnique.mockResolvedValue({ id: 10n, status: 'ACTIVE', providerType: 'PHARMACY' });
      prisma.purchase.findFirst.mockResolvedValue({
        id: 805n,
        invoiceNumber: 'ORD-KEY-idem-12345',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
        purchaseKind: 'MANUAL_ITEMS',
        totalAmount: 0,
        payableAmount: 0,
        purchaseDate: new Date(),
        provider: { id: 10n, providerName: 'City Pharmacy' },
        purchaseItems: [],
        billingSnapshot: { orderSource: 'MANUAL_ITEMS', fulfillmentPreference: 'COLLECT_FROM_PHARMACY' },
      });

      const order = await service.createCustomerOrder({
        customerId: 1n,
        providerId: 10n,
        orderSource: 'MANUAL_ITEMS',
        items: [{ name: 'Aspirin', quantity: 1 }],
        idempotencyKey: 'idem-12345',
      });

      expect(order.id).toBe('805');
      expect(prisma.purchase.create).not.toHaveBeenCalled();
    });
  });

  describe('PharmacyController Principal Authorization', () => {
    let controller: PharmacyController;

    beforeEach(() => {
      controller = new PharmacyController(
        service as any,
        {} as any,
        {} as any,
        providerScopeService as any,
      );
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

  describe('Pharmacy Security, Provider Resolution & Invoice Hardening', () => {
    it('authoritatively maps user.branchBusinessId (Business.id=20) to ServiceProvider.id=105', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 10n,
        branchBusinessId: 20n,
        firstName: 'Pharma',
        lastName: 'Admin',
        email: 'admin@pharma.org',
        mobile: '9876543210',
        status: 'ACTIVE',
        createdAt: new Date(),
        lastLoginAt: null,
      });

      prisma.serviceProvider.findFirst.mockResolvedValue({
        id: 105n,
        businessId: 20n,
        providerType: 'PHARMACY',
        status: 'ACTIVE',
        providerName: 'Shield Health Pharmacy',
        business: { id: 20n, code: 'PHARM-20', name: 'Shield Health' },
      });

      const principal = { principalType: 'USER', userId: '10', roleCode: 'PHARMACY_PROVIDER' } as any;
      const profile = await service.getPharmacyProfile(principal);

      expect(prisma.serviceProvider.findFirst).toHaveBeenCalledWith({
        where: {
          businessId: 20n,
          providerType: 'PHARMACY',
          status: 'ACTIVE',
        },
        include: { business: true },
      });

      expect(profile.pharmacyName).toBe('Shield Health Pharmacy');
      expect(profile.businessCode).toBe('PHARM-20');
      expect(profile.lastLoginAt).toBeNull();
    });

    it('fails closed on invoice upload when assertProviderCanAccessPurchase throws ForbiddenException', async () => {
      providerScopeService.assertProviderCanAccessPurchase.mockRejectedValue(
        new ForbiddenException('You are not authorized to access this purchase or order.'),
      );

      const file = {
        originalname: 'invoice.pdf',
        mimetype: 'application/pdf',
        size: 1024,
        buffer: Buffer.from('%PDF-1.4 test bytes'),
      };

      await expect(
        service.uploadOrderInvoiceFile(999n, file, { userId: '10' } as any),
      ).rejects.toThrow(ForbiddenException);
    });

    it('rejects invoice uploads with invalid magic byte signatures', async () => {
      providerScopeService.assertProviderCanAccessPurchase.mockResolvedValue(undefined as any);
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        provider: { status: 'ACTIVE', providerType: 'PHARMACY' },
      });
      (service['storageService'].validateContentSignature as jest.Mock).mockReturnValue({
        isValid: false,
        detectedMime: null,
      });

      const fakePdfFile = {
        originalname: 'malicious.pdf',
        mimetype: 'application/pdf',
        size: 1024,
        buffer: Buffer.from('NOT_A_REAL_PDF_FILE'),
      };

      await expect(
        service.uploadOrderInvoiceFile(501n, fakePdfFile, { userId: '10' } as any),
      ).rejects.toThrow(BadRequestException);
    });

    it('skips duplicate push notification on sendOrderInvoice when invoice is already sent', async () => {
      providerScopeService.assertProviderCanAccessPurchase.mockResolvedValue(undefined as any);
      prisma.purchase.findUnique.mockResolvedValue({
        id: 501n,
        customerId: 1n,
        provider: { status: 'ACTIVE', providerType: 'PHARMACY' },
      });

      prisma.$queryRawUnsafe.mockResolvedValue([
        {
          id: 701n,
          purchase_id: 501n,
          storage_key: 'r2://bucket/invoices/501.pdf',
          file_name: '501.pdf',
          sent_at: new Date(),
        },
      ]);

      jest.spyOn(service, 'getPharmacyOrderDetail').mockResolvedValue({ id: '501' } as any);

      const result = await service.sendOrderInvoice(501n, { userId: '10' } as any);

      expect(result.id).toBe('501');
      expect(prisma.$executeRawUnsafe).not.toHaveBeenCalled();
    });
  });
});
