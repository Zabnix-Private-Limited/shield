import { writeFileSync } from 'node:fs';
import path from 'node:path';

const webDir = path.join(process.cwd(), 'web');
const outputFile = path.join(webDir, 'sentry-init.js');

const enabled = (process.env.ENABLE_SENTRY ?? '').trim().toLowerCase() === 'true';
const dsn = (process.env.SENTRY_WEB_DSN ?? '').trim();
const environment = (process.env.SENTRY_ENVIRONMENT ?? 'development').trim();
const release = (process.env.SENTRY_RELEASE ?? '1.0.0').trim();
const apiBaseUrl = (process.env.API_BASE_URL ?? '').trim();

const script = `(() => {
  const config = {
    enabled: ${enabled ? 'true' : 'false'},
    dsn: ${JSON.stringify(dsn)},
    environment: ${JSON.stringify(environment)},
    release: ${JSON.stringify(release)},
    apiBaseUrl: ${JSON.stringify(apiBaseUrl)},
  };

  if (!config.enabled || !config.dsn || typeof window === 'undefined' || typeof Sentry === 'undefined') {
    return;
  }

  const traceTargets = [window.location.origin, /^https?:\\/\\/127\\.0\\.0\\.1:3000/, /^https?:\\/\\/localhost:3000/];
  if (config.apiBaseUrl) {
    traceTargets.push(config.apiBaseUrl);
  }

  Sentry.init({
    dsn: config.dsn,
    environment: config.environment,
    release: config.release,
    sendDefaultPii: true,
    integrations: [
      Sentry.browserTracingIntegration(),
      Sentry.replayIntegration({
        maskAllText: true,
        blockAllMedia: true,
      }),
    ],
    tracesSampleRate: config.environment === 'production' ? 0.2 : 1.0,
    tracePropagationTargets: traceTargets,
    replaysSessionSampleRate: config.environment === 'production' ? 0.05 : 0.25,
    replaysOnErrorSampleRate: 1.0,
  });
})();
`;

writeFileSync(outputFile, script, 'utf8');
