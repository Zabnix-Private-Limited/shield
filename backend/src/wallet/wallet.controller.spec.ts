import { WalletController } from './wallet.controller';

describe('WalletController transaction scope', () => {
  const walletService = {
    walletBelongsToCustomer: jest.fn(),
    getTransactions: jest.fn(),
    recharge: jest.fn(),
  };
  const providerScope = { assertProviderCanAccessWallet: jest.fn() };
  const agentScope = {
    assertAgentCanAccessWalletByCustomer: jest.fn(),
    assertAgentCanAccessWallet: jest.fn(),
  };
  const controller = new WalletController(
    walletService as any,
    providerScope as any,
    agentScope as any,
  );
  const customer = {
    principalType: 'CUSTOMER',
    customerId: '11',
  } as any;

  beforeEach(() => jest.clearAllMocks());

  it('rejects transaction access to a wallet not owned by the customer', async () => {
    walletService.walletBelongsToCustomer.mockResolvedValue(false);

    await expect(
      controller.getTransactions(
        '99',
        undefined,
        undefined,
        undefined,
        customer,
      ),
    ).rejects.toThrow('Customers can only view their own wallet transactions.');

    expect(walletService.getTransactions).not.toHaveBeenCalled();
  });

  it('fails closed when a customer principal has no customer context', async () => {
    await expect(
      controller.getTransactions('99', undefined, undefined, undefined, {
        principalType: 'CUSTOMER',
      } as any),
    ).rejects.toThrow('Authenticated customer context is required.');

    expect(walletService.walletBelongsToCustomer).not.toHaveBeenCalled();
  });

  it('scopes a staff recharge to the target customer before ledger mutation', async () => {
    walletService.recharge.mockResolvedValue({ id: 1n });
    const agent = {
      principalType: 'USER',
      userId: '42',
      roleCode: 'SHIELD_AGENT',
    } as any;
    await controller.recharge({ customer_id: '11', amount: 100 }, agent);
    expect(
      agentScope.assertAgentCanAccessWalletByCustomer,
    ).toHaveBeenCalledWith(11n, agent);
    expect(walletService.recharge).toHaveBeenCalledWith(
      11n,
      100,
      42n,
      undefined,
      'CASH',
    );
  });

  it('scopes an agent transaction feed by the wallet owner', async () => {
    const agent = {
      principalType: 'USER',
      userId: '42',
      roleCode: 'SHIELD_AGENT',
    } as any;
    walletService.getTransactions.mockResolvedValue([]);

    await controller.getTransactions('99', undefined, undefined, undefined, agent);

    expect(agentScope.assertAgentCanAccessWallet).toHaveBeenCalledWith(99n, agent);
    expect(walletService.getTransactions).toHaveBeenCalled();
  });
});
