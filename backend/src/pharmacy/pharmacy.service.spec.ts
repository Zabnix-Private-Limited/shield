import { PharmacyService } from './pharmacy.service';

describe('PharmacyService customer wellness catalogue', () => {
  it('returns only customer-safe production fields with pagination metadata', async () => {
    const product = {
      id: BigInt(1), productCode: 'WELLNESS-1', productName: 'Vitamin A',
      brand: 'Sample', unit: '1 pack', mrp: { toString: () => '100' },
      sellingPrice: { toString: () => '90' }, dataSource: 'CATALOGUE',
      category: { id: BigInt(2), name: 'Vitamins' }, costPrice: { toString: () => '40' },
    };
    const prisma = {
      product: { count: jest.fn().mockResolvedValue(1), findMany: jest.fn().mockResolvedValue([product]) },
      productCategory: { findMany: jest.fn().mockResolvedValue([{ id: BigInt(2), name: 'Vitamins' }]) },
      $transaction: jest.fn(async (queries: Promise<unknown>[]) => Promise.all(queries)),
    };
    const service = new PharmacyService(prisma as any, {} as any, {} as any, {} as any, {} as any);

    await expect(service.listCustomerWellnessProducts({ page: '1', pageSize: '24' })).resolves.toEqual({
      items: [{
        id: '1', productCode: 'WELLNESS-1', productName: 'Vitamin A', brand: 'Sample',
        unit: '1 pack', mrp: 100, sellingPrice: 90,
        category: { id: '2', name: 'Vitamins' }, catalogueKind: 'STANDARD',
        purchasable: true,
        purchasabilityReason: null,
      }],
      pagination: { page: 1, pageSize: 24, total: 1, totalPages: 1 },
      categories: [{ id: '2', name: 'Vitamins' }],
      disclosure: null,
    });
  });

  it('projects only the authenticated customer order and excludes internal fields', async () => {
    const purchase = {
      id: BigInt(9), invoiceNumber: 'INV-9', orderStatus: 'PLACED',
      paymentStatus: 'PENDING', totalAmount: { toString: () => '100' },
      payableAmount: { toString: () => '90' }, purchaseDate: new Date('2026-08-08T10:00:00Z'),
      provider: { providerName: 'Safe Pharmacy', business: { name: 'Safe Business' } },
      purchaseItems: [{
        id: BigInt(4), productId: BigInt(3), itemName: null,
        quantity: { toString: () => '2' }, unitPrice: { toString: () => '45' },
        totalPrice: { toString: () => '90' }, product: { productName: 'Vitamin A', costPrice: 10 },
      }],
      paymentSummary: { gatewaySecret: 'must-not-leak' },
      billingSnapshot: { internalNote: 'must-not-leak' },
    };
    const prisma = {
      purchase: { findMany: jest.fn().mockResolvedValue([purchase]) },
    };
    const service = new PharmacyService(prisma as any, {} as any, {} as any, {} as any, {} as any);

    await expect(service.listCustomerOrders(BigInt(7))).resolves.toEqual([{
      id: '9', invoiceNumber: 'INV-9', orderStatus: 'PLACED', paymentStatus: 'PENDING',
      totalAmount: 100, payableAmount: 90, purchaseDate: new Date('2026-08-08T10:00:00Z'),
      providerName: 'Safe Business',
      items: [{ id: '4', productId: '3', name: 'Vitamin A', quantity: 2, unitPrice: 45, lineTotal: 90 }],
    }]);
    expect(prisma.purchase.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { customerId: BigInt(7) },
    }));
  });

  it('does not disclose another customer order', async () => {
    const prisma = { purchase: { findFirst: jest.fn().mockResolvedValue(null) } };
    const service = new PharmacyService(prisma as any, {} as any, {} as any, {} as any, {} as any);

    await expect(service.getCustomerOrder(BigInt(7), BigInt(9))).rejects.toThrow('Order not found.');
    expect(prisma.purchase.findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: BigInt(9), customerId: BigInt(7) },
    }));
  });
});
