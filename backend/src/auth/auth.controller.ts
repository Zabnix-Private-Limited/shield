import { Controller, Get, Post, Body, UseGuards, Request, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { MockAuthGuard } from './mock-auth.guard';
import { PrismaService } from '../prisma/prisma.service';

@Controller('auth')
export class AuthController {
  constructor(private prisma: PrismaService) {}

  @Post('login')
  async login(@Body() body: { mobile: string; role: string }) {
    const { mobile, role } = body;
    if (!mobile || !role) {
      throw new UnauthorizedException('Mobile and Role are required');
    }

    const targetRole = role.toLowerCase();

    if (targetRole === 'customer') {
      const customer = await this.prisma.customer.findFirst({
        where: { mobile },
        include: { membership: true, wallet: true },
      });

      if (!customer) {
        throw new NotFoundException('Customer with this mobile number not found');
      }

      return {
        success: true,
        message: 'Login successful',
        data: {
          id: customer.id.toString(),
          role: 'customer',
          user: this.serialize(customer),
        },
      };
    } else {
      const user = await this.prisma.user.findFirst({
        where: {
          mobile,
          role: {
            code: targetRole,
          },
        },
        include: { role: true, department: true },
      });

      if (!user) {
        throw new NotFoundException(`Staff user with this mobile number for role '${role}' not found`);
      }

      return {
        success: true,
        message: 'Login successful',
        data: {
          id: user.id.toString(),
          role: user.role?.code || targetRole,
          user: this.serialize(user),
        },
      };
    }
  }

  @Get('profile')
  @UseGuards(MockAuthGuard)
  getProfile(@Request() req: any) {
    // Serialize BigInt values to string representation since JSON.stringify does not support BigInt
    return this.serialize(req.user);
  }

  private serialize(obj: any): any {
    if (obj === null || obj === undefined) {
      return obj;
    }
    
    if (typeof obj === 'bigint') {
      return obj.toString();
    }
    
    if (Array.isArray(obj)) {
      return obj.map(item => this.serialize(item));
    }
    
    if (typeof obj === 'object') {
      const copy: Record<string, any> = {};
      for (const key of Object.keys(obj)) {
        copy[key] = this.serialize(obj[key]);
      }
      return copy;
    }
    
    return obj;
  }
}
