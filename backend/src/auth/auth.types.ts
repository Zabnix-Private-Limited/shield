export const USER_TYPES = [
  'CUSTOMER',
  'EMPLOYEE',
  'SERVICE_PROVIDER',
  'SYSTEM',
] as const;

export type ShieldUserType = (typeof USER_TYPES)[number];

export const ACCESS_SCOPES = [
  'GLOBAL',
  'ORGANIZATION',
  'CLUSTER',
  'BRANCH',
  'SELF',
] as const;

export type ShieldAccessScope = (typeof ACCESS_SCOPES)[number];

export type ShieldPrincipalType = 'CUSTOMER' | 'USER' | 'SYSTEM';

export type ShieldPrincipal = {
  subjectId: string;
  sessionId: string;
  principalType: ShieldPrincipalType;
  roleCode: string;
  userType: ShieldUserType;
  accessScope: ShieldAccessScope;
  permissions: string[];
  firebaseUid: string;
  authProvider: string;
  customerId?: string;
  userId?: string;
  email?: string;
  mobile?: string;
  branchBusinessId?: string;
};

export type ShieldJwtPayload = {
  sub: string;
  sid: string;
  pty: ShieldPrincipalType;
  role: string;
  userType: ShieldUserType;
  scope: ShieldAccessScope;
  permissions: string[];
  firebaseUid: string;
  authProvider: string;
  customerId?: string;
  userId?: string;
  email?: string;
  mobile?: string;
  branchBusinessId?: string;
};

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresIn: string;
  refreshTokenExpiresIn: string;
  principal: ShieldPrincipal;
};

export type AuthenticatedSession = {
  sessionId: string;
  principal: ShieldPrincipal;
};
