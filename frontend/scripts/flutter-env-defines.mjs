function pushDefine(args, key, value) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    return;
  }
  args.push(`--dart-define=${key}=${value.trim()}`);
}

export function withFlutterEnvDefines(args, env = process.env) {
  const nextArgs = [...args];
  pushDefine(nextArgs, 'APP_ENV', env.APP_ENV);
  pushDefine(nextArgs, 'API_BASE_URL', env.API_BASE_URL);
  pushDefine(nextArgs, 'GOOGLE_MAPS_API_KEY', env.GOOGLE_MAPS_API_KEY);
  pushDefine(nextArgs, 'ENABLE_OCR', env.ENABLE_OCR);
  pushDefine(nextArgs, 'ENABLE_NOTIFICATIONS', env.ENABLE_NOTIFICATIONS);
  pushDefine(nextArgs, 'ENABLE_SENTRY', env.ENABLE_SENTRY);
  pushDefine(nextArgs, 'TURNSTILE_SITE_KEY', env.TURNSTILE_SITE_KEY);
  pushDefine(
    nextArgs,
    'FIREBASE_WEB_VAPID_KEY',
    env.FIREBASE_WEB_VAPID_KEY,
  );
  pushDefine(nextArgs, 'SENTRY_FLUTTER_DSN', env.SENTRY_FLUTTER_DSN);
  pushDefine(nextArgs, 'SENTRY_ENVIRONMENT', env.SENTRY_ENVIRONMENT);
  pushDefine(nextArgs, 'SENTRY_RELEASE', env.SENTRY_RELEASE);
  pushDefine(
    nextArgs,
    'ALLOW_LOCAL_WEB_PHONE_AUTH',
    env.ALLOW_LOCAL_WEB_PHONE_AUTH,
  );
  return nextArgs;
}
