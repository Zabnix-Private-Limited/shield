import { AdminGovernanceController } from './admin-governance.controller';

describe('AdminGovernanceController', () => {
  const adminGovernanceService = {
    getDashboardWorkspace: jest.fn(),
    getCustomersWorkspace: jest.fn(),
    getCustomerWorkspaceForm: jest.fn(),
    executeCustomerWorkspaceAction: jest.fn(),
    executeCustomerWorkspaceBulkAction: jest.fn(),
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
    const principal = {
      userId: '100',
      email: 'admin@shield.test',
      permissions: ['customers.view'],
    } as any;
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
      }, principal),
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
    }, principal);
  });

  it('returns the admin customer form envelope', async () => {
    const principal = {
      userId: '100',
      email: 'admin@shield.test',
      permissions: ['customers.view', 'customers.update'],
    } as any;
    adminGovernanceService.getCustomerWorkspaceForm.mockResolvedValue({
      id: 'edit',
      entity: 'customer',
    });

    await expect(
      controller.getCustomerWorkspaceForm(
        'edit',
        { record_id: '42' },
        principal,
      ),
    ).resolves.toEqual({
      success: true,
      message: 'Admin customer workspace form retrieved successfully.',
      data: { id: 'edit', entity: 'customer' },
    });

    expect(adminGovernanceService.getCustomerWorkspaceForm).toHaveBeenCalledWith(
      'edit',
      '42',
      principal,
    );
  });

  it('executes a customer workspace action', async () => {
    const principal = {
      userId: '100',
      email: 'admin@shield.test',
      permissions: ['customers.view', 'customers.update'],
    } as any;
    adminGovernanceService.executeCustomerWorkspaceAction.mockResolvedValue({
      status: 'success',
      actionId: 'edit',
    });

    await expect(
      controller.executeCustomerWorkspaceAction(
        'edit',
        { record_id: '42', first_name: 'Amina' },
        principal,
      ),
    ).resolves.toEqual({
      success: true,
      message: 'Admin customer workspace action executed successfully.',
      data: { status: 'success', actionId: 'edit' },
    });

    expect(
      adminGovernanceService.executeCustomerWorkspaceAction,
    ).toHaveBeenCalledWith(
      'edit',
      { record_id: '42', first_name: 'Amina' },
      principal,
    );
  });

  it('executes a customer workspace bulk action', async () => {
    const principal = {
      userId: '100',
      email: 'admin@shield.test',
      permissions: ['customers.view', 'customers.approve'],
    } as any;
    adminGovernanceService.executeCustomerWorkspaceBulkAction.mockResolvedValue({
      status: 'success',
      actionId: 'bulk-suspend',
      affected: 2,
    });

    await expect(
      controller.executeCustomerWorkspaceBulkAction(
        'bulk-suspend',
        { record_ids: ['42', '43'] },
        principal,
      ),
    ).resolves.toEqual({
      success: true,
      message: 'Admin customer workspace bulk action executed successfully.',
      data: { status: 'success', actionId: 'bulk-suspend', affected: 2 },
    });

    expect(
      adminGovernanceService.executeCustomerWorkspaceBulkAction,
    ).toHaveBeenCalledWith(
      'bulk-suspend',
      { record_ids: ['42', '43'] },
      principal,
    );
  });
});
