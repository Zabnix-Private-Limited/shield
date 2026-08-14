import { REQUIRED_PERMISSIONS } from '../auth/permissions.decorator';
import { PlatformCapabilitiesController } from './platform-capabilities.controller';

describe('PlatformCapabilitiesController reports contract', () => {
  const authService = { verifyAccessToken: jest.fn() };
  const agentScopeService = {
    isAgentPrincipal: jest.fn(),
    resolveAgentContext: jest.fn(),
    assertAgentCanAccessCustomer: jest.fn(),
    assertAgentCanAccessAppointment: jest.fn(),
  };
  const providerScopeService = {
    normalizeReportFilters: jest.fn(),
    isProviderPrincipal: jest.fn(),
    assertProviderCanAccessAppointment: jest.fn(),
    assertProviderCanAccessCustomer: jest.fn(),
  };
  const printService = { listTemplates: jest.fn(), generate: jest.fn() };
  const realtimeService = { stream: jest.fn() };
  const reportService = {
    listMetadata: jest.fn(),
    runReport: jest.fn(),
    recordReportExport: jest.fn(),
  };
  const controller = new PlatformCapabilitiesController(
    authService as any,
    agentScopeService as any,
    providerScopeService as any,
    printService as any,
    realtimeService as any,
    reportService as any,
  );

  beforeEach(() => jest.clearAllMocks());

  it('requires report view/export permissions on the registry and run routes', () => {
    expect(
      Reflect.getMetadata(
        REQUIRED_PERMISSIONS,
        PlatformCapabilitiesController.prototype.getReports,
      ),
    ).toEqual(['reports.view']);
    expect(
      Reflect.getMetadata(
        REQUIRED_PERMISSIONS,
        PlatformCapabilitiesController.prototype.runReport,
      ),
    ).toEqual(['reports.export']);
  });

  it('overwrites any supplied agent code with the authenticated agent scope', async () => {
    const principal = { principalType: 'USER', userId: '9' } as any;
    providerScopeService.normalizeReportFilters.mockReturnValue({
      agentCode: 'ATTEMPTED-OTHER-AGENT',
    });
    agentScopeService.isAgentPrincipal.mockReturnValue(true);
    agentScopeService.resolveAgentContext.mockResolvedValue({
      agentCode: 'AGENT-OWNED',
    });
    reportService.runReport.mockResolvedValue({
      rows: [],
      metadata: { id: 'AGENT_CUSTOMER_REGISTRATIONS' },
      exportFile: { format: 'CSV' },
    });

    await controller.runReport(
      {
        workspace: 'agent',
        reportId: 'AGENT_CUSTOMER_REGISTRATIONS',
        agentCode: 'ATTEMPTED-OTHER-AGENT',
        format: 'CSV',
      },
      principal,
    );

    expect(reportService.runReport).toHaveBeenCalledWith(
      'AGENT_CUSTOMER_REGISTRATIONS',
      expect.objectContaining({ workspace: 'agent', agentCode: 'AGENT-OWNED' }),
      'CSV',
    );
    expect(reportService.recordReportExport).toHaveBeenCalledWith(
      9n,
      'AGENT_CUSTOMER_REGISTRATIONS',
      'CSV',
      expect.objectContaining({ agentCode: 'AGENT-OWNED' }),
    );
  });
});
