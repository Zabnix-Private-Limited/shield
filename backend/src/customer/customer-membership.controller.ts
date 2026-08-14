import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { AgentScopeService } from '../auth/agent-scope.service';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CustomerService } from './customer.service';

@Controller('customer')
export class CustomerMembershipController {
  constructor(
    private readonly customerService: CustomerService,
    private readonly agentScopeService: AgentScopeService,
  ) {}

  private resolveCustomerId(
    customerId?: string,
    principal?: ShieldPrincipal,
  ): bigint {
    if (principal?.principalType === 'CUSTOMER' && principal.customerId) {
      return BigInt(principal.customerId);
    }
    if (customerId?.trim()) {
      return BigInt(customerId);
    }
    throw new BadRequestException(
      'Authenticated customer context is required.',
    );
  }

  private resolveAuthenticatedCustomer(principal?: ShieldPrincipal): bigint {
    if (principal?.principalType === 'CUSTOMER' && principal.customerId) {
      return BigInt(principal.customerId);
    }
    throw new BadRequestException(
      'Authenticated customer context is required.',
    );
  }

  @RequirePermissions('customers.view')
  @Get('membership')
  async getMembership(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const resolvedCustomerId = this.resolveCustomerId(customerId, principal);
    await this.agentScopeService.assertAgentCanAccessCustomer(
      resolvedCustomerId,
      principal,
    );
    return {
      success: true,
      message: 'Customer membership retrieved successfully.',
      data: await this.customerService.getCustomerPortalMembership(
        resolvedCustomerId,
      ),
    };
  }

  @RequirePermissions('customers.view')
  @Get('membership/card')
  async getCard(@CurrentPrincipal() principal?: ShieldPrincipal) {
    const customerId = this.resolveCustomerId(undefined, principal);
    return {
      success: true,
      data: await this.customerService.getCardProfile(customerId),
    };
  }

  @RequirePermissions('customers.view')
  @Get('membership/card/requests')
  async getCardRequests(@CurrentPrincipal() principal?: ShieldPrincipal) {
    const customerId = this.resolveCustomerId(undefined, principal);
    return {
      success: true,
      data: await this.customerService.listPhysicalCardRequests(customerId),
    };
  }

  @RequirePermissions('customers.update')
  @Post('membership/application')
  async submitApplication(@CurrentPrincipal() principal?: ShieldPrincipal) {
    const customerId = this.resolveAuthenticatedCustomer(principal);
    return {
      success: true,
      message: 'Membership application submitted successfully.',
      data: await this.customerService.submitMembershipApplication(customerId),
    };
  }

  @RequirePermissions('customers.view')
  @Get('membership/application')
  async getApplication(@CurrentPrincipal() principal?: ShieldPrincipal) {
    const customerId = this.resolveAuthenticatedCustomer(principal);
    return {
      success: true,
      data: await this.customerService.getCustomerMembershipApplication(
        customerId,
      ),
    };
  }

  @RequirePermissions('customers.approve')
  @Post('membership/application/:applicationId/review')
  async reviewApplication(
    @Param('applicationId') applicationId: string,
    @Body() body: { status?: string; reason?: string },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType !== 'USER' || !principal.userId) {
      throw new BadRequestException('Authorized staff context is required.');
    }
    return {
      success: true,
      data: await this.customerService.reviewMembershipApplication(
        BigInt(applicationId),
        BigInt(principal.userId),
        body.status,
        body.reason,
      ),
    };
  }

  @RequirePermissions('customers.update')
  @Post('membership/card/request')
  async requestCard(@CurrentPrincipal() principal?: ShieldPrincipal) {
    const customerId = this.resolveCustomerId(undefined, principal);
    return {
      success: true,
      data: await this.customerService.requestPhysicalCard(customerId),
    };
  }
}
