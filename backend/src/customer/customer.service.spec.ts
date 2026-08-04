import { CustomerService } from './customer.service';

describe('CustomerService alternative contacts', () => {
  const prisma = {
    customerContact: {
      findMany: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      deleteMany: jest.fn(),
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

  it('rejects a short alternative mobile number', async () => {
    jest
      .spyOn(service, 'findOne')
      .mockResolvedValue({ mobile: '9876500000' } as any);

    await expect(
      service.saveAlternativeContact(1n, { mobile: '98765' }),
    ).rejects.toThrow(
      'Alternative mobile number must differ from the primary login number.',
    );
    expect(prisma.customerContact.findMany).not.toHaveBeenCalled();
  });

  it('deletes only a matching non-primary contact', async () => {
    prisma.customerContact.deleteMany.mockResolvedValue({ count: 1 });

    await expect(
      service.removeAlternativeContact(1n, 7n),
    ).resolves.toBeUndefined();
    expect(prisma.customerContact.deleteMany).toHaveBeenCalledWith({
      where: { id: 7n, customerId: 1n, isPrimary: false },
    });
  });
});
