import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { RBAC_PERMISSIONS, RBAC_ROLES } from './rbac-catalog';

@Injectable()
export class AuthBootstrapService implements OnModuleInit {
  private readonly logger = new Logger(AuthBootstrapService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.ensureSchemaSupport();
    await this.seedRbacCatalog();
  }

  private async ensureSchemaSupport() {
    const ddl = [
      `ALTER TABLE roles ADD COLUMN IF NOT EXISTS user_type VARCHAR(30)`,
      `ALTER TABLE roles ADD COLUMN IF NOT EXISTS default_scope VARCHAR(30)`,
      `ALTER TABLE roles ADD COLUMN IF NOT EXISTS is_system_role BOOLEAN DEFAULT FALSE`,
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(128)`,
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(30)`,
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS user_type VARCHAR(30)`,
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS access_scope VARCHAR(30)`,
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS branch_business_id BIGINT`,
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ(6)`,
      `ALTER TABLE customers ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(128)`,
      `ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ(6)`,
      `CREATE UNIQUE INDEX IF NOT EXISTS idx_user_firebase_uid ON users(firebase_uid)`,
      `CREATE INDEX IF NOT EXISTS idx_user_branch_business ON users(branch_business_id)`,
      `CREATE UNIQUE INDEX IF NOT EXISTS idx_customer_firebase_uid ON customers(firebase_uid)`,
    ];

    for (const statement of ddl) {
      await this.prisma.$executeRawUnsafe(statement);
    }
  }

  private async seedRbacCatalog() {
    for (const permission of RBAC_PERMISSIONS) {
      await this.prisma.permission.upsert({
        where: { code: permission.code },
        update: {
          name: permission.name,
          description: permission.description,
        },
        create: {
          uuid: randomUUID(),
          code: permission.code,
          name: permission.name,
          description: permission.description,
        },
      });
    }

    for (const role of RBAC_ROLES) {
      await this.prisma.role.upsert({
        where: { code: role.code },
        update: {
          name: role.name,
          description: role.description,
          userType: role.userType,
          defaultScope: role.defaultScope,
          isSystemRole: role.isSystemRole ?? false,
        },
        create: {
          uuid: randomUUID(),
          code: role.code,
          name: role.name,
          description: role.description,
          userType: role.userType,
          defaultScope: role.defaultScope,
          isSystemRole: role.isSystemRole ?? false,
        },
      });
    }

    const roles = await this.prisma.role.findMany({
      where: {
        code: {
          in: RBAC_ROLES.map((role) => role.code),
        },
      },
      select: {
        id: true,
        code: true,
      },
    });

    const permissions = await this.prisma.permission.findMany({
      where: {
        code: {
          in: RBAC_PERMISSIONS.map((permission) => permission.code),
        },
      },
      select: {
        id: true,
        code: true,
      },
    });

    const roleIdByCode = new Map(
      roles
        .filter((role): role is { id: bigint; code: string } => !!role.code)
        .map((role) => [role.code, role.id]),
    );

    const permissionIdByCode = new Map(
      permissions
        .filter(
          (permission): permission is { id: bigint; code: string } =>
            !!permission.code,
        )
        .map((permission) => [permission.code, permission.id]),
    );

    for (const role of RBAC_ROLES) {
      const roleId = roleIdByCode.get(role.code);
      if (!roleId) {
        continue;
      }

      const permissionIds = role.permissions
        .map((code) => permissionIdByCode.get(code))
        .filter((value): value is bigint => value != null);

      if (permissionIds.length === 0) {
        await this.prisma.rolePermission.deleteMany({
          where: { roleId },
        });
        continue;
      }

      await this.prisma.rolePermission.deleteMany({
        where: {
          roleId,
          permissionId: {
            notIn: permissionIds,
          },
        },
      });

      await this.prisma.rolePermission.createMany({
        data: permissionIds.map((permissionId) => ({
          roleId,
          permissionId,
        })),
        skipDuplicates: true,
      });
    }

    this.logger.log(
      `RBAC catalog ensured with ${RBAC_ROLES.length} roles and ${RBAC_PERMISSIONS.length} permissions.`,
    );
  }
}
