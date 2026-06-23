import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MockAuthGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    
    // Extract mock auth headers
    const roleHeader = request.headers['x-role'];
    const userIdHeader = request.headers['x-user-id'];
    const customerIdHeader = request.headers['x-customer-id'];

    try {
      // 1. If explicit customer ID is provided
      if (customerIdHeader) {
        const customer = await this.prisma.customer.findUnique({
          where: { id: BigInt(customerIdHeader) },
          include: { membership: true, wallet: true },
        });
        if (customer) {
          (customer as any).email = 'Zabnixprivatelimited@gmail.com';
          request.user = {
            id: customer.id,
            uuid: customer.uuid,
            role: 'customer',
            isStaff: false,
            customer,
          };
          return true;
        }
      }

      // 2. If explicit staff User ID is provided
      if (userIdHeader) {
        const user = await this.prisma.user.findUnique({
          where: { id: BigInt(userIdHeader) },
          include: { role: true, department: true },
        });
        if (user) {
          (user as any).email = 'Zabnixprivatelimited@gmail.com';
          request.user = {
            id: user.id,
            uuid: user.uuid,
            role: user.role?.code || 'staff',
            isStaff: true,
            user,
          };
          return true;
        }
      }

      // 3. Fallback to role-based selection from x-role header, or default to 'customer'
      const targetRole = (roleHeader || 'customer').toString().toLowerCase();

      if (targetRole === 'customer') {
        const customer = await this.prisma.customer.findFirst({
          where: { mobile: '9876543210' },
          include: { membership: true, wallet: true },
        });
        
        if (!customer) {
          throw new Error('Default mock customer Nihal Rahman not found in database. Run db seed.');
        }

        (customer as any).email = 'Zabnixprivatelimited@gmail.com';
        request.user = {
          id: customer.id,
          uuid: customer.uuid,
          role: 'customer',
          isStaff: false,
          customer,
        };
      } else {
        // Staff roles
        const user = await this.prisma.user.findFirst({
          where: {
            role: {
              code: targetRole,
            },
          },
          include: { role: true, department: true },
        });

        if (!user) {
          throw new Error(`Mock staff user for role '${targetRole}' not found in database. Run db seed.`);
        }

        (user as any).email = 'Zabnixprivatelimited@gmail.com';
        request.user = {
          id: user.id,
          uuid: user.uuid,
          role: user.role?.code || targetRole,
          isStaff: true,
          user,
        };
      }

      return true;
    } catch (error) {
      console.error('MockAuthGuard Error:', error.message);
      throw new UnauthorizedException(error.message);
    }
  }
}
