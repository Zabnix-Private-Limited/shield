import { AuthService } from './auth.service';

describe('AuthService customer session ownership', () => {
  const prisma = {
    authSession: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      updateMany: jest.fn(),
    },
  };
  const service = new AuthService(
    prisma as any,
    {} as any,
    {} as any,
    {} as any,
  );
  const customer = {
    sessionId: 'current-session',
    principalType: 'CUSTOMER',
    customerId: '11',
    subjectId: 'customer-11',
    roleCode: 'CUSTOMER',
    userType: 'CUSTOMER',
    accessScope: 'SELF',
    permissions: [],
    firebaseUid: '',
    authProvider: 'phone',
  } as any;

  beforeEach(() => jest.clearAllMocks());

  it('lists only owner-scoped safe session and device fields', async () => {
    prisma.authSession.findMany.mockResolvedValue([
      {
        sessionId: 'current-session',
        roleCode: 'CUSTOMER',
        loginMethod: 'phone',
        createdAt: new Date('2026-08-08T10:00:00Z'),
        lastSeenAt: new Date('2026-08-08T10:05:00Z'),
        refreshTokenExpiresAt: new Date('2026-09-08T10:00:00Z'),
        revokedAt: null,
        refreshTokenHash: 'must-never-leak',
        authDevice: {
          id: 3n,
          uuid: 'device-3',
          deviceName: 'Chrome',
          platform: 'web',
          browser: 'Chrome',
          os: 'Windows',
          isTrusted: false,
          firstSeenAt: new Date('2026-08-08T10:00:00Z'),
          lastSeenAt: new Date('2026-08-08T10:05:00Z'),
          userAgent: 'must-never-leak',
        },
      },
    ]);

    const sessions = await service.listSessions(customer);

    expect(prisma.authSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerType: 'CUSTOMER', ownerId: '11' },
      }),
    );
    expect(sessions[0]).toEqual(
      expect.objectContaining({ sessionId: 'current-session', isCurrent: true }),
    );
    expect(sessions[0]).not.toHaveProperty('refreshTokenHash');
    expect(sessions[0].device).not.toHaveProperty('userAgent');
  });

  it('rejects revoking a foreign session before mutation', async () => {
    prisma.authSession.findFirst.mockResolvedValue(null);

    await expect(
      service.revokeOwnedSession(customer, 'other-customers-session'),
    ).rejects.toThrow('Session not found for principal.');

    expect(prisma.authSession.findFirst).toHaveBeenCalledWith({
      where: {
        sessionId: 'other-customers-session',
        ownerType: 'CUSTOMER',
        ownerId: '11',
      },
      select: { sessionId: true },
    });
    expect(prisma.authSession.updateMany).not.toHaveBeenCalled();
  });

  it('excludes the current session when revoking all other sessions', async () => {
    prisma.authSession.findMany.mockResolvedValue([{ sessionId: 'second-session' }]);
    prisma.authSession.updateMany.mockResolvedValue({ count: 1 });

    await expect(service.revokeOtherOwnedSessions(customer)).resolves.toEqual({
      success: true,
      revokedSessionCount: 1,
    });

    expect(prisma.authSession.findMany).toHaveBeenCalledWith({
      where: {
        ownerType: 'CUSTOMER',
        ownerId: '11',
        sessionId: { not: 'current-session' },
        revokedAt: null,
      },
      select: { sessionId: true },
    });
  });
});
