import { CustomerService } from './customer.service';

describe('CustomerService alternative contacts', () => {
  const prisma = {
    customer: { findUnique: jest.fn(), findFirst: jest.fn(), update: jest.fn() },
    customerContact: {
      findMany: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      deleteMany: jest.fn(),
    },
    auditLog: { create: jest.fn() },
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
      data: {
        name: 'Care contact',
        relation: null,
        isPrimary: false,
        contactType: 'ALTERNATIVE',
      },
    });
    expect(prisma.customerContact.create).not.toHaveBeenCalled();
  });

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
      where: {
        id: 7n,
        customerId: 1n,
        isPrimary: false,
        contactType: 'ALTERNATIVE',
        deletedAt: null,
      },
    });
  });

  it('projects only customer-safe fields for the signed-in profile', async () => {
    prisma.customer.findFirst.mockResolvedValue({ id: 11n, mobile: '9876543210' });

    await service.getCustomerSelfProfile(11n);

    expect(prisma.customer.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 11n, deletedAt: null } }),
    );
    expect(prisma.customer.findFirst.mock.calls[0][0].select).toEqual(
      expect.objectContaining({ mobile: true }),
    );
    expect(
      prisma.customer.findFirst.mock.calls[0][0].select,
    ).not.toHaveProperty('firebaseUid');
  });

  it('does not permit the customer profile contract to update phone or status', async () => {
    prisma.customer.update.mockResolvedValue({ id: 11n });
    prisma.customer.findFirst.mockResolvedValue({ id: 11n, mobile: '9876543210' });
    prisma.auditLog.create.mockResolvedValue({});

    await service.updateCustomerSelfProfile(11n, {
      firstName: ' Asha ',
      lastName: ' Kumar ',
      email: 'asha@example.com',
    } as any);

    expect(prisma.customer.update).toHaveBeenCalledWith({
      where: { id: 11n },
      data: expect.not.objectContaining({ mobile: expect.anything(), status: expect.anything() }),
    });
    expect(prisma.auditLog.create).toHaveBeenCalled();
  });

  it('rejects a future date of birth for the customer profile', async () => {
    await expect(
      service.updateCustomerSelfProfile(11n, {
        firstName: 'Asha',
        lastName: 'Kumar',
        dob: '2999-01-01',
      }),
    ).rejects.toThrow('Date of birth must be a valid past date.');
  });
});
