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
    delete process.env.OCR_ENABLED;
    delete process.env.OCR_TIMEOUT_MS;

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { getAppEnv } = require('./app-env');
    const env = getAppEnv();

    expect(env.port).toBe(3000);
    expect(env.corsOrigins).toEqual([
      'http://localhost:53431',
      'http://127.0.0.1:53431',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
    ]);
    expect(env.prescriptionAiUrl).toBe('http://127.0.0.1:8010');
    expect(env.ocrEnabled).toBe(false);
    expect(env.ocrTimeoutMs).toBe(120000);
  });

  it('parses configured values for core, cors, and OCR settings', async () => {
    process.env.PORT = '4200';
    process.env.CORS_ORIGIN = 'https://shield.example.com, https://portal.example.com';
    process.env.PRESCRIPTION_AI_URL = 'https://ocr.example.com/';
    process.env.OCR_ENABLED = 'true';
    process.env.OCR_TIMEOUT_MS = '90000';

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { getAppEnv } = require('./app-env');
    const env = getAppEnv();

    expect(env.port).toBe(4200);
    expect(env.corsOrigins).toEqual([
      'http://localhost:53431',
      'http://127.0.0.1:53431',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      'https://shield.example.com',
      'https://portal.example.com',
    ]);
    expect(env.prescriptionAiUrl).toBe('https://ocr.example.com');
    expect(env.ocrEnabled).toBe(true);
    expect(env.ocrTimeoutMs).toBe(90000);
  });
});
