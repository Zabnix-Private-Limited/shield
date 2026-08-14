import { ForbiddenException } from '@nestjs/common';
import { CrmController } from './crm.controller';

describe('CrmController complaint scope', () => {
  const crm = {
    listComplaints: jest.fn(), getComplaint: jest.fn(), assignComplaint: jest.fn(),
    addInternalNote: jest.fn(), replyToCustomer: jest.fn(), escalateComplaint: jest.fn(), resolveComplaint: jest.fn(),
  };
  const scope = {
    isAgentPrincipal: jest.fn().mockReturnValue(true),
    listAccessibleCustomerIds: jest.fn().mockResolvedValue([11n]),
    assertAgentCanAccessCustomer: jest.fn(),
    assertAgentCanAccessComplaint: jest.fn(),
  };
  const controller = new CrmController(crm as any, scope as any);
  const agent = { principalType: 'USER', userId: '42', roleCode: 'SHIELD_AGENT' } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    scope.isAgentPrincipal.mockReturnValue(true);
    scope.listAccessibleCustomerIds.mockResolvedValue([11n]);
    scope.assertAgentCanAccessCustomer.mockResolvedValue(undefined);
    scope.assertAgentCanAccessComplaint.mockResolvedValue(undefined);
  });

  it('filters an unqualified agent complaint list through accessible customer IDs', async () => {
    crm.listComplaints.mockResolvedValue([]);
    await controller.listComplaints(undefined, agent);
    expect(crm.listComplaints).toHaveBeenCalledWith(undefined, [11n]);
  });

  it('blocks a scoped agent from reading an unassigned complaint', async () => {
    scope.assertAgentCanAccessComplaint.mockRejectedValue(new ForbiddenException());
    await expect(controller.getComplaint('99', agent)).rejects.toBeInstanceOf(ForbiddenException);
    expect(crm.getComplaint).not.toHaveBeenCalled();
  });

  it('blocks a scoped agent from mutating an unassigned complaint', async () => {
    scope.assertAgentCanAccessComplaint.mockRejectedValue(new ForbiddenException());
    await expect(controller.replyToCustomer('99', { note: 'update' }, agent)).rejects.toBeInstanceOf(ForbiddenException);
    expect(crm.replyToCustomer).not.toHaveBeenCalled();
  });

  it('uses the authenticated actor for a scoped customer reply', async () => {
    crm.replyToCustomer.mockResolvedValue({ id: 2n });
    await controller.replyToCustomer('7', { note: 'visible reply' }, agent);
    expect(crm.replyToCustomer).toHaveBeenCalledWith(7n, 42n, 'visible reply');
  });
});
