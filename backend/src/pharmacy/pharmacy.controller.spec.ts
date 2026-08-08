import { PharmacyController } from './pharmacy.controller';

describe('PharmacyController customer wellness catalogue', () => {
  const pharmacyService = {
    listWellnessProducts: jest.fn(),
    listCustomerWellnessProducts: jest.fn(),
    getCustomerWellnessProduct: jest.fn(),
    listPurchases: jest.fn(),
    listCustomerOrders: jest.fn(),
    getCustomerOrder: jest.fn(),
    createCustomerPrescriptionRequest: jest.fn(),
    listCustomerPrescriptionRequests: jest.fn(),
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
      controller.listCustomerWellnessProducts(
        {
          principalType: 'CUSTOMER',
          customerId: '7',
        } as any,
        'vitamin',
        '2',
        '3',
        '12',
      ),
    ).resolves.toMatchObject({ data: { items: [{ id: '1' }] } });
    expect(pharmacyService.listCustomerWellnessProducts).toHaveBeenCalledWith({
      query: 'vitamin',
      categoryId: '2',
      page: '3',
      pageSize: '12',
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

  it('submits a pharmacy request using the authenticated customer identity', async () => {
    pharmacyService.createCustomerPrescriptionRequest.mockResolvedValue({
      id: '9',
      status: 'SUBMITTED',
      prescription: { id: '4', title: 'prescription.pdf' },
      pharmacy: { id: '8', name: 'Active Pharmacy' },
    });

    await expect(
      controller.submitCustomerPrescription(
        { document_id: '4', provider_id: '8', customer_notes: 'Please review' },
        { principalType: 'CUSTOMER', customerId: '7' } as any,
      ),
    ).resolves.toMatchObject({ data: { id: '9', status: 'SUBMITTED' } });
    expect(
      pharmacyService.createCustomerPrescriptionRequest,
    ).toHaveBeenCalledWith(
      expect.objectContaining({
        customerId: BigInt(7),
        documentId: BigInt(4),
        providerId: BigInt(8),
        customerNotes: 'Please review',
      }),
    );
  });

  it('rejects pharmacy submission without a customer session', async () => {
    await expect(
      controller.submitCustomerPrescription(
        { document_id: '4', provider_id: '8' },
        { principalType: 'USER' } as any,
      ),
    ).rejects.toThrow('Authenticated customer context is required.');
  });

  it('lists only the authenticated customer request archive', async () => {
    pharmacyService.listCustomerPrescriptionRequests.mockResolvedValue([
      { id: '9', status: 'SUBMITTED' },
    ]);

    await expect(
      controller.listCustomerPrescriptionRequests({
        principalType: 'CUSTOMER',
        customerId: '7',
      } as any),
    ).resolves.toMatchObject({ data: [{ id: '9' }] });
    expect(
      pharmacyService.listCustomerPrescriptionRequests,
    ).toHaveBeenCalledWith(BigInt(7));
  });

  it('lists orders using the authenticated customer identity only', async () => {
    pharmacyService.listCustomerOrders.mockResolvedValue([{ id: '9' }]);

    await expect(
      controller.listCustomerOrders({ principalType: 'CUSTOMER', customerId: '7' } as any),
    ).resolves.toMatchObject({ data: [{ id: '9' }] });
    expect(pharmacyService.listCustomerOrders).toHaveBeenCalledWith(BigInt(7));
  });

  it('rejects cross-customer order access without a customer session', async () => {
    await expect(
      controller.getCustomerOrder('9', { principalType: 'USER' } as any),
    ).rejects.toThrow('Authenticated customer context is required.');
    expect(pharmacyService.getCustomerOrder).not.toHaveBeenCalled();
  });
});
