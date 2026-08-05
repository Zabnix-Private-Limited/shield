import { PharmacyController } from './pharmacy.controller';

describe('PharmacyController customer wellness catalogue', () => {
  const pharmacyService = {
    listWellnessProducts: jest.fn(),
    listCustomerWellnessProducts: jest.fn(),
    getCustomerWellnessProduct: jest.fn(),
    listPurchases: jest.fn(),
  };
  const providerScope = { assertProviderCanAccessCustomer: jest.fn() };
  const controller = new PharmacyController(
    pharmacyService as any,
    providerScope as any,
  );

  beforeEach(() => jest.clearAllMocks());

  it('returns active catalogue products to an authenticated customer', async () => {
    pharmacyService.listCustomerWellnessProducts.mockResolvedValue({
      items: [{ id: '1', catalogueKind: 'DEMO' }],
    });

    await expect(
      controller.listCustomerWellnessProducts({
        principalType: 'CUSTOMER',
        customerId: '7',
      } as any, 'vitamin', '2', '3', '12'),
    ).resolves.toMatchObject({ data: { items: [{ id: '1' }] } });
    expect(pharmacyService.listCustomerWellnessProducts).toHaveBeenCalledWith({
      query: 'vitamin', categoryId: '2', page: '3', pageSize: '12',
    });
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
