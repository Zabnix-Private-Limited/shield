import { ForbiddenException } from '@nestjs/common';
import { TimelineController } from './timeline.controller';

describe('TimelineController', () => {
  const timelineService = {
    getPatientTimeline: jest.fn(),
  };
  const controller = new TimelineController(timelineService as any);

  beforeEach(() => jest.clearAllMocks());

  it('loads only the authenticated customer timeline', async () => {
    timelineService.getPatientTimeline.mockResolvedValue([{ eventType: 'DOCUMENT_UPLOADED' }]);

    await expect(
      controller.getCustomerTimeline({
        principalType: 'CUSTOMER',
        customerId: '42',
      } as any),
    ).resolves.toMatchObject({ data: [{ eventType: 'DOCUMENT_UPLOADED' }] });
    expect(timelineService.getPatientTimeline).toHaveBeenCalledWith(42n);
  });

  it('rejects a missing customer context', async () => {
    await expect(controller.getCustomerTimeline(undefined)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
