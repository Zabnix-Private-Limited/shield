import { CustomerController } from './customer.controller';

describe('CustomerController card scope', () => {
  const service = {
    getCardProfile: jest.fn(),
    requestPhysicalCard: jest.fn(),
    saveAlternativeContact: jest.fn(),
    listAlternativeContacts: jest.fn(),
    removeAlternativeContact: jest.fn(),
    search: jest.fn(),
    findExistingCustomerByMobile: jest.fn(),
  };
  const agentScope = { assertAgentCanAccessCustomer: jest.fn() };
  const providerScope = { assertProviderCanAccessCustomer: jest.fn() };
  const controller = new CustomerController(
    service as any,
    agentScope as any,
    providerScope as any,
  );
  const customer = {
    principalType: 'CUSTOMER',
    customerId: '11',
  } as any;

  beforeEach(() => jest.clearAllMocks());

  it('rejects a customer reading another customer card profile', async () => {
    await expect(controller.cardProfile('12', customer)).rejects.toThrow(
      'Customers can only access their own customer record.',
    );
    expect(service.getCardProfile).not.toHaveBeenCalled();
  });

  it('rejects a customer requesting another customer physical card', async () => {
    await expect(controller.requestCard('12', customer)).rejects.toThrow(
      'Customers can only access their own customer record.',
    );
    expect(service.requestPhysicalCard).not.toHaveBeenCalled();
  });

  it('rejects a customer saving another customer alternative contact', async () => {
    await expect(
      controller.saveAlternativeContact(
        '12',
        { mobile: '9876543210' },
        customer,
      ),
    ).rejects.toThrow('Customers can only access their own customer record.');
    expect(service.saveAlternativeContact).not.toHaveBeenCalled();
  });

  it('rejects a customer reading another customer alternative contacts', async () => {
    await expect(
      controller.listAlternativeContacts('12', customer),
    ).rejects.toThrow('Customers can only access their own customer record.');
    expect(service.listAlternativeContacts).not.toHaveBeenCalled();
  });

  it('rejects customer access to staff customer lookup endpoints', async () => {
    await expect(
      controller.search(
        '9876543210',
        undefined,
        undefined,
        undefined,
        customer,
      ),
    ).rejects.toThrow('Customer search is not available to customer accounts.');
    await expect(
      controller.existingByMobile('9876543210', customer),
    ).rejects.toThrow('Customer lookup is not available to customer accounts.');
    expect(service.search).not.toHaveBeenCalled();
    expect(service.findExistingCustomerByMobile).not.toHaveBeenCalled();
  });

  it('rejects a customer removing another customer alternative contact', async () => {
    await expect(
      controller.removeAlternativeContact('12', '7', customer),
    ).rejects.toThrow('Customers can only access their own customer record.');
    expect(service.removeAlternativeContact).not.toHaveBeenCalled();
  });
});
