import { CustomerMembershipController } from './customer-membership.controller';

describe('CustomerMembershipController card routes', () => {
  const service = {
    getCardProfile: jest.fn(),
    listPhysicalCardRequests: jest.fn(),
    requestPhysicalCard: jest.fn(),
    submitMembershipApplication: jest.fn(),
    getCustomerMembershipApplication: jest.fn(),
    getMembershipApplicationCustomerId: jest.fn(),
    reviewMembershipApplication: jest.fn(),
  };
  const agentScope = { assertAgentCanAccessCustomer: jest.fn() };
  const controller = new CustomerMembershipController(
    service as any,
    agentScope as any,
  );
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('derives card reads from the customer principal', async () => {
    service.getCardProfile.mockResolvedValue({ action: 'VIEW_CARD' });
    await expect(controller.getCard(customer)).resolves.toEqual({
      success: true,
      data: { action: 'VIEW_CARD' },
    });
    expect(service.getCardProfile).toHaveBeenCalledWith(11n);
  });

  it('keeps request history and card requests customer-self scoped', async () => {
    service.listPhysicalCardRequests.mockResolvedValue([]);
    service.requestPhysicalCard.mockResolvedValue({ status: 'REQUESTED' });
    await controller.getCardRequests(customer);
    await controller.requestCard(customer);
    expect(service.listPhysicalCardRequests).toHaveBeenCalledWith(11n);
    expect(service.requestPhysicalCard).toHaveBeenCalledWith(11n);
  });

  it('derives membership applications only from the authenticated customer', async () => {
    service.submitMembershipApplication.mockResolvedValue({
      status: 'PENDING',
    });
    service.getCustomerMembershipApplication.mockResolvedValue({
      status: 'PENDING',
    });
    await controller.submitApplication(customer);
    await controller.getApplication(customer);
    expect(service.submitMembershipApplication).toHaveBeenCalledWith(11n);
    expect(service.getCustomerMembershipApplication).toHaveBeenCalledWith(11n);
  });

  it('does not let a customer review an application', async () => {
    await expect(
      controller.reviewApplication('9', { status: 'APPROVED' }, customer),
    ).rejects.toThrow('Authorized staff context is required');
    expect(service.reviewMembershipApplication).not.toHaveBeenCalled();
  });

  it('passes an authorized staff review to the service', async () => {
    service.getMembershipApplicationCustomerId.mockResolvedValue(11n);
    service.reviewMembershipApplication.mockResolvedValue({
      status: 'APPROVED',
    });
    const staff = { principalType: 'USER', userId: '7' } as any;
    await controller.reviewApplication('9', { status: 'APPROVED' }, staff);
    expect(service.reviewMembershipApplication).toHaveBeenCalledWith(
      9n,
      7n,
      'APPROVED',
      undefined,
    );
    expect(agentScope.assertAgentCanAccessCustomer).toHaveBeenCalledWith(
      11n,
      staff,
    );
  });
});
