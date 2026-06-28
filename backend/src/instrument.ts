import * as Sentry from '@sentry/nestjs';
import { nodeProfilingIntegration } from '@sentry/profiling-node';

const sentryEnabled =
  (process.env.ENABLE_SENTRY ?? '').trim().toLowerCase() === 'true';
const environment = (process.env.SENTRY_ENVIRONMENT ?? process.env.NODE_ENV ?? 'development').trim();
const isProduction = environment === 'production';

Sentry.init({
  enabled: sentryEnabled,
  dsn: (process.env.SENTRY_BACKEND_DSN ?? '').trim() || undefined,
  environment,
  release: (process.env.SENTRY_RELEASE ?? '1.0.0').trim(),
  sendDefaultPii: true,
  tracesSampleRate: isProduction ? 0.2 : 1.0,
  profileSessionSampleRate: isProduction ? 0.2 : 1.0,
  profileLifecycle: 'trace',
  enableLogs: true,
  integrations: [nodeProfilingIntegration(), Sentry.prismaIntegration()],
});
