import { ForbiddenException } from '@nestjs/common';
import { CustomerProviderDiscoveryController } from './customer-provider-discovery.controller';

describe('CustomerProviderDiscoveryController', () => {
  const directory = {
    listCustomerProviderCategories: jest.fn(),
    listCustomerProviders: jest.fn(),
    getCustomerProvider: jest.fn(),
  };
  const controller = new CustomerProviderDiscoveryController(directory as any);
  const customer = { principalType: 'CUSTOMER', customerId: '42' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('returns only the customer directory service projection', async () => {
    directory.listCustomerProviders.mockResolvedValue({ items: [], pagination: {} });

    await expect(controller.list(customer, 'clinic', 'DOCTOR', '2', '10')).resolves.toEqual({
      success: true,
      message: 'Customer providers retrieved successfully.',
      data: { items: [], pagination: {} },
    });
    expect(directory.listCustomerProviders).toHaveBeenCalledWith({
      query: 'clinic',
      type: 'DOCTOR',
      page: '2',
      pageSize: '10',
    });
  });

  it('rejects non-customer callers before directory access', async () => {
    await expect(controller.categories({ principalType: 'USER' } as any)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(directory.listCustomerProviderCategories).not.toHaveBeenCalled();
  });
});
