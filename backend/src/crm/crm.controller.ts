import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UnauthorizedException,
} from '@nestjs/common';
import { AgentScopeService } from '../auth/agent-scope.service';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { CrmService } from './crm.service';

@Controller()
export class CrmController {
  constructor(
    private crmService: CrmService,
    private readonly agentScopeService: AgentScopeService,
  ) {}

  @RequirePermissions('crm.view')
  @Get('crm/activities')
  async listActivities(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (customerId?.trim()) {
      await this.agentScopeService.assertAgentCanAccessCustomer(
        BigInt(customerId),
        principal,
      );
    }
    const list = await this.crmService.listActivities(
      customerId ? BigInt(customerId) : undefined,
    );
    return {
      success: true,
      message: 'CRM activities retrieved',
      data: list,
    };
  }

  @RequirePermissions('crm.create')
  @Post('crm/activities')
  async createActivity(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const staffId = body.created_by
      ? BigInt(body.created_by)
      : principal?.userId
        ? BigInt(principal.userId)
        : undefined;

    if (!staffId) {
      throw new UnauthorizedException('Authentication required');
    }
    await this.agentScopeService.assertAgentCanAccessCustomer(
      BigInt(body.customer_id),
      principal,
    );

    const act = await this.crmService.createActivity({
      customerId: BigInt(body.customer_id),
      activityType: body.activity_type,
      notes: body.notes,
      createdBy: staffId,
    });
    return {
      success: true,
      message: 'CRM activity recorded successfully',
      data: act,
    };
  }

  @RequirePermissions('crm.view')
  @Get('crm/tasks')
  async listTasks(
    @Query('customer_id') customerId?: string,
    @Query('assigned_to') assignedTo?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const scopedAssignedTo =
      this.agentScopeService.isAgentPrincipal(principal) && principal?.userId
        ? BigInt(principal.userId)
        : assignedTo
          ? BigInt(assignedTo)
          : undefined;
    if (customerId?.trim()) {
      await this.agentScopeService.assertAgentCanAccessCustomer(
        BigInt(customerId),
        principal,
      );
    }
    const list = await this.crmService.listTasks(
      customerId ? BigInt(customerId) : undefined,
      scopedAssignedTo,
    );
    return {
      success: true,
      message: 'CRM tasks list retrieved',
      data: list,
    };
  }

  @RequirePermissions('crm.create')
  @Post('crm/tasks')
  async createTask(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessCustomer(
      BigInt(body.customer_id),
      principal,
    );
    const task = await this.crmService.createTask({
      customerId: BigInt(body.customer_id),
      assignedTo:
        this.agentScopeService.isAgentPrincipal(principal) && principal?.userId
          ? BigInt(principal.userId)
          : BigInt(body.assigned_to),
      dueDate: body.due_date,
      notes: body.notes,
    });
    return {
      success: true,
      message: 'CRM task created successfully',
      data: task,
    };
  }

  @RequirePermissions('crm.update')
  @Put('crm/tasks/:id')
  async updateTask(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessCrmTask(
      BigInt(id),
      principal,
    );
    const task = await this.crmService.updateTask(BigInt(id), body);
    return {
      success: true,
      message: 'CRM task updated successfully',
      data: task,
    };
  }

  @RequirePermissions('crm.view')
  @Get('crm/complaints')
  async listComplaints(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (customerId?.trim()) {
      await this.agentScopeService.assertAgentCanAccessCustomer(
        BigInt(customerId),
        principal,
      );
    }
    const list = await this.crmService.listComplaints(
      customerId ? BigInt(customerId) : undefined,
    );
    return {
      success: true,
      message: 'Complaints list retrieved',
      data: list,
    };
  }

  @RequirePermissions('crm.create')
  @Post('complaints')
  async createComplaint(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessCustomer(
      BigInt(body.customer_id),
      principal,
    );
    const comp = await this.crmService.createComplaint({
      customerId: BigInt(body.customer_id),
      complaintType: body.complaint_type,
      description: body.description,
    });
    return {
      success: true,
      message: 'Complaint submitted successfully',
      data: comp,
    };
  }

  @RequirePermissions('crm.update')
  @Put('complaints/:id')
  async updateComplaint(@Param('id') id: string, @Body() body: any) {
    const comp = await this.crmService.updateComplaint(BigInt(id), body);
    return {
      success: true,
      message: 'Complaint updated successfully',
      data: comp,
    };
  }

  @RequirePermissions('crm.update')
  @Post('complaints/:id/resolve')
  async resolveComplaint(@Param('id') id: string) {
    const comp = await this.crmService.resolveComplaint(BigInt(id));
    return {
      success: true,
      message: 'Complaint resolved successfully',
      data: comp,
    };
  }
}
