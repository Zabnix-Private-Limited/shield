import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { RequirePermissions } from '../auth/permissions.decorator';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AppointmentService } from './appointment.service';

@Controller('appointments')
export class AppointmentController {
  constructor(private appointmentService: AppointmentService) {}

  @RequirePermissions('appointments.view')
  @Get()
  async list(
    @Query('customer_id') customerId?: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const targetCustomerId =
      principal?.principalType === 'CUSTOMER'
        ? BigInt(principal.customerId!)
        : customerId
          ? BigInt(customerId)
          : undefined;
    const appts = await this.appointmentService.list(targetCustomerId);
    return {
      success: true,
      message: 'Appointments list retrieved',
      data: appts,
    };
  }

  @RequirePermissions('appointments.create')
  @Post()
  async create(@Body() body: any, @CurrentPrincipal() principal?: ShieldPrincipal) {
    if (principal?.principalType === 'CUSTOMER') {
      body.customer_id = principal.customerId;
    }
    const appt = await this.appointmentService.create(body);
    return {
      success: true,
      message: 'Appointment booked successfully',
      data: appt,
    };
  }

  @RequirePermissions('appointments.view')
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const appt = await this.appointmentService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Appointment details retrieved',
      data: appt,
    };
  }

  @RequirePermissions('appointments.delete')
  @Post(':id/cancel')
  async cancel(@Param('id') id: string) {
    const appt = await this.appointmentService.cancel(BigInt(id));
    return {
      success: true,
      message: 'Appointment cancelled successfully',
      data: appt,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/confirm')
  async confirm(@Param('id') id: string) {
    const appt = await this.appointmentService.confirm(BigInt(id));
    return {
      success: true,
      message: 'Appointment confirmed successfully',
      data: appt,
    };
  }

  @RequirePermissions('appointments.view')
  @Get(':id/consultation-workspace')
  async getConsultationWorkspace(@Param('id') id: string) {
    const workspace = await this.appointmentService.getConsultationWorkspace(
      BigInt(id),
    );
    return {
      success: true,
      message: 'Consultation workspace retrieved',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/start-consultation')
  async startConsultation(@Param('id') id: string) {
    const workspace = await this.appointmentService.startConsultation(BigInt(id));
    return {
      success: true,
      message: 'Consultation started successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/consultation')
  async saveConsultation(@Param('id') id: string, @Body() body: any) {
    const workspace = await this.appointmentService.saveConsultation(BigInt(id), {
      symptoms: body.symptoms,
      diagnosis: body.diagnosis,
      advice: body.advice,
      followUp: body.follow_up ?? body.followUp,
      notes: body.notes,
    });
    return {
      success: true,
      message: 'Consultation progress saved successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/complete-consultation')
  async completeConsultation(@Param('id') id: string, @Body() body: any) {
    const workspace = await this.appointmentService.completeConsultation(BigInt(id), {
      symptoms: body.symptoms,
      diagnosis: body.diagnosis,
      advice: body.advice,
      followUp: body.follow_up ?? body.followUp,
      notes: body.notes,
    });
    return {
      success: true,
      message: 'Consultation completed successfully',
      data: workspace,
    };
  }
}
