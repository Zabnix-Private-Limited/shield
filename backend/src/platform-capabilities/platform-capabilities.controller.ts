import {
  Controller,
  Get,
  MessageEvent,
  Post,
  Query,
  Body,
  Sse,
  UnauthorizedException,
  Headers,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { AuthService } from '../auth/auth.service';
import type { ShieldPrincipal } from '../auth/auth.types';
import { AgentScopeService } from '../auth/agent-scope.service';
import { CurrentPrincipal } from '../auth/current-principal.decorator';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { Public } from '../auth/public.decorator';
import { PlatformPrintService } from './platform-print.service';
import { PlatformRealtimeService } from './platform-realtime.service';
import { PlatformReportService } from './platform-report.service';

@Controller('platform')
export class PlatformCapabilitiesController {
  constructor(
    private readonly authService: AuthService,
    private readonly agentScopeService: AgentScopeService,
    private readonly providerScopeService: ProviderScopeService,
    private readonly platformPrintService: PlatformPrintService,
    private readonly platformRealtimeService: PlatformRealtimeService,
    private readonly platformReportService: PlatformReportService,
  ) {}

  @Get('print/templates')
  getPrintTemplates() {
    return {
      success: true,
      message: 'Print templates retrieved successfully.',
      data: this.platformPrintService.listTemplates(),
    };
  }

  @Post('print/generate')
  async generatePrint(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.assertPrintPayloadAccess(body.payload, principal);
    const data = this.platformPrintService.generate(
      `${body.templateId ?? ''}`,
      body.payload ?? {},
    );
    return {
      success: true,
      message: 'Printable document generated successfully.',
      data,
    };
  }

  @Get('reports')
  getReports(@Query('workspace') workspace?: string) {
    return {
      success: true,
      message: 'Report registry retrieved successfully.',
      data: this.platformReportService.listMetadata(workspace),
    };
  }

  @Post('reports/run')
  async runReport(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    let filters: Record<string, any> =
      this.providerScopeService.normalizeReportFilters(principal, {
        workspace: body.workspace?.toString(),
        providerId:
          body.providerId && /^\d+$/.test(`${body.providerId}`.trim())
            ? BigInt(body.providerId)
            : undefined,
        providerType: body.providerType?.toString(),
        businessId:
          body.businessId && /^\d+$/.test(`${body.businessId}`.trim())
            ? BigInt(body.businessId)
            : undefined,
        dateFrom: body.dateFrom?.toString(),
        dateTo: body.dateTo?.toString(),
        status: body.status?.toString(),
        search: body.search?.toString(),
        serviceType: body.serviceType?.toString(),
        customerId:
          body.customerId && /^\d+$/.test(`${body.customerId}`.trim())
            ? BigInt(body.customerId)
            : undefined,
      });

    if (this.agentScopeService.isAgentPrincipal(principal)) {
      const context = await this.agentScopeService.resolveAgentContext(principal);
      if (filters.customerId) {
        await this.agentScopeService.assertAgentCanAccessCustomer(
          filters.customerId,
          principal,
        );
      }
      filters = {
        ...filters,
        workspace: body.workspace?.toString()?.trim()?.toLowerCase() || 'agent',
        agentCode: context?.agentCode,
      };
    }

    const data = await this.platformReportService.runReport(
      `${body.reportId ?? ''}`,
      filters,
      `${body.format ?? 'PDF'}`.trim().toUpperCase() as 'PDF' | 'EXCEL' | 'CSV',
    );
    return {
      success: true,
      message: 'Report generated successfully.',
      data,
    };
  }

  @Public()
  @Sse('realtime/stream')
  async streamRealtime(
    @Query('workspace') workspace = 'provider',
    @Query('customer_id') customerId?: string,
    @Query('access_token') accessToken?: string,
    @Headers('authorization') authorization?: string,
  ): Promise<Observable<MessageEvent>> {
    const token =
      accessToken?.trim() ||
      authorization?.replace(/^Bearer\s+/i, '').trim() ||
      '';
    if (!token) {
      throw new UnauthorizedException('Access token is required.');
    }
    await this.authService.verifyAccessToken(token);
    return this.platformRealtimeService.stream(
      workspace.trim().toLowerCase(),
      customerId?.trim() || undefined,
    );
  }

  private async assertPrintPayloadAccess(
    payload: any,
    principal?: ShieldPrincipal,
  ) {
    if (this.agentScopeService.isAgentPrincipal(principal)) {
      const activeVisitAppointmentId =
        payload?.activeVisit?.appointmentId ?? payload?.appointmentId;
      if (
        activeVisitAppointmentId != null &&
        /^\d+$/.test(`${activeVisitAppointmentId}`.trim())
      ) {
        await this.agentScopeService.assertAgentCanAccessAppointment(
          BigInt(`${activeVisitAppointmentId}`.trim()),
          principal,
        );
        return;
      }

      const customerId = payload?.patient?.id ?? payload?.customerId;
      if (customerId != null && /^\d+$/.test(`${customerId}`.trim())) {
        await this.agentScopeService.assertAgentCanAccessCustomer(
          BigInt(`${customerId}`.trim()),
          principal,
        );
      }
      return;
    }

    if (!this.providerScopeService.isProviderPrincipal(principal)) {
      return;
    }

    const activeVisitAppointmentId =
      payload?.activeVisit?.appointmentId ?? payload?.appointmentId;
    if (
      activeVisitAppointmentId != null &&
      /^\d+$/.test(`${activeVisitAppointmentId}`.trim())
    ) {
      await this.providerScopeService.assertProviderCanAccessAppointment(
        BigInt(`${activeVisitAppointmentId}`.trim()),
        principal,
      );
      return;
    }

    const customerId = payload?.patient?.id ?? payload?.customerId;
    if (customerId != null && /^\d+$/.test(`${customerId}`.trim())) {
      await this.providerScopeService.assertProviderCanAccessCustomer(
        BigInt(`${customerId}`.trim()),
        principal,
      );
    }
  }
}
