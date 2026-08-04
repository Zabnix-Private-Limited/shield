import { WalletController } from './wallet.controller';

describe('WalletController transaction scope', () => {
  const walletService = {
    walletBelongsToCustomer: jest.fn(),
    getTransactions: jest.fn(),
  };
  const providerScope = { assertProviderCanAccessWallet: jest.fn() };
  const controller = new WalletController(
    walletService as any,
    providerScope as any,
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
});
