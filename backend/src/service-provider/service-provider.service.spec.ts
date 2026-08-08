import { ServiceProviderService } from './service-provider.service';

describe('ServiceProviderService customer directory projection', () => {
  const prisma = {
    serviceProvider: {
      count: jest.fn(),
      findMany: jest.fn(),
    },
    $transaction: jest.fn(),
  };
  const service = new ServiceProviderService(
    prisma as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
  );

  beforeEach(() => jest.clearAllMocks());

  it('projects only customer-safe fields and excludes inactive providers', async () => {
    const provider = {
      id: 7n,
      providerName: 'Active Pharmacy',
      providerType: 'PHARMACY',
      business: { name: 'SHIELD Health' },
      internalCost: 1000,
      commission: 12,
      settlement: { account: 'private' },
      credentials: 'private',
      internalNotes: 'private',
    };
    prisma.$transaction.mockResolvedValue([1, [provider]]);

    const result = await service.listCustomerProviders({ page: '1' });

    expect(result.items).toEqual([
      {
        id: '7',
        name: 'Active Pharmacy',
        type: 'PHARMACY',
        typeLabel: 'Pharmacy',
        businessName: 'SHIELD Health',
        availability: 'ACTIVE',
        availabilityLabel: 'Active provider',
      },
    ]);
    expect(Object.keys(result.items[0])).not.toEqual(
      expect.arrayContaining([
        'internalCost',
        'commission',
        'settlement',
        'credentials',
        'internalNotes',
      ]),
    );
    expect(prisma.serviceProvider.count).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ status: 'ACTIVE' }),
      }),
    );
  });
});
