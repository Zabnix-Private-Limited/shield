import { PharmacyService } from './pharmacy.service';

describe('PharmacyService customer wellness catalogue', () => {
  it('returns only customer-safe demo fields with pagination metadata', async () => {
    const product = {
      id: BigInt(1), productCode: 'LEGACY-XLS-1', productName: 'Vitamin A',
      brand: 'Sample', unit: '1 pack', mrp: { toString: () => '100' },
      sellingPrice: { toString: () => '90' }, dataSource: 'LEGACY_XLS_20260805',
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
        id: '1', productCode: 'LEGACY-XLS-1', productName: 'Vitamin A', brand: 'Sample',
        unit: '1 pack', mrp: 100, sellingPrice: 90,
        category: { id: '2', name: 'Vitamins' }, catalogueKind: 'DEMO',
      }],
      pagination: { page: 1, pageSize: 24, total: 1, totalPages: 1 },
      categories: [{ id: '2', name: 'Vitamins' }],
      disclosure: 'Demo products only — not live Sahakar inventory.',
    });
  });
});
