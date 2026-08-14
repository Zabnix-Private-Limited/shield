import { CustomerSupportController } from './support.controller';

describe('CustomerSupportController', () => {
  const service = { listForCustomer: jest.fn(), submitForCustomer: jest.fn() };
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
});
