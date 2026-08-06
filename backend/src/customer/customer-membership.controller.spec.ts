import { CustomerMembershipController } from './customer-membership.controller';

describe('CustomerMembershipController card routes', () => {
  const service = {
    getCardProfile: jest.fn(),
    listPhysicalCardRequests: jest.fn(),
    requestPhysicalCard: jest.fn(),
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
});
