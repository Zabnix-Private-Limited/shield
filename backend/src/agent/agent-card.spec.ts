import { UnauthorizedException } from '@nestjs/common';
import { AgentService } from './agent.service';

describe('AgentService Card Requests & Digital Card Issuance', () => {
  let service: AgentService;
  let prisma: any;
  let agentScopeService: any;
  let customerService: any;

  beforeEach(() => {
    prisma = {
      agent: {
        findFirst: jest.fn(),
      },
      customer: {
        findMany: jest.fn(),
      },
      cardRequest: {
        findMany: jest.fn(),
      },
    };

    agentScopeService = {
      resolveAgentContext: jest.fn().mockResolvedValue({ agentId: 1n, agentCode: 'AGT001' }),
      assertAgentCanAccessCustomer: jest.fn().mockResolvedValue(undefined),
    };

    customerService = {
      approve: jest.fn(),
    };

    service = new AgentService(
      prisma,
      {} as any, // authService
      agentScopeService, // 3rd param (index 2)
      customerService,   // 4th param (index 3)
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );
  });

  describe('listCardRequests', () => {
    it('returns card requests for agent-scoped customers', async () => {
      prisma.customer.findMany.mockResolvedValue([
        {
          id: 10n,
          uuid: 'cust-uuid-10',
          customerCode: 'SH-100',
          firstName: 'Ramesh',
          lastName: 'Kumar',
          mobile: '9876543210',
          status: 'ACTIVE',
          membership: { status: 'ACTIVE' },
          shieldCard: { cardNumber: 'SHIELD-100' },
        },
      ]);
      prisma.cardRequest.findMany.mockResolvedValue([
        {
          id: 801n,
          uuid: 'req-uuid-801',
          customerId: 10n,
          status: 'REQUESTED',
          requestedAt: new Date('2026-08-16T10:00:00Z'),
          remarks: 'Requested physical card',
        },
      ]);

      const requests = await service.listCardRequests({
        principalType: 'USER',
        userId: '5',
      } as any);

      expect(requests).toHaveLength(1);
      expect(requests[0].id).toBe('801');
      expect(requests[0].customer?.name).toBe('Ramesh Kumar');
      expect(requests[0].customer?.hasDigitalCard).toBe(true);
    });

    it('returns empty array when agent has no customers', async () => {
      prisma.customer.findMany.mockResolvedValue([]);

      const requests = await service.listCardRequests({
        principalType: 'USER',
        userId: '5',
      } as any);

      expect(requests).toEqual([]);
    });
  });

  describe('issueCustomerCard', () => {
    it('calls customerService.issueDigitalMembershipCard to issue digital card without broad approval side effects', async () => {
      customerService.issueDigitalMembershipCard = jest.fn().mockResolvedValue({
        id: 100n,
        cardNumber: 'SHLD-CARD-100',
        status: 'ACTIVE',
      });

      const result = await service.issueCustomerCard(10n, {
        principalType: 'USER',
        userId: '5',
      } as any);

      expect(agentScopeService.assertAgentCanAccessCustomer).toHaveBeenCalledWith(10n, expect.anything());
      expect(customerService.issueDigitalMembershipCard).toHaveBeenCalledWith(10n, 5n);
      expect(result).toBeDefined();
    });

    it('throws UnauthorizedException if principal is missing userId', async () => {
      await expect(
        service.issueCustomerCard(10n, { principalType: 'CUSTOMER', customerId: '10' } as any),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
