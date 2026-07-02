import {
  Controller,
  ForbiddenException,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UnauthorizedException,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AgentScopeService } from '../auth/agent-scope.service';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { CustomerService } from './customer.service';

@Controller('customers')
export class CustomerController {
  constructor(
    private customerService: CustomerService,
    private readonly agentScopeService: AgentScopeService,
    private readonly providerScopeService: ProviderScopeService,
  ) {}

  @RequirePermissions('customers.create')
  @Post()
  async create(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const scopedBody = { ...body };
    const isAgent = this.agentScopeService.isAgentPrincipal(principal);
    const agentCode = isAgent
      ? await this.agentScopeService.resolveAgentCode(principal)
      : undefined;
    const staffId =
      principal?.userId != null
        ? BigInt(principal.userId)
        : body.created_by
          ? BigInt(body.created_by)
          : undefined;
    if (agentCode) {
      scopedBody.agent_code = agentCode;
    }
    const customer = await this.customerService.create(scopedBody, staffId);
    return {
      success: true,
      message: 'Customer created successfully',
      data: customer,
    };
  }

  @RequirePermissions('customers.view')
  @Get('search')
  async search(
    @Query('mobile') mobile?: string,
    @Query('name') name?: string,
    @Query('aadhaar') aadhaar?: string,
    @Query('membership') membership?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const results = await this.customerService.search({
      mobile,
      name,
      aadhaar,
      membership,
    });
    const data =
      this.providerScopeService.isProviderPrincipal(principal) ||
          this.agentScopeService.isAgentPrincipal(principal)
      ? await (async () => {
          const customerIds = results.map((item) => item.id);
          const allowedIds = new Set(
            (
              this.providerScopeService.isProviderPrincipal(principal)
                ? await this.providerScopeService.listAccessibleCustomerIds(
                    principal,
                    customerIds,
                  )
                : await this.agentScopeService.listAccessibleCustomerIds(
                    principal,
                    customerIds,
                  )
            ).map((id) => id.toString()),
          );
          return results.filter((item) => allowedIds.has(item.id.toString()));
        })()
      : results;
    return {
      success: true,
      message: 'Search completed',
      data,
    };
  }

  @RequirePermissions('customers.view')
  @Get('me')
  async me(@CurrentPrincipal() principal?: ShieldPrincipal) {
    if (!principal?.customerId) {
      throw new ForbiddenException('Only customers can use /customers/me.');
    }

    const customer = await this.customerService.findOne(BigInt(principal.customerId));
    return {
      success: true,
      message: 'Customer details retrieved',
      data: customer,
    };
  }

  @RequirePermissions('customers.view')
  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (
      principal?.principalType === 'CUSTOMER' &&
      principal.customerId !== id
    ) {
      throw new ForbiddenException('Customers can only view their own profile.');
    }

    await this.providerScopeService.assertProviderCanAccessCustomer(
      BigInt(id),
      principal,
    );
    await this.agentScopeService.assertAgentCanAccessCustomer(BigInt(id), principal);
    const customer = await this.customerService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Customer details retrieved',
      data: customer,
    };
  }

  @RequirePermissions('customers.update')
  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (
      principal?.principalType === 'CUSTOMER' &&
      principal.customerId !== id
    ) {
      throw new ForbiddenException('Customers can only update their own profile.');
    }

    await this.providerScopeService.assertProviderCanAccessCustomer(
      BigInt(id),
      principal,
    );
    await this.agentScopeService.assertAgentCanAccessCustomer(BigInt(id), principal);
    const customer = await this.customerService.update(BigInt(id), body);
    return {
      success: true,
      message: 'Customer profile updated successfully',
      data: customer,
    };
  }

  @RequirePermissions('customers.approve')
  @Post(':id/approve')
  async approve(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const staffId = body.staff_id
      ? BigInt(body.staff_id)
      : principal?.userId
        ? BigInt(principal.userId)
        : undefined;

    if (!staffId) {
      throw new UnauthorizedException('Authentication required');
    }

    const customer = await this.customerService.approve(BigInt(id), staffId);
    return {
      success: true,
      message: 'Customer onboarding approved successfully',
      data: customer,
    };
  }

  @RequirePermissions('customers.approve')
  @Post(':id/suspend')
  async suspend(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const staffId = body.staff_id
      ? BigInt(body.staff_id)
      : principal?.userId
        ? BigInt(principal.userId)
        : undefined;

    if (!staffId) {
      throw new UnauthorizedException('Authentication required');
    }

    const customer = await this.customerService.suspend(BigInt(id), staffId);
    return {
      success: true,
      message: 'Customer status suspended',
      data: customer,
    };
  }
}
