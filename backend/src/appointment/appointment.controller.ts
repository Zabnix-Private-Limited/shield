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
import { AgentScopeService } from '../auth/agent-scope.service';
import { AppointmentService } from './appointment.service';

@Controller('appointments')
export class AppointmentController {
  constructor(
    private appointmentService: AppointmentService,
    private readonly agentScopeService: AgentScopeService,
  ) {}

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
    if (targetCustomerId) {
      await this.agentScopeService.assertAgentCanAccessCustomer(
        targetCustomerId,
        principal,
      );
    }
    const appts = await this.appointmentService.list(targetCustomerId, principal);
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
    await this.agentScopeService.assertAgentCanAccessCustomer(
      BigInt(body.customer_id),
      principal,
    );
    const appt = await this.appointmentService.create(body);
    return {
      success: true,
      message: 'Appointment booked successfully',
      data: appt,
    };
  }

  @RequirePermissions('appointments.view')
  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessAppointment(
      BigInt(id),
      principal,
    );
    const appt = await this.appointmentService.findOne(BigInt(id), principal);
    return {
      success: true,
      message: 'Appointment details retrieved',
      data: appt,
    };
  }

  @RequirePermissions('appointments.delete')
  @Post(':id/cancel')
  async cancel(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessAppointment(
      BigInt(id),
      principal,
    );
    const appt = await this.appointmentService.cancel(BigInt(id), principal);
    return {
      success: true,
      message: 'Appointment cancelled successfully',
      data: appt,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/confirm')
  async confirm(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.agentScopeService.assertAgentCanAccessAppointment(
      BigInt(id),
      principal,
    );
    const appt = await this.appointmentService.confirm(BigInt(id), principal);
    return {
      success: true,
      message: 'Appointment confirmed successfully',
      data: appt,
    };
  }

  @RequirePermissions('appointments.view')
  @Get(':id/consultation-workspace')
  async getConsultationWorkspace(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.getConsultationWorkspace(
      BigInt(id),
      principal,
    );
    return {
      success: true,
      message: 'Consultation workspace retrieved',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/start-consultation')
  async startConsultation(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.startConsultation(
      BigInt(id),
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Consultation started successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/consultation')
  async saveConsultation(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.saveConsultation(
      BigInt(id),
      {
        chiefComplaint: body.chief_complaint ?? body.chiefComplaint,
        symptoms: body.symptoms,
        clinicalFindings: body.clinical_findings ?? body.clinicalFindings,
        diagnosis: body.diagnosis,
        advice: body.advice,
        procedures: body.procedures,
        labOrders: body.lab_orders ?? body.labOrders,
        followUp: body.follow_up ?? body.followUp,
        providerNotes: body.provider_notes ?? body.providerNotes ?? body.notes,
      },
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Consultation progress saved successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/complete-consultation')
  async completeConsultation(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.completeConsultation(
      BigInt(id),
      {
        chiefComplaint: body.chief_complaint ?? body.chiefComplaint,
        symptoms: body.symptoms,
        clinicalFindings: body.clinical_findings ?? body.clinicalFindings,
        diagnosis: body.diagnosis,
        advice: body.advice,
        procedures: body.procedures,
        labOrders: body.lab_orders ?? body.labOrders,
        followUp: body.follow_up ?? body.followUp,
        providerNotes: body.provider_notes ?? body.providerNotes ?? body.notes,
        billingDraft: body.billing_draft ?? body.billingDraft,
      },
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Consultation completed successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/visit-billing')
  async saveVisitBilling(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.saveVisitBillingDraft(
      BigInt(id),
      body.billing_draft ?? body.billingDraft ?? body,
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Visit billing saved successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/generate-invoice')
  async generateVisitInvoice(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.generateVisitInvoice(
      BigInt(id),
      {
        formData: {
          chiefComplaint: body.chief_complaint ?? body.chiefComplaint,
          symptoms: body.symptoms,
          clinicalFindings: body.clinical_findings ?? body.clinicalFindings,
          diagnosis: body.diagnosis,
          advice: body.advice,
          procedures: body.procedures,
          labOrders: body.lab_orders ?? body.labOrders,
          followUp: body.follow_up ?? body.followUp,
          providerNotes: body.provider_notes ?? body.providerNotes ?? body.notes,
        },
        billingDraft: body.billing_draft ?? body.billingDraft,
      },
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Visit invoice generated successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/record-payment')
  async recordVisitPayment(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.recordVisitPayment(
      BigInt(id),
      body.billing_draft ?? body.billingDraft ?? body,
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Visit payment recorded successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/prescription/draft')
  async savePrescriptionDraft(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.savePrescriptionDraft(
      BigInt(id),
      {
        clinicalRemarks:
          body.clinical_remarks ?? body.clinicalRemarks ?? body.notes,
        items: body.items,
      },
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Prescription draft saved successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/prescription/copy-to-open-visit')
  async copyPrescriptionToOpenVisit(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.copyPrescriptionToOpenVisit(
      BigInt(id),
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Historical prescription copied to the active visit successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/prescription/finalize')
  async finalizePrescription(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.finalizePrescription(
      BigInt(id),
      {
        clinicalRemarks:
          body.clinical_remarks ?? body.clinicalRemarks ?? body.notes,
        items: body.items,
        sendToPharmacy: body.send_to_pharmacy ?? body.sendToPharmacy,
      },
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Prescription finalized successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/prescription/duplicate-last')
  async duplicatePreviousPrescription(
    @Param('id') id: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.duplicatePreviousPrescription(
      BigInt(id),
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Previous prescription copied successfully',
      data: workspace,
    };
  }

  @RequirePermissions('appointments.update')
  @Post(':id/void-invoice')
  async voidVisitInvoice(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    const workspace = await this.appointmentService.voidVisitInvoice(
      BigInt(id),
      body.reason,
      principal,
      {
        userId: principal?.userId ? BigInt(principal.userId) : undefined,
        roleCode: principal?.roleCode,
      },
    );
    return {
      success: true,
      message: 'Visit invoice voided successfully',
      data: workspace,
    };
  }
}
