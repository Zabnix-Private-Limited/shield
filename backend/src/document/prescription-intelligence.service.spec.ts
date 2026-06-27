import { PrescriptionIntelligenceService } from './prescription-intelligence.service';

describe('PrescriptionIntelligenceService', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
    delete process.env.PRESCRIPTION_AI_URL;
  });

  it('uploads the prescription file and product master to the AI service', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        patient: 'Rahul',
        doctor: 'Dr. Kumar',
        date: '24-06-2026',
        raw_text: 'Patient: Rahul',
        medicines: [],
        medicine_matches: [],
        overall_confidence: 92.5,
        engine: 'pymupdf+paddleocr+rapidfuzz',
      }),
    });
    global.fetch = fetchMock as typeof fetch;

    const service = new PrescriptionIntelligenceService();

    await service.analyzeFile({
      fileName: 'rx.pdf',
      mimeType: 'application/pdf',
      buffer: Buffer.from('sample prescription'),
      products: [
        {
          productId: '12',
          productName: 'Paracetamol 650',
          brand: 'Crocin',
          productCode: 'PCM650',
        },
      ],
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('http://127.0.0.1:8010/analyze-file');
    expect(init?.method).toBe('POST');
    expect(init?.body).toBeInstanceOf(FormData);

    const body = init?.body as FormData;
    expect(body.get('products')).toBe(
      '[{"product_id":"12","product_name":"Paracetamol 650","brand":"Crocin","product_code":"PCM650"}]',
    );

    const file = body.get('file');
    expect(file).toBeInstanceOf(File);
    expect((file as File).name).toBe('rx.pdf');
  });

  it('throws a helpful error when the AI service is unavailable', async () => {
    global.fetch = jest
      .fn()
      .mockRejectedValue(new Error('connect ECONNREFUSED 127.0.0.1:8010')) as typeof fetch;

    const service = new PrescriptionIntelligenceService();

    await expect(
      service.analyzeFile({
        fileName: 'rx.pdf',
        mimeType: 'application/pdf',
        buffer: Buffer.from('sample prescription'),
        products: [],
      }),
    ).rejects.toThrow('Prescription extraction service is unavailable');
  });
});
