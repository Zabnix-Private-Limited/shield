import { PharmacyController } from './pharmacy.controller';

describe('PharmacyController customer wellness catalogue', () => {
  const pharmacyService = {
    listWellnessDemoProducts: jest.fn(),
    listPurchases: jest.fn(),
  };
  const providerScope = { assertProviderCanAccessCustomer: jest.fn() };
  const controller = new PharmacyController(
    pharmacyService as any,
    providerScope as any,
  );

  beforeEach(() => jest.clearAllMocks());

  it('returns only seeded demo products to an authenticated customer', async () => {
    pharmacyService.listWellnessDemoProducts.mockResolvedValue([{ id: 1 }]);

    await expect(
      controller.listCustomerWellnessProducts({
        principalType: 'CUSTOMER',
        customerId: '7',
      } as any),
    ).resolves.toMatchObject({ data: [{ id: 1 }] });
  });

  it('rejects non-customer principals', async () => {
    await expect(
      controller.listCustomerWellnessProducts({ principalType: 'USER' } as any),
    ).rejects.toThrow('Only authenticated customers');
  });

  it('fails closed when a customer purchase request has no customer context', async () => {
    await expect(
      controller.listPurchases(undefined, { principalType: 'CUSTOMER' } as any),
    ).rejects.toThrow('Authenticated customer context is required.');
    expect(pharmacyService.listPurchases).not.toHaveBeenCalled();
  });
});
