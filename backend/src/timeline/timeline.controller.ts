import {
  Controller,
  ForbiddenException,
  Get,
  Param,
  Query,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { TimelineService } from './timeline.service';

@Controller('timeline')
export class TimelineController {
  constructor(private readonly timelineService: TimelineService) {}

  @RequirePermissions('customers.view')
  @Get('me')
  async getCustomerTimeline(
    @CurrentPrincipal() principal?: ShieldPrincipal,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    if (principal?.principalType !== 'CUSTOMER' || !principal.customerId) {
      throw new ForbiddenException('Authenticated customer context is required.');
    }

    const hasPaginationQuery = page != null || pageSize != null;
    const parsedPage = Number.parseInt(page ?? '', 10);
    const parsedPageSize = Number.parseInt(pageSize ?? '', 10);
    return {
      success: true,
      message: 'Customer activity timeline retrieved successfully.',
      data: hasPaginationQuery
          ? await this.timelineService.getCustomerTimeline(
              BigInt(principal.customerId),
              parsedPage,
              parsedPageSize,
            )
          : await this.timelineService.getCustomerTimeline(
              BigInt(principal.customerId),
            ),
    };
  }

  @RequirePermissions('providers.view')
  @Get('patient/:customerId')
  async getPatientTimeline(@Param('customerId') customerId: string) {
    const timeline = await this.timelineService.getPatientTimeline(
      BigInt(customerId),
    );
    return {
      success: true,
      message: 'Patient timeline retrieved successfully.',
      data: timeline,
    };
  }

  @RequirePermissions('providers.view')
  @Get('visit/:visitId')
  async getVisitTimeline(@Param('visitId') visitId: string) {
    const timeline = await this.timelineService.getVisitTimeline(BigInt(visitId));
    return {
      success: true,
      message: 'Visit timeline retrieved successfully.',
      data: timeline,
    };
  }

  @RequirePermissions('providers.view')
  @Get('provider')
  async getProviderTimeline(@Query('provider_id') providerId?: string) {
    const timeline = await this.timelineService.getProviderTimeline(
      providerId ? BigInt(providerId) : undefined,
    );
    return {
      success: true,
      message: 'Provider activity timeline retrieved successfully.',
      data: timeline,
    };
  }

  @RequirePermissions('providers.view')
  @Get('business')
  async getBusinessTimeline(@Query('business_id') businessId?: string) {
    const timeline = businessId
      ? await this.timelineService.getBusinessTimeline(BigInt(businessId))
      : [];
    return {
      success: true,
      message: 'Business activity timeline retrieved successfully.',
      data: timeline,
    };
  }
}
