import { ShieldAccessScope, ShieldUserType } from './auth.types';

type PermissionAction =
  | 'view'
  | 'create'
  | 'update'
  | 'delete'
  | 'approve'
  | 'export';

type PermissionResource =
  | 'customers'
  | 'wallet'
  | 'membership'
  | 'appointments'
  | 'medical_records'
  | 'documents'
  | 'reports'
  | 'crm'
  | 'agents'
  | 'providers'
  | 'referrals'
  | 'analytics'
  | 'settings'
  | 'notifications';

type PermissionDefinition = {
  code: string;
  name: string;
  description: string;
};

type RoleDefinition = {
  code: string;
  name: string;
  description: string;
  userType: ShieldUserType;
  defaultScope: ShieldAccessScope;
  isSystemRole?: boolean;
  permissions: string[];
};

const RESOURCE_ACTIONS: Record<PermissionResource, PermissionAction[]> = {
  customers: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  wallet: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  membership: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  appointments: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  medical_records: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  documents: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  reports: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  crm: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  agents: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  providers: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  referrals: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  analytics: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  settings: ['view', 'create', 'update', 'delete', 'approve', 'export'],
  notifications: ['view', 'create', 'update', 'delete', 'approve', 'export'],
};

const RESOURCES = Object.keys(RESOURCE_ACTIONS) as PermissionResource[];

function makePermissionCode(
  resource: PermissionResource,
  action: PermissionAction,
) {
  return `${resource}.${action}`;
}

function permissionsFor(
  resources: PermissionResource[],
  actions?: PermissionAction[],
) {
  return resources.flatMap((resource) =>
    (actions ?? RESOURCE_ACTIONS[resource]).map((action) =>
      makePermissionCode(resource, action),
    ),
  );
}

function allPermissions() {
  return permissionsFor(RESOURCES);
}

const AGENT_PORTAL_PERMISSIONS: PermissionDefinition[] = [
  {
    code: 'agent.dashboard.view',
    name: 'VIEW agent dashboard',
    description: 'View the agent portal dashboard.',
  },
  {
    code: 'agent.customer.view',
    name: 'VIEW agent customers',
    description: 'View customers inside the agent portal.',
  },
  {
    code: 'agent.customer.create',
    name: 'CREATE agent customers',
    description: 'Create customers from the agent portal.',
  },
  {
    code: 'agent.customer.update',
    name: 'UPDATE agent customers',
    description: 'Update scoped customers from the agent portal.',
  },
  {
    code: 'agent.followup.view',
    name: 'VIEW agent follow-ups',
    description: 'View agent follow-ups and scheduled tasks.',
  },
  {
    code: 'agent.followup.create',
    name: 'CREATE agent follow-ups',
    description: 'Create agent follow-ups and tasks.',
  },
  {
    code: 'agent.followup.update',
    name: 'UPDATE agent follow-ups',
    description: 'Update agent follow-up outcomes and tasks.',
  },
  {
    code: 'agent.referral.view',
    name: 'VIEW agent referrals',
    description: 'View the scoped referral network in the agent portal.',
  },
  {
    code: 'agent.document.view',
    name: 'VIEW agent documents',
    description: 'View scoped customer documents in the agent portal.',
  },
  {
    code: 'agent.document.upload',
    name: 'UPLOAD agent documents',
    description: 'Upload scoped customer documents in the agent portal.',
  },
  {
    code: 'agent.notification.view',
    name: 'VIEW agent notifications',
    description: 'View scoped notifications in the agent portal.',
  },
  {
    code: 'agent.performance.view',
    name: 'VIEW agent performance',
    description: 'View agent performance and incentive summaries.',
  },
];

export const RBAC_PERMISSIONS: PermissionDefinition[] = [
  ...RESOURCES.flatMap(
  (resource) =>
    RESOURCE_ACTIONS[resource].map((action) => ({
      code: makePermissionCode(resource, action),
      name: `${action.toUpperCase()} ${resource.replace(/_/g, ' ')}`,
      description: `${action} access for ${resource.replace(/_/g, ' ')}.`,
    })),
  ),
  ...AGENT_PORTAL_PERMISSIONS,
];

export const RBAC_ROLES: RoleDefinition[] = [
  {
    code: 'ADMIN',
    name: 'Administrator',
    description:
      'Full-platform SHIELD administrator. Layouts may differ, permissions do not.',
    userType: 'EMPLOYEE',
    defaultScope: 'GLOBAL',
    permissions: allPermissions(),
  },
  {
    code: 'SHIELD_AGENT',
    name: 'SHIELD Agent',
    description:
      'Enrollment and referral-growth role limited to the agent customer graph.',
    userType: 'EMPLOYEE',
    defaultScope: 'SELF',
    permissions: [
      'agent.dashboard.view',
      'agent.customer.view',
      'agent.customer.create',
      'agent.customer.update',
      'agent.followup.view',
      'agent.followup.create',
      'agent.followup.update',
      'agent.referral.view',
      'agent.document.view',
      'agent.document.upload',
      'agent.notification.view',
      'agent.performance.view',
      ...permissionsFor(['customers'], ['view', 'create', 'update']),
      ...permissionsFor(['membership'], ['view']),
      ...permissionsFor(['wallet'], ['view']),
      ...permissionsFor(['referrals'], ['view', 'export']),
      ...permissionsFor(['agents'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
      ...permissionsFor(['documents'], ['view', 'create']),
      ...permissionsFor(['appointments'], ['view', 'create', 'update']),
      ...permissionsFor(['crm'], ['view', 'create', 'update']),
      ...permissionsFor(['notifications'], ['view', 'update']),
      ...permissionsFor(['settings'], ['view', 'update']),
    ],
  },
  {
    code: 'CRM_EXECUTIVE',
    name: 'CRM Executive',
    description:
      'Assigned-customer follow-up, retention, and complaint-management role.',
    userType: 'EMPLOYEE',
    defaultScope: 'SELF',
    permissions: [
      ...permissionsFor(['customers'], ['view', 'update']),
      ...permissionsFor(['crm'], ['view', 'create', 'update', 'export']),
      ...permissionsFor(['appointments'], ['view']),
      ...permissionsFor(['membership'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
      ...permissionsFor(['notifications'], ['view', 'create', 'update']),
    ],
  },
  {
    code: 'PHARMACY_PROVIDER',
    name: 'Pharmacist',
    description:
      'Pharmacy service-provider role for prescriptions, wallet redemption, and billing.',
    userType: 'SERVICE_PROVIDER',
    defaultScope: 'BRANCH',
    permissions: [
      ...permissionsFor(['customers'], ['view']),
      ...permissionsFor(['wallet'], ['view', 'update']),
      ...permissionsFor(['documents'], ['view', 'create']),
      ...permissionsFor(['medical_records'], ['view', 'create', 'approve']),
      ...permissionsFor(['providers'], ['view', 'create', 'update']),
      ...permissionsFor(['settings'], ['view', 'update']),
      ...permissionsFor(['appointments'], ['view']),
      ...permissionsFor(['notifications'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
    ],
  },
  {
    code: 'LAB_PROVIDER',
    name: 'Laboratory',
    description:
      'Lab operations role for assigned customers, documents, and reports.',
    userType: 'SERVICE_PROVIDER',
    defaultScope: 'BRANCH',
    permissions: [
      ...permissionsFor(['customers'], ['view']),
      ...permissionsFor(['appointments'], ['view', 'update']),
      ...permissionsFor(['documents'], ['view', 'create', 'update']),
      ...permissionsFor(['medical_records'], ['view', 'create', 'update']),
      ...permissionsFor(['providers'], ['view']),
      ...permissionsFor(['settings'], ['view', 'update']),
      ...permissionsFor(['notifications'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
    ],
  },
  {
    code: 'DOCTOR',
    name: 'Doctor',
    description:
      'Doctor role for assigned-patient care, consultation outcomes, and prescriptions.',
    userType: 'SERVICE_PROVIDER',
    defaultScope: 'BRANCH',
    permissions: [
      ...permissionsFor(['customers'], ['view']),
      ...permissionsFor(['appointments'], ['view', 'update', 'approve']),
      ...permissionsFor(['documents'], ['view', 'create']),
      ...permissionsFor(['medical_records'], ['view', 'create', 'update', 'approve']),
      ...permissionsFor(['providers'], ['view']),
      ...permissionsFor(['settings'], ['view', 'update']),
      ...permissionsFor(['notifications'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
    ],
  },
  {
    code: 'HOMECARE_PROVIDER',
    name: 'Home Care',
    description:
      'Homecare role for assigned visits, notes, and document uploads.',
    userType: 'SERVICE_PROVIDER',
    defaultScope: 'BRANCH',
    permissions: [
      ...permissionsFor(['customers'], ['view']),
      ...permissionsFor(['appointments'], ['view', 'update']),
      ...permissionsFor(['documents'], ['view', 'create', 'update']),
      ...permissionsFor(['medical_records'], ['view', 'create', 'update']),
      ...permissionsFor(['providers'], ['view']),
      ...permissionsFor(['settings'], ['view', 'update']),
      ...permissionsFor(['notifications'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
    ],
  },
  {
    code: 'DENTAL_PROVIDER',
    name: 'Dentist',
    description:
      'Dental role for assigned customers, records, and visit documentation.',
    userType: 'SERVICE_PROVIDER',
    defaultScope: 'BRANCH',
    permissions: [
      ...permissionsFor(['customers'], ['view']),
      ...permissionsFor(['appointments'], ['view', 'update']),
      ...permissionsFor(['documents'], ['view', 'create', 'update']),
      ...permissionsFor(['medical_records'], ['view', 'create', 'update']),
      ...permissionsFor(['providers'], ['view']),
      ...permissionsFor(['settings'], ['view', 'update']),
      ...permissionsFor(['notifications'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
    ],
  },
  {
    code: 'COSMETIC_PROVIDER',
    name: 'Cosmetic Clinic',
    description:
      'Cosmetic provider role for assigned customers and service documentation.',
    userType: 'SERVICE_PROVIDER',
    defaultScope: 'BRANCH',
    permissions: [
      ...permissionsFor(['customers'], ['view']),
      ...permissionsFor(['appointments'], ['view', 'update']),
      ...permissionsFor(['documents'], ['view', 'create', 'update']),
      ...permissionsFor(['medical_records'], ['view', 'create', 'update']),
      ...permissionsFor(['providers'], ['view']),
      ...permissionsFor(['settings'], ['view', 'update']),
      ...permissionsFor(['notifications'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
    ],
  },
  {
    code: 'DIETITIAN',
    name: 'Dietitian',
    description:
      'Dietitian role for assigned customers, plans, and care documents.',
    userType: 'SERVICE_PROVIDER',
    defaultScope: 'BRANCH',
    permissions: [
      ...permissionsFor(['customers'], ['view']),
      ...permissionsFor(['appointments'], ['view', 'update']),
      ...permissionsFor(['documents'], ['view', 'create', 'update']),
      ...permissionsFor(['medical_records'], ['view', 'create', 'update']),
      ...permissionsFor(['providers'], ['view']),
      ...permissionsFor(['settings'], ['view', 'update']),
      ...permissionsFor(['notifications'], ['view']),
      ...permissionsFor(['analytics'], ['view']),
    ],
  },
  {
    code: 'CUSTOMER',
    name: 'Customer',
    description:
      'Self-service customer role with wallet, services, records, referrals, and notifications.',
    userType: 'CUSTOMER',
    defaultScope: 'SELF',
    permissions: [
      ...permissionsFor(['customers'], ['view', 'update']),
      ...permissionsFor(['wallet'], ['view']),
      ...permissionsFor(['membership'], ['view']),
      ...permissionsFor(['appointments'], ['view', 'create', 'update']),
      ...permissionsFor(['medical_records'], ['view', 'create']),
      ...permissionsFor(['documents'], ['view', 'create']),
      ...permissionsFor(['referrals'], ['view']),
      ...permissionsFor(['notifications'], ['view', 'create', 'update']),
      ...permissionsFor(['providers'], ['view']),
    ],
  },
  {
    code: 'SYSTEM',
    name: 'System',
    description: 'System-level non-human execution role.',
    userType: 'SYSTEM',
    defaultScope: 'GLOBAL',
    isSystemRole: true,
    permissions: [
      ...permissionsFor(['notifications'], ['create', 'update']),
      ...permissionsFor(['reports'], ['export']),
    ],
  },
  {
    code: 'BACKGROUND_WORKER',
    name: 'Background Worker',
    description: 'Queue and scheduled-job execution role.',
    userType: 'SYSTEM',
    defaultScope: 'GLOBAL',
    isSystemRole: true,
    permissions: [
      ...permissionsFor(['notifications'], ['create', 'update']),
      ...permissionsFor(['reports'], ['export']),
    ],
  },
  {
    code: 'NOTIFICATION_SERVICE',
    name: 'Notification Service',
    description: 'Internal notification delivery service role.',
    userType: 'SYSTEM',
    defaultScope: 'GLOBAL',
    isSystemRole: true,
    permissions: permissionsFor(['notifications'], ['view', 'create', 'update']),
  },
  {
    code: 'WEBHOOK_SERVICE',
    name: 'Webhook Service',
    description: 'Internal webhook automation role.',
    userType: 'SYSTEM',
    defaultScope: 'GLOBAL',
    isSystemRole: true,
    permissions: [
      ...permissionsFor(['notifications'], ['create', 'update']),
      ...permissionsFor(['reports'], ['export']),
    ],
  },
];

export function getRolePermissions(roleCode: string) {
  return (
    RBAC_ROLES.find((role) => role.code === roleCode)?.permissions.slice() ?? []
  );
}
