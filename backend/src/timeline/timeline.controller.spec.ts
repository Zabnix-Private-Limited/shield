import { ForbiddenException } from '@nestjs/common';
import { TimelineController } from './timeline.controller';

describe('TimelineController', () => {
  const timelineService = {
    getCustomerTimeline: jest.fn(),
  };
  const controller = new TimelineController(timelineService as any);

  beforeEach(() => jest.clearAllMocks());

  it('loads only the authenticated customer timeline', async () => {
    timelineService.getCustomerTimeline.mockResolvedValue([{ id: 'document:1:0' }]);

    await expect(
      controller.getCustomerTimeline({
        principalType: 'CUSTOMER',
        customerId: '42',
      } as any),
    ).resolves.toMatchObject({ data: [{ id: 'document:1:0' }] });
    expect(timelineService.getCustomerTimeline).toHaveBeenCalledWith(42n);
  });

  it('rejects a missing customer context', async () => {
    await expect(controller.getCustomerTimeline(undefined)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
