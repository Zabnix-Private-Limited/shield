import { DocumentController } from './document.controller';

describe('DocumentController customer scope', () => {
  const service = {
    documentBelongsToCustomer: jest.fn(),
    findOne: jest.fn(),
    getDownloadUrl: jest.fn(),
    extract: jest.fn(),
    getPrescriptionReview: jest.fn(),
    getLogs: jest.fn(),
  };
  const agentScope = { assertAgentCanAccessDocument: jest.fn() };
  const providerScope = { assertProviderCanAccessDocument: jest.fn() };
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

    expect(response.data).toEqual({ id: BigInt(7), fileName: 'report.pdf' });
  });
});
