import { existsSync } from 'node:fs';
import { runCommand } from './vercel-shared.mjs';

const enabled = (process.env.ENABLE_SENTRY ?? '').trim().toLowerCase() === 'true';
const authToken = (process.env.SENTRY_AUTH_TOKEN ?? '').trim();
const org = (process.env.SENTRY_ORG ?? '').trim();
const project = (process.env.SENTRY_PROJECT_WEB ?? '').trim();
const release = (process.env.SENTRY_RELEASE ?? '').trim();

if (
  !enabled ||
  !authToken ||
  !org ||
  !project ||
  !release ||
  !existsSync('build/web')
) {
  process.exit(0);
}

runCommand(
  process.platform === 'win32' ? 'npx.cmd' : 'npx',
  ['@sentry/cli', 'sourcemaps', 'inject', 'build/web'],
  {
    env: {
      ...process.env,
      SENTRY_AUTH_TOKEN: authToken,
      SENTRY_ORG: org,
      SENTRY_PROJECT: project,
    },
  },
);

runCommand(
  process.platform === 'win32' ? 'npx.cmd' : 'npx',
  [
    '@sentry/cli',
    'sourcemaps',
    'upload',
    'build/web',
    '--release',
    release,
    '--org',
    org,
    '--project',
    project,
  ],
  {
    env: {
      ...process.env,
      SENTRY_AUTH_TOKEN: authToken,
      SENTRY_ORG: org,
      SENTRY_PROJECT: project,
    },
  },
);
