import { PlatformReportService } from './platform-report.service';

describe('PlatformReportService agent customer-management reports', () => {
  const prisma = {
    membership: { findMany: jest.fn() },
    complaint: { findMany: jest.fn() },
    customer: { findMany: jest.fn() },
    crmActivity: { findMany: jest.fn() },
    crmTask: { findMany: jest.fn() },
  };
  const printService = { generate: jest.fn() };
  const service = new PlatformReportService(prisma as any, printService as any);

  beforeEach(() => jest.clearAllMocks());

  it('registers all required agent customer-management report contracts', () => {
    const ids = service
      .listMetadata('agent')
      .reports.map((report) => report.id);
    expect(ids).toEqual(
      expect.arrayContaining([
        'AGENT_MEMBERSHIP_STATUS',
        'AGENT_SUPPORT_COMPLAINT_STATUS',
        'AGENT_CUSTOMER_RETENTION',
        'AGENT_CRM_PERFORMANCE',
      ]),
    );
  });

  it('builds the support and complaint report from the active agent customer scope', async () => {
    prisma.complaint.findMany.mockResolvedValue([
      {
        complaintType: 'SUPPORT_REQUEST',
        status: 'SUBMITTED',
        createdAt: new Date('2026-08-14T00:00:00.000Z'),
        customer: { firstName: 'Scoped', lastName: 'Customer' },
      },
    ]);

    const result = await service.runReport(
      'AGENT_SUPPORT_COMPLAINT_STATUS',
      { agentCode: 'AGENT-OWNED' },
      'CSV',
    );

    expect(prisma.complaint.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          customer: expect.objectContaining({ agentCode: 'AGENT-OWNED' }),
        }),
      }),
    );
    expect(result.summary).toEqual(
      expect.objectContaining({ totalRequests: 1, openRequests: 1 }),
    );
    expect(result.exportFile.fileName).toBe(
      'agent-support-complaint-status.csv',
    );
  });
});
