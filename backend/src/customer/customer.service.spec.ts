import { CustomerService } from './customer.service';

describe('CustomerService alternative contacts', () => {
  const prisma = {
    customer: { findUnique: jest.fn() },
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

  it('rejects the primary mobile even when it includes +91', async () => {
    prisma.customer.findUnique.mockResolvedValue({ mobile: '+919876543210' });

    await expect(
      service.saveAlternativeContact(11n, { mobile: '98765 43210' }),
    ).rejects.toThrow('Alternative mobile number must differ');

    expect(prisma.customerContact.findMany).not.toHaveBeenCalled();
  });

  it('updates an existing normalized alternative contact instead of duplicating it', async () => {
    prisma.customer.findUnique.mockResolvedValue({ mobile: '+919876543210' });
    prisma.customerContact.findMany.mockResolvedValue([
      { id: 7n, mobile: '+91 99887 76655' },
    ]);
    prisma.customerContact.update.mockResolvedValue({ id: 7n });

    await service.saveAlternativeContact(11n, {
      mobile: '99887-76655',
      name: 'Care contact',
    });

    expect(prisma.customerContact.update).toHaveBeenCalledWith({
      where: { id: 7n },
      data: { name: 'Care contact', relation: null, isPrimary: false },
    });
    expect(prisma.customerContact.create).not.toHaveBeenCalled();
  });
});
