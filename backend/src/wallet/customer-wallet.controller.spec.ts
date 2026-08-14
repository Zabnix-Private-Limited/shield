import { CustomerWalletController } from './customer-wallet.controller';
describe('CustomerWalletController recharge intents', () => {
  const wallet = { createRechargeIntent: jest.fn(), listRechargeIntents: jest.fn() };
  const controller = new CustomerWalletController(wallet as any, {} as any);
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;
  it('derives recharge intent ownership from customer principal', async () => {
    wallet.createRechargeIntent.mockResolvedValue({ id: 1n });
    await controller.createRechargeIntent({ amount: 100, idempotencyKey: 'retry-1' }, customer);
    expect(wallet.createRechargeIntent).toHaveBeenCalledWith(11n, 100, 'retry-1');
  });
});
