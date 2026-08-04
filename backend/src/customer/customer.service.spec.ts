import { CustomerService } from './customer.service';

describe('CustomerService alternative contacts', () => {
  const prisma = {
    customerContact: {
      findMany: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
    },
  };
  const service = new CustomerService(
    prisma as any,
    {} as any,
    {} as any,
    {} as any,
  );

  beforeEach(() => jest.clearAllMocks());

  it('matches an existing contact despite mobile formatting differences', async () => {
    jest
      .spyOn(service, 'findOne')
      .mockResolvedValue({ mobile: '9876500000' } as any);
    prisma.customerContact.findMany.mockResolvedValue([
      { id: 7n, mobile: '+91 98765-43210' },
    ]);
    prisma.customerContact.update.mockResolvedValue({
      id: 7n,
      mobile: '+91 98765-43210',
    });

    await service.saveAlternativeContact(1n, {
      mobile: '9876543210',
      name: 'Backup Contact',
    });

    expect(prisma.customerContact.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 7n } }),
    );
    expect(prisma.customerContact.create).not.toHaveBeenCalled();
  });
});
