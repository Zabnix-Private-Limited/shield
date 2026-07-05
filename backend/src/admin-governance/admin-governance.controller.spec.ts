import { AdminGovernanceController } from './admin-governance.controller';

describe('AdminGovernanceController', () => {
  const adminGovernanceService = {
    getDashboardWorkspace: jest.fn(),
    getCustomersWorkspace: jest.fn(),
  } as any;

  let controller: AdminGovernanceController;

  beforeEach(() => {
    jest.clearAllMocks();
    controller = new AdminGovernanceController(adminGovernanceService);
  });

  it('returns the admin dashboard workspace envelope', async () => {
    adminGovernanceService.getDashboardWorkspace.mockResolvedValue({
      header: { title: 'Dashboard' },
    });

    await expect(
      controller.getDashboardWorkspace({
        search: 'alerts',
        status: 'LIVE',
        page: '2',
        page_size: '10',
      }),
    ).resolves.toEqual({
      success: true,
      message: 'Admin dashboard workspace retrieved successfully.',
      data: { header: { title: 'Dashboard' } },
    });

    expect(adminGovernanceService.getDashboardWorkspace).toHaveBeenCalledWith({
      search: 'alerts',
      status: 'LIVE',
      tab: null,
      page: 2,
      pageSize: 10,
    });
  });

  it('returns the admin customers workspace envelope', async () => {
    adminGovernanceService.getCustomersWorkspace.mockResolvedValue({
      header: { title: 'Customers' },
    });

    await expect(
      controller.getCustomersWorkspace({
        search: 'kochi',
        status: 'ACTIVE',
      }),
    ).resolves.toEqual({
      success: true,
      message: 'Admin customers workspace retrieved successfully.',
      data: { header: { title: 'Customers' } },
    });

    expect(adminGovernanceService.getCustomersWorkspace).toHaveBeenCalledWith({
      search: 'kochi',
      status: 'ACTIVE',
      tab: null,
      page: 1,
      pageSize: 25,
    });
  });
});
