import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { AppointmentService } from './appointment.service';

@Controller('appointments')
export class AppointmentController {
  constructor(private appointmentService: AppointmentService) {}

  @Get()
  async list(@Query('customer_id') customerId?: string) {
    const targetCustomerId = customerId ? BigInt(customerId) : undefined;
    const appts = await this.appointmentService.list(targetCustomerId);
    return {
      success: true,
      message: 'Appointments list retrieved',
      data: appts,
    };
  }

  @Post()
  async create(@Body() body: any) {
    const appt = await this.appointmentService.create(body);
    return {
      success: true,
      message: 'Appointment booked successfully',
      data: appt,
    };
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const appt = await this.appointmentService.findOne(BigInt(id));
    return {
      success: true,
      message: 'Appointment details retrieved',
      data: appt,
    };
  }

  @Post(':id/cancel')
  async cancel(@Param('id') id: string) {
    const appt = await this.appointmentService.cancel(BigInt(id));
    return {
      success: true,
      message: 'Appointment cancelled successfully',
      data: appt,
    };
  }

  @Post(':id/confirm')
  async confirm(@Param('id') id: string) {
    const appt = await this.appointmentService.confirm(BigInt(id));
    return {
      success: true,
      message: 'Appointment confirmed successfully',
      data: appt,
    };
  }
}
