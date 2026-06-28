import { existsSync } from 'node:fs';
import { bundledFlutter, runFlutter } from './vercel-shared.mjs';
import { withFlutterEnvDefines } from './flutter-env-defines.mjs';
import './generate-web-sentry-config.mjs';

if (!existsSync(bundledFlutter) && process.env.VERCEL) {
  throw new Error('Bundled Flutter SDK is missing. The install step did not complete successfully.');
}

runFlutter(['config', '--enable-web']);
runFlutter(['pub', 'get']);
runFlutter(withFlutterEnvDefines(['build', 'web', '--release', '--source-maps']));
await import('./upload-web-sourcemaps.mjs');
