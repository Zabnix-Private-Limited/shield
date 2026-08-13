import { NotificationController } from './notification.controller';

describe('NotificationController customer scope', () => {
  const notificationService = {
    notificationBelongsToCustomer: jest.fn(),
    markAsRead: jest.fn(),
    markAllAsRead: jest.fn(),
    deactivateDeviceToken: jest.fn(),
    registerDeviceToken: jest.fn(),
  };
  const agentScope = {
    assertAgentCanAccessNotification: jest.fn(),
    assertAgentCanAccessCustomer: jest.fn(),
    isAgentPrincipal: jest.fn().mockReturnValue(false),
    listAccessibleCustomerIds: jest.fn(),
  };
  const providerScope = {
    assertProviderCanAccessNotification: jest.fn(),
    assertProviderCanAccessCustomer: jest.fn(),
  };
  const controller = new NotificationController(
    notificationService as any,
    agentScope as any,
    providerScope as any,
  );
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('rejects another customer notification before marking it as read', async () => {
    notificationService.notificationBelongsToCustomer.mockResolvedValue(false);

    await expect(controller.markAsRead('99', customer)).rejects.toThrow(
      'Customers can only update their own notifications.',
    );
    expect(notificationService.markAsRead).not.toHaveBeenCalled();
  });

  it('pins bulk updates to the authenticated customer', async () => {
    notificationService.markAllAsRead.mockResolvedValue({ count: 2 });

    await controller.markAllRead({ customer_id: '99' }, customer);

    expect(notificationService.markAllAsRead).toHaveBeenCalledWith([11n]);
    expect(agentScope.assertAgentCanAccessCustomer).not.toHaveBeenCalled();
    expect(providerScope.assertProviderCanAccessCustomer).not.toHaveBeenCalled();
  });

  it('pins device-token deactivation to the authenticated customer', async () => {
    notificationService.deactivateDeviceToken.mockResolvedValue({ count: 1 });

    await controller.deactivateDeviceToken({ token: 'device-token' }, customer);

    expect(notificationService.deactivateDeviceToken).toHaveBeenCalledWith(
      'device-token',
      11n,
    );
  });

  it('pins a push token registration to the authenticated customer session', async () => {
    notificationService.registerDeviceToken.mockResolvedValue({ id: 1n });
    const authenticatedCustomer = {
      principalType: 'CUSTOMER',
      customerId: '11',
      sessionId: 'customer-session',
    } as any;

    await controller.registerDeviceToken(
      {
        customer_id: '99',
        token: 'fcm-token',
        platform: 'WEB',
        device_label: 'Chrome',
      },
      authenticatedCustomer,
    );

    expect(notificationService.registerDeviceToken).toHaveBeenCalledWith({
      customerId: 11n,
      token: 'fcm-token',
      platform: 'WEB',
      deviceLabel: 'Chrome',
      sessionId: 'customer-session',
    });
  });
});
