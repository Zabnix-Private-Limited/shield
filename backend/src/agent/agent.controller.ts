import { Body, Controller, Get, Param, Patch, Put } from '@nestjs/common';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import { AgentService } from './agent.service';

@Controller('agents')
export class AgentController {
  constructor(private readonly agentService: AgentService) {}

  @RequirePermissions('agent.dashboard.view')
  @Get('workspace')
  async getWorkspace(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      message: 'Agent workspace retrieved successfully.',
      data: await this.agentService.getWorkspace(principal),
    };
  }

  @RequirePermissions('agent.customer.view')
  @Get('customers/:customerId/workspace')
  async getCustomerWorkspace(
    @Param('customerId') customerId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Agent customer workspace retrieved successfully.',
      data: await this.agentService.getCustomerWorkspace(
        BigInt(customerId),
        principal,
      ),
    };
  }

  @RequirePermissions('settings.view')
  @Get('me/profile')
  async getCurrentProfile(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      message: 'Agent profile retrieved successfully.',
      data: await this.agentService.getCurrentProfile(principal),
    };
  }

  @RequirePermissions('settings.view')
  @Get('me/preferences')
  async getCurrentPreferences(@CurrentPrincipal() principal?: ShieldPrincipal) {
    return {
      success: true,
      message: 'Agent preferences retrieved successfully.',
      data: await this.agentService.getCurrentPreferences(principal),
    };
  }

  @RequirePermissions('settings.update')
  @Patch('me/profile')
  async updateCurrentProfile(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Agent profile updated successfully.',
      data: await this.agentService.updateCurrentProfile(principal, body),
    };
  }

  @RequirePermissions('settings.update')
  @Put('me/preferences')
  async updateCurrentPreferences(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    return {
      success: true,
      message: 'Agent preferences updated successfully.',
      data: await this.agentService.updateCurrentPreferences(principal, body),
    };
  }
}
