import { DocumentController } from './document.controller';

describe('DocumentController customer scope', () => {
  const service = {
    documentBelongsToCustomer: jest.fn(),
    findOne: jest.fn(),
    getDownloadUrl: jest.fn(),
    extract: jest.fn(),
    getPrescriptionReview: jest.fn(),
    getLogs: jest.fn(),
    softDelete: jest.fn(),
    upload: jest.fn(),
    list: jest.fn(),
  };
  const agentScope = {
    assertAgentCanAccessDocument: jest.fn(),
    assertAgentCanAccessCustomer: jest.fn(),
  };
  const providerScope = {
    assertProviderCanAccessDocument: jest.fn(),
    assertProviderCanAccessCustomer: jest.fn(),
  };
  const controller = new DocumentController(
    service as any,
    agentScope as any,
    providerScope as any,
  );
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('rejects a customer reading another customer document', async () => {
    service.documentBelongsToCustomer.mockResolvedValue(false);

    await expect(controller.findOne('7', customer)).rejects.toThrow(
      'Customers can only access their own documents.',
    );
    expect(service.findOne).not.toHaveBeenCalled();
  });

  it('rejects a customer downloading another customer document', async () => {
    service.documentBelongsToCustomer.mockResolvedValue(false);

    await expect(controller.download('7', customer)).rejects.toThrow(
      'Customers can only access their own documents.',
    );
    expect(service.getDownloadUrl).not.toHaveBeenCalled();
  });

  it.each([
    [
      'extracting document data',
      () => controller.extract({ document_id: '7' }, customer),
    ],
    [
      'viewing a prescription review',
      () => controller.getPrescriptionReview('7', customer),
    ],
    [
      'viewing document processing logs',
      () => controller.getLogs('7', customer),
    ],
  ])(
    'rejects a customer %s for another customer document',
    async (_, action) => {
      service.documentBelongsToCustomer.mockResolvedValue(false);

      await expect(action()).rejects.toThrow(
        'Customers can only access their own documents.',
      );
    },
  );

  it('does not return a storage path to a customer', async () => {
    service.documentBelongsToCustomer.mockResolvedValue(true);
    service.findOne.mockResolvedValue({
      id: BigInt(7),
      storagePath: 'private/object',
      fileName: 'report.pdf',
    });
    agentScope.assertAgentCanAccessDocument.mockResolvedValue(undefined);
    providerScope.assertProviderCanAccessDocument.mockResolvedValue(undefined);

    const response = await controller.findOne('7', customer);

    expect(response.data).toMatchObject({
      id: BigInt(7),
      title: 'report.pdf',
      fileName: 'report.pdf',
    });
    expect(response.data).not.toHaveProperty('storagePath');
    expect(response.data).not.toHaveProperty('customer');
    expect(response.data).not.toHaveProperty('documentProcessingLogs');
  });

  it('rejects a customer archiving another customer document', async () => {
    service.documentBelongsToCustomer.mockResolvedValue(false);

    await expect(controller.softDelete('7', customer)).rejects.toThrow(
      'Customers can only access their own documents.',
    );
    expect(service.softDelete).not.toHaveBeenCalled();
  });

  it('does not expose internal processing routes to a document owner', async () => {
    service.documentBelongsToCustomer.mockResolvedValue(true);

    await expect(controller.getLogs('7', customer)).rejects.toThrow(
      'Document processing details are not available in the customer archive.',
    );
  });

  it('binds a customer upload to the authenticated customer, not body input', async () => {
    service.upload.mockResolvedValue({ id: BigInt(8), fileName: 'record.pdf' });
    agentScope.assertAgentCanAccessCustomer.mockResolvedValue(undefined);
    providerScope.assertProviderCanAccessCustomer.mockResolvedValue(undefined);

    await controller.upload(
      {
        originalname: 'record.pdf',
        size: 32,
        mimetype: 'application/pdf',
        buffer: Buffer.from('synthetic'),
      },
      { customer_id: '99', document_type: 'LAB_REPORT' },
      customer,
    );

    expect(service.upload).toHaveBeenCalledWith(
      expect.objectContaining({
        customerId: BigInt(11),
        documentType: 'LAB_REPORT',
      }),
    );
  });

  it('rejects an unsafe customer upload before storage is called', async () => {
    await expect(
      controller.upload(
        {
          originalname: 'malware.exe',
          size: 32,
          mimetype: 'application/octet-stream',
          buffer: Buffer.from('synthetic'),
        },
        { document_type: 'OTHER' },
        customer,
      ),
    ).rejects.toThrow(
      'Only PDF, JPEG, PNG, and WebP document files are accepted.',
    );
    expect(service.upload).not.toHaveBeenCalled();
  });

  it('uses the authenticated customer for list queries', async () => {
    service.list.mockResolvedValue([]);
    agentScope.assertAgentCanAccessCustomer.mockResolvedValue(undefined);
    providerScope.assertProviderCanAccessCustomer.mockResolvedValue(undefined);

    await controller.list('99', customer);

    expect(service.list).toHaveBeenCalledWith(BigInt(11), customer);
  });
});
