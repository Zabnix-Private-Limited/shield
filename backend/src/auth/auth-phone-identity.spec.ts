import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

describe('AuthService Phone OTP Identity Resolution', () => {
  let service: AuthService;
  let prisma: any;
  let firebaseAdminService: any;
  let jwtService: any;

  beforeEach(() => {
    prisma = {
      $transaction: jest.fn().mockImplementation((cb) => cb(prisma)),
      customer: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
        updateMany: jest.fn(),
      },
      role: {
        findFirst: jest.fn().mockResolvedValue({
          id: 1n,
          code: 'CUSTOMER',
          rolePermissions: [],
        }),
      },
      authDevice: {
        findFirst: jest.fn().mockResolvedValue({ id: 10n }),
        update: jest.fn().mockResolvedValue({ id: 10n }),
        create: jest.fn().mockResolvedValue({ id: 10n }),
      },
      authSession: {
        create: jest.fn().mockResolvedValue({ id: 100n }),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      loginHistory: {
        create: jest.fn().mockResolvedValue({ id: 50n }),
      },
    };

    firebaseAdminService = {
      verifyIdToken: jest.fn(),
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('mock-jwt-token'),
      signAsync: jest.fn().mockResolvedValue('mock-jwt-token'),
      verify: jest.fn(),
    };

    service = new AuthService(
      prisma as any,
      jwtService as any,
      firebaseAdminService,
      {} as any,
    );
  });

  describe('loginCustomer phone matching', () => {
    it('strictly matches verified phone number to prevent mapping to wrong customer', async () => {
      firebaseAdminService.verifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-stale-or-new',
        phone_number: '+919876543210',
        firebase: { sign_in_provider: 'phone' },
      });

      prisma.customer.findMany.mockResolvedValue([
        {
          id: 100n,
          uuid: 'cust-100-uuid',
          mobile: '9876543210',
          status: 'ACTIVE',
          firebaseUid: 'firebase-uid-old',
        },
      ]);

      prisma.customer.updateMany.mockResolvedValue({ count: 1 });

      const session = await service.loginCustomer('valid-firebase-token');

      expect(session).toBeDefined();
      expect(session.accessToken).toBe('mock-jwt-token');
      expect(prisma.customer.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            mobile: { endsWith: '9876543210' },
          }),
        }),
      );
    });

    it('fails closed and rejects sign-in if multiple customer records match normalized phone', async () => {
      firebaseAdminService.verifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-1',
        phone_number: '+919876543210',
        firebase: { sign_in_provider: 'phone' },
      });

      prisma.customer.findMany.mockResolvedValue([
        { id: 100n, mobile: '9876543210', status: 'ACTIVE' },
        { id: 200n, mobile: '+919876543210', status: 'ACTIVE' },
      ]);

      await expect(
        service.loginCustomer('valid-firebase-token'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects sign-in if customer account is SUSPENDED', async () => {
      firebaseAdminService.verifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-1',
        phone_number: '+919876543210',
        firebase: { sign_in_provider: 'phone' },
      });

      prisma.customer.findMany.mockResolvedValue([
        {
          id: 100n,
          mobile: '9876543210',
          status: 'SUSPENDED',
        },
      ]);

      await expect(
        service.loginCustomer('valid-firebase-token'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
