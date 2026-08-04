import { ReferralController } from './referral.controller';

describe('ReferralController customer scope', () => {
  const referralService = {
    getReferralTree: jest.fn(),
    getReferralSummary: jest.fn(),
  };
  const agentScope = { assertAgentCanAccessCustomer: jest.fn() };
  const controller = new ReferralController(referralService as any, agentScope as any);
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('rejects another customer referral tree before reading it', async () => {
    await expect(controller.tree('99', customer)).rejects.toThrow(
      'Customers can only access their own referral data.',
    );
    expect(referralService.getReferralTree).not.toHaveBeenCalled();
  });

  it('reads the authenticated customer referral summary', async () => {
    referralService.getReferralSummary.mockResolvedValue({ total: 0 });

    await controller.summary('11', customer);

    expect(referralService.getReferralSummary).toHaveBeenCalledWith(11n);
  });
});
