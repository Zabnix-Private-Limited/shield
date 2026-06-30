type ShieldAppEnv = {
  nodeEnv: string;
  appName: string;
  appUrl: string;
  apiBaseUrl: string;
  corsOrigins: string[];
  port: number;
  databaseUrl: string;
  redisUrl: string;
  redisTls: boolean;
  redisPrefix: string;
  redisDefaultTtl: number;
  jwtAccessSecret: string;
  jwtRefreshSecret: string;
  jwtAccessTtl: string;
  jwtRefreshTtl: string;
  otpProvider: string;
  otpApiKey: string;
  otpSenderId: string;
  r2AccountId: string;
  r2AccessKeyId: string;
  r2SecretAccessKey: string;
  r2Bucket: string;
  r2Endpoint: string;
  r2PublicBaseUrl: string;
  firebaseProjectId: string;
  firebaseClientEmail: string;
  firebasePrivateKey: string;
  firebaseServiceAccountJson: string;
  firebaseServiceAccountPath: string;
  smtpHost: string;
  smtpPort: number;
  smtpUser: string;
  smtpPass: string;
  smtpFrom: string;
  turnstileSiteKey: string;
  turnstileSecretKey: string;
  prescriptionAiUrl: string;
  ocrEnabled: boolean;
  ocrTimeoutMs: number;
};

const defaultCorsOrigins = [
  'http://localhost:53431',
  'http://127.0.0.1:53431',
  'http://localhost:3000',
  'http://127.0.0.1:3000',
];

function readString(key: string, fallback = '') {
  return process.env[key]?.trim() || fallback;
}

function readNumber(key: string, fallback: number) {
  const raw = process.env[key]?.trim();
  if (!raw) {
    return fallback;
  }
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function readBoolean(key: string, fallback: boolean) {
  const raw = process.env[key]?.trim().toLowerCase();
  if (!raw) {
    return fallback;
  }
  if (['1', 'true', 'yes', 'on'].includes(raw)) {
    return true;
  }
  if (['0', 'false', 'no', 'off'].includes(raw)) {
    return false;
  }
  return fallback;
}

function readList(key: string, fallback: string[]) {
  const raw = process.env[key]?.trim();
  if (!raw) {
    return fallback;
  }
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

function mergeUnique(values: string[]) {
  return Array.from(new Set(values.map((value) => value.trim()).filter(Boolean)));
}

export function getAppEnv(): ShieldAppEnv {
  return {
    nodeEnv: readString('NODE_ENV', 'development'),
    appName: readString('APP_NAME', 'SHIELD'),
    appUrl: readString('APP_URL', 'http://127.0.0.1:53431'),
    apiBaseUrl: readString('API_BASE_URL', 'http://127.0.0.1:3000'),
    corsOrigins: mergeUnique([
      ...defaultCorsOrigins,
      ...readList('CORS_ORIGIN', []),
    ]),
    port: readNumber('PORT', 3000),
    databaseUrl: readString('DATABASE_URL'),
    redisUrl: readString('REDIS_URL'),
    redisTls: readBoolean('REDIS_TLS', true),
    redisPrefix: readString('REDIS_PREFIX', 'shield:'),
    redisDefaultTtl: readNumber('REDIS_DEFAULT_TTL', 300),
    jwtAccessSecret: readString('JWT_ACCESS_SECRET'),
    jwtRefreshSecret: readString('JWT_REFRESH_SECRET'),
    jwtAccessTtl: readString('JWT_ACCESS_TTL', '15m'),
    jwtRefreshTtl: readString('JWT_REFRESH_TTL', '3650d'),
    otpProvider: readString('OTP_PROVIDER'),
    otpApiKey: readString('OTP_API_KEY'),
    otpSenderId: readString('OTP_SENDER_ID'),
    r2AccountId: readString('R2_ACCOUNT_ID'),
    r2AccessKeyId: readString('R2_ACCESS_KEY_ID'),
    r2SecretAccessKey: readString('R2_SECRET_ACCESS_KEY'),
    r2Bucket: readString('R2_BUCKET'),
    r2Endpoint: readString('R2_ENDPOINT'),
    r2PublicBaseUrl: readString('R2_PUBLIC_BASE_URL'),
    firebaseProjectId: readString('FIREBASE_PROJECT_ID'),
    firebaseClientEmail: readString('FIREBASE_CLIENT_EMAIL'),
    firebasePrivateKey: readString('FIREBASE_PRIVATE_KEY').replace(
      /\\n/g,
      '\n',
    ),
    firebaseServiceAccountJson: readString('FIREBASE_SERVICE_ACCOUNT_JSON'),
    firebaseServiceAccountPath: readString('FIREBASE_SERVICE_ACCOUNT_PATH'),
    smtpHost: readString('SMTP_HOST'),
    smtpPort: readNumber('SMTP_PORT', 587),
    smtpUser: readString('SMTP_USER'),
    smtpPass: readString('SMTP_PASS'),
    smtpFrom: readString('SMTP_FROM'),
    turnstileSiteKey: readString('TURNSTILE_SITE_KEY'),
    turnstileSecretKey: readString('TURNSTILE_SECRET_KEY'),
    prescriptionAiUrl: readString(
      'PRESCRIPTION_AI_URL',
      'http://127.0.0.1:8010',
    ).replace(/\/+$/, ''),
    ocrEnabled: readBoolean('OCR_ENABLED', false),
    ocrTimeoutMs: readNumber('OCR_TIMEOUT_MS', 120000),
  };
}
