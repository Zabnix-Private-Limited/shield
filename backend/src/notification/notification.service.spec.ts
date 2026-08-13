import { NotificationService } from './notification.service';

describe('NotificationService push-token registration', () => {
  const prisma = {
    authSession: { findUnique: jest.fn() },
    devicePushToken: { upsert: jest.fn() },
  };
  const service = new NotificationService(
    prisma as any,
    {} as any,
    {} as any,
    {} as any,
    {} as any,
  );

  beforeEach(() => jest.clearAllMocks());

  it('upserts one token against the authenticated customer device', async () => {
    prisma.authSession.findUnique.mockResolvedValue({ authDeviceId: 22n });
    prisma.devicePushToken.upsert.mockResolvedValue({ id: 1n });

    await service.registerDeviceToken({
      customerId: 11n,
      token: 'fcm-token',
      platform: 'web',
      deviceLabel: 'Chrome',
      sessionId: 'customer-session',
    });

    expect(prisma.authSession.findUnique).toHaveBeenCalledWith({
      where: { sessionId: 'customer-session' },
      select: { authDeviceId: true },
    });
    expect(prisma.devicePushToken.upsert).toHaveBeenCalledWith({
      where: { token: 'fcm-token' },
      update: {
        customerId: 11n,
        authDeviceId: 22n,
        platform: 'WEB',
        deviceLabel: 'Chrome',
        isActive: true,
        lastSeenAt: expect.any(Date),
      },
      create: {
        uuid: expect.any(String),
        customerId: 11n,
        authDeviceId: 22n,
        token: 'fcm-token',
        platform: 'WEB',
        deviceLabel: 'Chrome',
        isActive: true,
        lastSeenAt: expect.any(Date),
      },
    });
  });
});
