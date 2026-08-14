import { StoreChangeController } from './store-change.controller';

describe('StoreChangeController', () => {
  const service = {
    listStoreChangeRequests: jest.fn(),
    submitStoreChangeRequest: jest.fn(),
    getStoreChangeRequestCustomerId: jest.fn(),
    listStoreChangeRequestsForStaff: jest.fn(),
    reviewStoreChangeRequest: jest.fn(),
  };
  const agentScope = {
    assertAgentCanAccessCustomer: jest.fn(),
    isAgentPrincipal: jest.fn().mockReturnValue(false),
    listAccessibleCustomerIds: jest.fn(),
  };
  const controller = new StoreChangeController(service as any, agentScope as any);
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('derives a submitted request from the authenticated customer', async () => {
    service.submitStoreChangeRequest.mockResolvedValue({ id: '1' });

    await controller.submitCustomerRequest(
      { providerId: '7', reason: 'Moved closer to this pharmacy.' }, customer,
    );

    expect(service.submitStoreChangeRequest).toHaveBeenCalledWith(
      11n, 7n, 'Moved closer to this pharmacy.',
    );
  });

  it('rejects a request without a customer principal', async () => {
    await expect(
      controller.submitCustomerRequest({ providerId: '7', reason: 'Reason' }, undefined),
    ).rejects.toThrow('Authenticated customer context is required.');
  });

  it('scopes an agent review to the request customer before mutation', async () => {
    service.getStoreChangeRequestCustomerId.mockResolvedValue(11n);
    service.reviewStoreChangeRequest.mockResolvedValue({ id: '1', status: 'APPROVED' });
    const agent = { principalType: 'USER', userId: '42', roleCode: 'SHIELD_AGENT' } as any;

    await controller.review('1', { status: 'APPROVED' }, agent);

    expect(agentScope.assertAgentCanAccessCustomer).toHaveBeenCalledWith(11n, agent);
    expect(service.reviewStoreChangeRequest).toHaveBeenCalledWith(
      1n, 42n, 'APPROVED', undefined,
    );
  });

  it('limits an unfiltered agent queue to assigned customers', async () => {
    agentScope.isAgentPrincipal.mockReturnValue(true);
    agentScope.listAccessibleCustomerIds.mockResolvedValue([11n]);
    service.listStoreChangeRequestsForStaff.mockResolvedValue([]);
    const agent = { principalType: 'USER', userId: '42', roleCode: 'SHIELD_AGENT' } as any;

    await controller.listForStaff(undefined, agent);

    expect(service.listStoreChangeRequestsForStaff).toHaveBeenCalledWith([11n]);
  });
});
