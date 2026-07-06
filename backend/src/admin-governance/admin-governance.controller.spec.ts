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
      selectedId: null,
      sortKey: null,
      sortDirection: null,
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
        tab: 'Profile',
        selected_id: '42',
        sort_key: 'createdAt',
        sort_direction: 'asc',
        page: '3',
        page_size: '15',
      }),
    ).resolves.toEqual({
      success: true,
      message: 'Admin customers workspace retrieved successfully.',
      data: { header: { title: 'Customers' } },
    });

    expect(adminGovernanceService.getCustomersWorkspace).toHaveBeenCalledWith({
      search: 'kochi',
      status: 'ACTIVE',
      tab: 'Profile',
      selectedId: '42',
      sortKey: 'createdAt',
      sortDirection: 'asc',
      page: 3,
      pageSize: 15,
    });
  });
});
