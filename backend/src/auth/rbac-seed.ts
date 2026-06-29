import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';
import { RBAC_PERMISSIONS, RBAC_ROLES } from './rbac-catalog';

export async function ensureRbacCatalog(prisma: PrismaClient) {
  for (const permission of RBAC_PERMISSIONS) {
    await prisma.permission.upsert({
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
    await prisma.role.upsert({
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

  const roles = await prisma.role.findMany({
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

  const permissions = await prisma.permission.findMany({
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
      await prisma.rolePermission.deleteMany({
        where: { roleId },
      });
      continue;
    }

    await prisma.rolePermission.deleteMany({
      where: {
        roleId,
        permissionId: {
          notIn: permissionIds,
        },
      },
    });

    await prisma.rolePermission.createMany({
      data: permissionIds.map((permissionId) => ({
        roleId,
        permissionId,
      })),
      skipDuplicates: true,
    });
  }
}
