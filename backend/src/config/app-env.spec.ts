describe('app env helpers', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('uses sensible defaults when optional values are absent', async () => {
    delete process.env.PORT;
    delete process.env.CORS_ORIGIN;
    delete process.env.PRESCRIPTION_AI_URL;

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { getAppEnv } = require('./app-env');
    const env = getAppEnv();

    expect(env.port).toBe(3000);
    expect(env.corsOrigins).toEqual([
      'http://localhost:53431',
      'http://127.0.0.1:53431',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'https://shield-zabnix.vercel.app',
    ]);
    expect(env.prescriptionAiUrl).toBe('http://127.0.0.1:8010');
  });

  it('parses configured values for core, cors, and prescription AI settings', async () => {
    process.env.PORT = '4200';
    process.env.CORS_ORIGIN = 'https://shield.example.com, https://portal.example.com';
    process.env.PRESCRIPTION_AI_URL = 'https://ai.example.com/';

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { getAppEnv } = require('./app-env');
    const env = getAppEnv();

    expect(env.port).toBe(4200);
    expect(env.corsOrigins).toEqual([
      'http://localhost:53431',
      'http://127.0.0.1:53431',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'https://shield-zabnix.vercel.app',
      'https://shield.example.com',
      'https://portal.example.com',
    ]);
    expect(env.prescriptionAiUrl).toBe('https://ai.example.com');
  });
});
