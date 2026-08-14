import { BadRequestException, Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { AgentScopeService } from '../auth/agent-scope.service';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CustomerService } from './customer.service';

@Controller()
export class StoreChangeController {
  constructor(
    private readonly customerService: CustomerService,
    private readonly agentScopeService: AgentScopeService,
  ) {}

  private customerId(principal?: ShieldPrincipal) {
    if (principal?.principalType === 'CUSTOMER' && principal.customerId) {
      return BigInt(principal.customerId);
    }
    throw new BadRequestException('Authenticated customer context is required.');
  }

  @RequirePermissions('customers.view')
  @Get('customer/store-change-requests')
  async listCustomerRequests(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return { success: true, data: await this.customerService.listStoreChangeRequests(this.customerId(principal)) };
  }

  @RequirePermissions('customers.update')
  @Post('customer/store-change-requests')
  async submitCustomerRequest(
    @Body() body: { providerId?: string; reason?: string },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (!body.providerId?.trim()) throw new BadRequestException('Requested pharmacy is required.');
    return {
      success: true,
      data: await this.customerService.submitStoreChangeRequest(
        this.customerId(principal), BigInt(body.providerId), body.reason ?? '',
      ),
    };
  }

  @RequirePermissions('customers.approve')
  @Get('store-change-requests')
  async listForStaff(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (customerId?.trim()) {
      await this.agentScopeService.assertAgentCanAccessCustomer(BigInt(customerId), principal);
      return { success: true, data: await this.customerService.listStoreChangeRequestsForStaff([BigInt(customerId)]) };
    }
    const customerIds = this.agentScopeService.isAgentPrincipal(principal)
      ? await this.agentScopeService.listAccessibleCustomerIds(principal)
      : undefined;
    return { success: true, data: await this.customerService.listStoreChangeRequestsForStaff(customerIds) };
  }

  @RequirePermissions('customers.approve')
  @Post('store-change-requests/:id/review')
  async review(
    @Param('id') id: string,
    @Body() body: { status?: string; reason?: string },
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (principal?.principalType !== 'USER' || !principal.userId) {
      throw new BadRequestException('Authorized staff context is required.');
    }
    const requestId = BigInt(id);
    await this.agentScopeService.assertAgentCanAccessCustomer(
      await this.customerService.getStoreChangeRequestCustomerId(requestId), principal,
    );
    return { success: true, data: await this.customerService.reviewStoreChangeRequest(requestId, BigInt(principal.userId), body.status, body.reason) };
  }
}
