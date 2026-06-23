import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { CrmService } from './crm.service';
import { MockAuthGuard } from '../auth/mock-auth.guard';

@Controller()
@UseGuards(MockAuthGuard)
export class CrmController {
  constructor(private crmService: CrmService) {}

  @Get('crm/activities')
  async listActivities(@Query('customer_id') customerId?: string) {
    const list = await this.crmService.listActivities(
      customerId ? BigInt(customerId) : undefined,
    );
    return {
      success: true,
      message: 'CRM activities retrieved',
      data: list,
    };
  }

  @Post('crm/activities')
  async createActivity(@Body() body: any, @Request() req: any) {
    const staffId = req.user.isStaff ? BigInt(req.user.id) : BigInt(1);
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

  @Get('crm/tasks')
  async listTasks(
    @Query('customer_id') customerId?: string,
    @Query('assigned_to') assignedTo?: string,
  ) {
    const list = await this.crmService.listTasks(
      customerId ? BigInt(customerId) : undefined,
      assignedTo ? BigInt(assignedTo) : undefined,
    );
    return {
      success: true,
      message: 'CRM tasks list retrieved',
      data: list,
    };
  }

  @Post('crm/tasks')
  async createTask(@Body() body: any) {
    const task = await this.crmService.createTask({
      customerId: BigInt(body.customer_id),
      assignedTo: BigInt(body.assigned_to),
      dueDate: body.due_date,
      notes: body.notes,
    });
    return {
      success: true,
      message: 'CRM task created successfully',
      data: task,
    };
  }

  @Put('crm/tasks/:id')
  async updateTask(@Param('id') id: string, @Body() body: any) {
    const task = await this.crmService.updateTask(BigInt(id), body);
    return {
      success: true,
      message: 'CRM task updated successfully',
      data: task,
    };
  }

  @Get('crm/complaints')
  async listComplaints(@Query('customer_id') customerId?: string) {
    const list = await this.crmService.listComplaints(
      customerId ? BigInt(customerId) : undefined,
    );
    return {
      success: true,
      message: 'Complaints list retrieved',
      data: list,
    };
  }

  @Post('complaints')
  async createComplaint(@Body() body: any) {
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

  @Put('complaints/:id')
  async updateComplaint(@Param('id') id: string, @Body() body: any) {
    const comp = await this.crmService.updateComplaint(BigInt(id), body);
    return {
      success: true,
      message: 'Complaint updated successfully',
      data: comp,
    };
  }

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
