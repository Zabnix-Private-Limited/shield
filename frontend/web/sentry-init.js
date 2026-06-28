(() => {
  const config = {
    enabled: true,
    dsn: "https://b2b7c2f2c1a254d0facd76687291f661@o4511172712923136.ingest.us.sentry.io/4511641997672448",
    environment: "development",
    release: "1.0.0",
    apiBaseUrl: "",
  };

  if (!config.enabled || !config.dsn || typeof window === 'undefined' || typeof Sentry === 'undefined') {
    return;
  }

  const traceTargets = [window.location.origin, /^https?:\/\/127\.0\.0\.1:3000/, /^https?:\/\/localhost:3000/];
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
