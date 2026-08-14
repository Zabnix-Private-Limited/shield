import { CustomerSupportController } from './support.controller';

describe('CustomerSupportController', () => {
  const service = {
    listForCustomer: jest.fn(),
    getForCustomer: jest.fn(),
    submitForCustomer: jest.fn(),
  };
  const controller = new CustomerSupportController(service as any);
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('derives support history ownership from the authenticated customer', async () => {
    service.listForCustomer.mockResolvedValue([]);
    await controller.list(customer);
    expect(service.listForCustomer).toHaveBeenCalledWith(11n);
  });

  it('submits support only for the authenticated customer', async () => {
    service.submitForCustomer.mockResolvedValue({ id: 1n });
    await controller.submit(
      { message: 'Need help', subject: 'Membership' },
      customer,
    );
    expect(service.submitForCustomer).toHaveBeenCalledWith(11n, {
      message: 'Need help',
      subject: 'Membership',
      complaintType: undefined,
    });
  });

  it('rejects a non-customer principal', async () => {
    await expect(
      controller.list({ principalType: 'USER' } as any),
    ).rejects.toThrow('Authenticated customer context is required');
  });

  it('loads support detail only through the authenticated customer ownership projection', async () => {
    service.getForCustomer.mockResolvedValue({
      id: 5n,
      lifecycleEvents: [{ eventType: 'CUSTOMER_REPLY_ADDED', customerVisible: true }],
    });
    await controller.detail('5', customer);
    expect(service.getForCustomer).toHaveBeenCalledWith(11n, 5n);
  });

  it('does not treat an absent cross-customer detail as a successful response', async () => {
    service.getForCustomer.mockResolvedValue(null);
    await expect(controller.detail('99', customer)).rejects.toThrow(
      'Support request not found',
    );
  });
});
