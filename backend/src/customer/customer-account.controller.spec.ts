import { CustomerAccountController } from './customer-account.controller';

describe('CustomerAccountController', () => {
  const service = {
    getCustomerSelfProfile: jest.fn(),
    updateCustomerSelfProfile: jest.fn(),
    listAddresses: jest.fn(),
    saveAddress: jest.fn(),
    removeAddress: jest.fn(),
    listDependents: jest.fn(),
    saveDependent: jest.fn(),
    removeDependent: jest.fn(),
    listContacts: jest.fn(),
    saveContact: jest.fn(),
    removeContact: jest.fn(),
    getPreferences: jest.fn(),
    savePreferences: jest.fn(),
    listEligiblePharmacies: jest.fn(),
    getPreferredProvider: jest.fn(),
    setPreferredProvider: jest.fn(),
  };
  const controller = new CustomerAccountController(service as any);
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('derives address ownership from the customer principal', async () => {
    service.saveAddress.mockResolvedValue({ id: 7n });

    await controller.createAddress(
      { customerId: '99', addressLine1: 'QA Address' },
      customer,
    );

    expect(service.saveAddress).toHaveBeenCalledWith(
      11n,
      expect.objectContaining({ customerId: '99', addressLine1: 'QA Address' }),
    );
    expect(service.saveAddress).not.toHaveBeenCalledWith(
      99n,
      expect.anything(),
    );
  });

  it('derives profile ownership from the customer principal', async () => {
    service.getCustomerSelfProfile.mockResolvedValue({ id: 11n });
    service.updateCustomerSelfProfile.mockResolvedValue({ id: 11n });

    await controller.profile(customer);
    await controller.updateProfile(
      { firstName: 'Asha', status: 'APPROVED', mobile: '9999999999' },
      customer,
    );

    expect(service.getCustomerSelfProfile).toHaveBeenCalledWith(11n);
    expect(service.updateCustomerSelfProfile).toHaveBeenCalledWith(11n, {
      firstName: 'Asha',
      status: 'APPROVED',
      mobile: '9999999999',
    });
  });

  it('rejects a missing or non-customer principal before resource access', async () => {
    await expect(controller.addresses(undefined)).rejects.toThrow(
      'Customer session required.',
    );
    await expect(
      controller.dependents({ principalType: 'USER', customerId: '11' } as any),
    ).rejects.toThrow('Customer session required.');
    expect(service.listAddresses).not.toHaveBeenCalled();
    expect(service.listDependents).not.toHaveBeenCalled();
  });

  it('scopes destructive resources to the authenticated customer', async () => {
    service.removeAddress.mockResolvedValue(undefined);
    service.removeDependent.mockResolvedValue(undefined);
    service.removeContact.mockResolvedValue(undefined);

    await controller.removeAddress('7', customer);
    await controller.removeDependent('8', customer);
    await controller.removeContact('9', customer);

    expect(service.removeAddress).toHaveBeenCalledWith(11n, 7n);
    expect(service.removeDependent).toHaveBeenCalledWith(11n, 8n);
    expect(service.removeContact).toHaveBeenCalledWith(11n, 9n);
  });

  it('rejects malformed resource and provider IDs', async () => {
    await expect(
      controller.removeAddress('not-an-id', customer),
    ).rejects.toThrow('Invalid resource id.');
    await expect(
      controller.setPreferredProvider({ providerId: 'other' }, customer),
    ).rejects.toThrow('Invalid resource id.');
    expect(service.removeAddress).not.toHaveBeenCalled();
    expect(service.setPreferredProvider).not.toHaveBeenCalled();
  });

  it('uses the authenticated customer for preferences and pharmacy selection', async () => {
    service.savePreferences.mockResolvedValue({ id: 3n });
    service.setPreferredProvider.mockResolvedValue({ id: 3n });

    await controller.updatePreferences({ language: 'en' }, customer);
    await controller.setPreferredProvider(
      { providerId: '5', customerId: '99' },
      customer,
    );

    expect(service.savePreferences).toHaveBeenCalledWith(11n, {
      language: 'en',
    });
    expect(service.setPreferredProvider).toHaveBeenCalledWith(11n, 5n);
  });
});
