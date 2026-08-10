import { ForbiddenException } from '@nestjs/common';
import { AgentScopeService } from './agent-scope.service';

describe('AgentScopeService', () => {
  const principal = {
    principalType: 'USER' as const,
    userId: '42',
    roleCode: 'SHIELD_AGENT',
  };

  it('permits an assigned customer for the authenticated SHIELD agent', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: BigInt(42),
          employeeCode: 'AG-42',
          firstName: 'Assigned',
          lastName: 'Agent',
          email: null,
          mobile: null,
          status: 'ACTIVE',
        }),
      },
      customer: {
        findMany: jest.fn().mockResolvedValue([{ id: BigInt(7) }]),
      },
    };
    const service = new AgentScopeService(prisma as any);

    await expect(
      service.assertAgentCanAccessCustomer(BigInt(7), principal),
    ).resolves.toBeUndefined();
    expect(prisma.customer.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ agentCode: 'AG-42' }),
      }),
    );
  });

  it('rejects a guessed customer ID outside the agent graph', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: BigInt(42),
          employeeCode: 'AG-42',
          firstName: 'Assigned',
          lastName: 'Agent',
          email: null,
          mobile: null,
          status: 'ACTIVE',
        }),
      },
      customer: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new AgentScopeService(prisma as any);

    await expect(
      service.assertAgentCanAccessCustomer(BigInt(999), principal),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
