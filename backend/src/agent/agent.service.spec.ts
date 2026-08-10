import { AgentService } from './agent.service';

describe('AgentService customer list', () => {
  it('uses the authenticated agent code, search predicate, and bounded pagination', async () => {
    const customerRows = [
      {
        id: BigInt(7),
        firstName: 'Asha',
        lastName: 'Nair',
        customerCode: 'SH-007',
        mobile: '9876543210',
        status: 'ACTIVE',
        membership: { status: 'ACTIVE' },
        shieldCard: { status: 'ACTIVE' },
      },
    ];
    const prisma = {
      customer: {
        count: jest.fn().mockReturnValue('count-query'),
        findMany: jest.fn().mockReturnValue('find-query'),
      },
      $transaction: jest.fn().mockResolvedValue([101, customerRows]),
    };
    const agentScope = {
      resolveAgentContext: jest.fn().mockResolvedValue({
        agentCode: 'AG-42',
      }),
    };
    const service = new AgentService(
      prisma as any,
      {} as any,
      agentScope as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );

    const result = await service.listCustomers({} as any, {
      query: 'asha',
      status: 'active',
      membershipStatus: 'suspended',
      page: 2,
      pageSize: 500,
    });

    expect(prisma.customer.count).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          agentCode: 'AG-42',
          status: 'ACTIVE',
          membership: { status: 'SUSPENDED' },
        }),
      }),
    );
    expect(prisma.customer.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 100, take: 100 }),
    );
    expect(result).toMatchObject({
      page: 2,
      pageSize: 100,
      total: 101,
      totalPages: 2,
      items: [
        expect.objectContaining({ id: '7', customerCode: 'SH-007' }),
      ],
    });
  });
});
