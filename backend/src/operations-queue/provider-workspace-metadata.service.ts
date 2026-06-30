import { Injectable } from '@nestjs/common';

export type ProviderWorkflowProfileCode =
  | 'GENERAL'
  | 'CLINIC'
  | 'PHARMACY'
  | 'DENTAL'
  | 'LABORATORY'
  | 'HOME_VISIT'
  | 'COSMETIC'
  | 'DIETITIAN';

@Injectable()
export class ProviderWorkspaceMetadataService {
  buildWorkspaceMeta(
    profile: ProviderWorkflowProfileCode,
    metrics: {
      waitingCount: number;
      activeCareCount: number;
      billingCount: number;
      appointmentsToday: number;
      pendingAppointments: number;
    },
  ) {
    const profileLabel = this.getWorkflowProfileLabel(profile);
    return {
      providerContext: {
        providerType: profile,
        workspaceTitle: this.getWorkspaceTitle(profile),
        headline: this.getWorkspaceHeadline(profile),
      },
      workflowProfile: {
        code: profile,
        title: profileLabel,
      },
      moduleRegistry: this.buildModuleRegistry(profile),
      navigationSections: this.buildNavigationSections(profile, metrics),
      queueStages: this.buildQueueStages(profile),
      dashboardHighlights: this.buildDashboardHighlights(profile),
      searchConfig: this.buildSearchConfig(profile),
      timelineConfig: this.buildTimelineConfig(profile),
      featureFlags: {
        realtimeQueue: false,
        patientTimeline: true,
        consultationEngine: false,
        smartAlerts: true,
      },
      permissions: ['providers.view'],
      patientWorkspace: this.buildPatientWorkspace(profile),
    };
  }

  buildQueueStageLabel(
    profile: ProviderWorkflowProfileCode,
    stageCode: string,
    rawStatus?: string | null,
  ) {
    switch (stageCode) {
      case 'ACCEPTED':
        return 'Accepted';
      case 'CONSULTATION':
        return this.getConsultationStageTitle(profile);
      case 'WAITING_PAYMENT':
        return 'Waiting for Payment';
      case 'WAITING':
        if ((rawStatus ?? '').toUpperCase().includes('LAB')) {
          return 'Waiting for Lab Report';
        }
        return this.getDashboardWaitingTitle(profile);
      case 'READY_TO_COMPLETE':
        return this.getReadyStageTitle(profile);
      case 'COMPLETED':
        return 'Completed';
      default:
        return 'Waiting';
    }
  }

  buildPrimaryActionLabel(
    profile: ProviderWorkflowProfileCode,
    stageCode: string,
    workflowType: string,
  ) {
    if (workflowType === 'PAYMENT') {
      return stageCode === 'COMPLETED' ? 'View payment' : 'Open billing';
    }
    switch (stageCode) {
      case 'ACCEPTED':
        return this.getAcceptedPrimaryAction(profile);
      case 'CONSULTATION':
        return 'Continue care';
      case 'WAITING':
        return 'Open patient';
      case 'READY_TO_COMPLETE':
        return 'Finish visit';
      case 'COMPLETED':
        return 'View summary';
      default:
        return 'Open patient';
    }
  }

  buildPrimaryTargetTab(stageCode: string, workflowType: string) {
    if (workflowType === 'PAYMENT') {
      return 'payments';
    }
    switch (stageCode) {
      case 'ACCEPTED':
        return 'today-visit';
      case 'CONSULTATION':
        return 'timeline';
      case 'READY_TO_COMPLETE':
        return 'timeline';
      case 'COMPLETED':
        return 'history';
      case 'WAITING':
      default:
        return 'overview';
    }
  }

  getWorkflowProfileLabel(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'CLINIC':
        return 'Clinic Care Workflow';
      case 'PHARMACY':
        return 'Pharmacy Fulfillment Workflow';
      case 'DENTAL':
        return 'Dental Care Workflow';
      case 'LABORATORY':
        return 'Laboratory Workflow';
      case 'HOME_VISIT':
        return 'Home Care Workflow';
      case 'COSMETIC':
        return 'Cosmetic Care Workflow';
      case 'DIETITIAN':
        return 'Dietitian Care Workflow';
      case 'GENERAL':
      default:
        return 'Provider Care Workflow';
    }
  }

  private buildNavigationSections(
    profile: ProviderWorkflowProfileCode,
    metrics: {
      waitingCount: number;
      activeCareCount: number;
      billingCount: number;
      appointmentsToday: number;
      pendingAppointments: number;
    },
  ) {
    return [
      {
        id: 'dashboard',
        title: 'Dashboard',
        icon: 'dashboard',
        route: '/portal/provider/dashboard',
        permission: 'providers.view',
        badge: metrics.activeCareCount,
        order: 1,
      },
      {
        id: 'queue',
        title: 'Live Queue',
        icon: 'queue',
        route: '/portal/provider/queue',
        permission: 'providers.view',
        badge: metrics.waitingCount + metrics.billingCount,
        order: 2,
      },
      {
        id: 'customers',
        title: 'Patient Workspace',
        icon: 'patient',
        route: '/portal/provider/customers',
        permission: 'providers.view',
        badge: 0,
        order: 3,
      },
      {
        id: 'appointments',
        title: 'Appointments',
        icon: 'calendar',
        route: '/portal/provider/appointments',
        permission: 'providers.view',
        badge: metrics.pendingAppointments,
        order: 4,
      },
      {
        id: 'documents',
        title: this.getRecordsNavigationTitle(profile),
        icon: 'folder',
        route: '/portal/provider/documents',
        permission: 'providers.view',
        badge: 0,
        order: 5,
      },
      {
        id: 'prescriptions',
        title: this.getPrescriptionsNavigationTitle(profile),
        icon: 'prescription',
        route: '/portal/provider/prescriptions',
        permission: 'providers.view',
        badge: 0,
        order: 6,
      },
      {
        id: 'profile',
        title: 'Profile',
        icon: 'profile',
        route: '/portal/provider/profile',
        permission: 'providers.view',
        badge: 0,
        order: 7,
      },
      {
        id: 'settings',
        title: 'Settings',
        icon: 'settings',
        route: '/portal/provider/settings',
        permission: 'providers.view',
        badge: 0,
        order: 8,
      },
    ];
  }

  private buildModuleRegistry(profile: ProviderWorkflowProfileCode) {
    const baseModules = [
      { id: 'dashboard', title: 'Dashboard', permission: 'providers.view' },
      { id: 'queue', title: 'Live Queue', permission: 'providers.view' },
      {
        id: 'patient-workspace',
        title: 'Patient Workspace',
        permission: 'providers.view',
      },
      { id: 'appointments', title: 'Appointments', permission: 'providers.view' },
      { id: 'documents', title: 'Medical Records', permission: 'providers.view' },
      { id: 'settings', title: 'Settings', permission: 'providers.view' },
    ];

    switch (profile) {
      case 'PHARMACY':
        return [
          ...baseModules,
          {
            id: 'prescriptions',
            title: 'Prescription Verification',
            permission: 'providers.view',
          },
          { id: 'billing', title: 'Billing', permission: 'providers.view' },
        ];
      case 'LABORATORY':
        return [
          ...baseModules,
          {
            id: 'samples',
            title: 'Sample Collection',
            permission: 'providers.view',
          },
          { id: 'reports', title: 'Lab Reports', permission: 'providers.view' },
        ];
      case 'DENTAL':
        return [
          ...baseModules,
          { id: 'treatments', title: 'Treatments', permission: 'providers.view' },
          {
            id: 'prescriptions',
            title: 'Prescriptions',
            permission: 'providers.view',
          },
        ];
      default:
        return [
          ...baseModules,
          {
            id: 'prescriptions',
            title: 'Prescriptions',
            permission: 'providers.view',
          },
        ];
    }
  }

  private buildQueueStages(profile: ProviderWorkflowProfileCode) {
    const dictionary = this.getQueueStageDictionary(profile);
    return [
      this.toQueueStageMeta('WAITING', 1, dictionary),
      this.toQueueStageMeta('ACCEPTED', 2, dictionary),
      this.toQueueStageMeta('CONSULTATION', 3, dictionary),
      this.toQueueStageMeta('WAITING_PAYMENT', 4, dictionary),
      this.toQueueStageMeta('READY_TO_COMPLETE', 5, dictionary),
      this.toQueueStageMeta('COMPLETED', 6, dictionary),
    ];
  }

  private buildDashboardHighlights(profile: ProviderWorkflowProfileCode) {
    const waitingTitle = this.getDashboardWaitingTitle(profile);
    return [
      {
        code: 'URGENT',
        title: 'Urgent',
        note: 'needs attention now',
        icon: 'priority',
        color: 'red',
        order: 1,
        metricKind: 'urgent',
        stageCodes: [] as string[],
      },
      {
        code: 'WAITING',
        title: waitingTitle,
        note: 'patients or billing items pending',
        icon: 'queue',
        color: 'orange',
        order: 2,
        metricKind: 'stage_count',
        stageCodes: ['WAITING', 'WAITING_PAYMENT'],
      },
      {
        code: 'CONSULTATION',
        title: this.getConsultationStageTitle(profile),
        note: 'care work in progress',
        icon: 'care',
        color: 'blue',
        order: 3,
        metricKind: 'stage_count',
        stageCodes: ['CONSULTATION'],
      },
      {
        code: 'READY_TO_COMPLETE',
        title: this.getReadyStageTitle(profile),
        note: 'can be finished now',
        icon: 'checklist',
        color: 'green',
        order: 4,
        metricKind: 'stage_count',
        stageCodes: ['READY_TO_COMPLETE'],
      },
    ];
  }

  private buildSearchConfig(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Search patient',
      subtitle: this.getSearchSubtitle(profile),
      placeholder:
        'Search by name, patient ID, phone, membership, SHIELD card, appointment, or invoice',
      supportedQueries: [
        'Patient name',
        'Patient ID',
        'Phone number',
        'Membership number',
        'SHIELD card',
        'Appointment',
        'Invoice',
      ],
      emptyStateMessage: 'No patients match this search yet.',
    };
  }

  private buildTimelineConfig(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Timeline',
      subtitle: this.getTimelineSubtitle(profile),
      eventLabels: {
        APPOINTMENT: 'Visit',
        DOCUMENT: 'Record',
      },
      emptyStateMessage: 'No patient history is available yet.',
    };
  }

  private buildPatientWorkspace(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Patient workspace',
      description:
        'Open one patient and keep visits, records, billing, and follow-up work together in a single workspace.',
      emptyStateMessage:
        'Select a patient to open the full care view. Visits, records, benefits, and payments stay together here.',
      headerFields: [
        { code: 'membership', title: 'Membership', icon: 'membership', order: 1 },
        { code: 'shield-card', title: 'SHIELD Card', icon: 'card', order: 2 },
        { code: 'wallet', title: 'Wallet', icon: 'wallet', order: 3 },
        { code: 'blood-group', title: 'Blood Group', icon: 'health', order: 4 },
        { code: 'location', title: 'Location', icon: 'location', order: 5 },
        { code: 'upcoming-appointment', title: "Today's Visit", icon: 'calendar', order: 6 },
      ],
      quickActions: this.buildPatientQuickActions(profile),
      tabs: [
        {
          code: 'overview',
          title: 'Overview',
          icon: 'summary',
          order: 1,
          emptyStateMessage: 'No patient summary is available yet.',
        },
        {
          code: 'today-visit',
          title: "Today's Visit",
          icon: 'care',
          order: 2,
          emptyStateMessage: 'No live visit activity has been recorded for today.',
        },
        {
          code: 'timeline',
          title: 'Timeline',
          icon: 'timeline',
          order: 3,
          emptyStateMessage: 'No patient history is available yet.',
        },
        {
          code: 'appointments',
          title: 'Appointments',
          icon: 'calendar',
          order: 4,
          emptyStateMessage:
            'No appointments have been added for this patient yet.',
        },
        {
          code: 'records',
          title: this.getRecordsNavigationTitle(profile),
          icon: 'folder',
          order: 5,
          emptyStateMessage:
            'No medical records have been uploaded yet. Prescriptions, reports, and supporting files will appear here.',
        },
        {
          code: 'payments',
          title: 'Payments',
          icon: 'payments',
          order: 6,
          emptyStateMessage: 'No patient billing details are available yet.',
        },
        {
          code: 'membership',
          title: 'Membership',
          icon: 'membership',
          order: 7,
          emptyStateMessage: 'No membership details are available yet.',
        },
        {
          code: 'history',
          title: 'History',
          icon: 'history',
          order: 8,
          emptyStateMessage: 'No completed visit history is available yet.',
        },
      ],
    };
  }

  private buildPatientQuickActions(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return [
          {
            code: 'open-verification',
            title: 'Start Verification',
            icon: 'verify',
            targetTab: 'today-visit',
          },
          {
            code: 'open-billing',
            title: 'Open Billing',
            icon: 'payments',
            targetTab: 'payments',
          },
          {
            code: 'review-records',
            title: 'Review Records',
            icon: 'folder',
            targetTab: 'records',
          },
        ];
      case 'LABORATORY':
        return [
          {
            code: 'collect-sample',
            title: 'Collect Sample',
            icon: 'care',
            targetTab: 'today-visit',
          },
          {
            code: 'open-reports',
            title: 'Open Reports',
            icon: 'folder',
            targetTab: 'records',
          },
          {
            code: 'check-payments',
            title: 'Check Payments',
            icon: 'payments',
            targetTab: 'payments',
          },
        ];
      default:
        return [
          {
            code: 'start-consultation',
            title: 'Start Consultation',
            icon: 'play',
            targetTab: 'today-visit',
          },
          {
            code: 'open-timeline',
            title: 'Open Timeline',
            icon: 'timeline',
            targetTab: 'timeline',
          },
          {
            code: 'check-payments',
            title: 'Check Payments',
            icon: 'payments',
            targetTab: 'payments',
          },
        ];
    }
  }

  private toQueueStageMeta(
    code: string,
    order: number,
    dictionary: Record<
      string,
      {
        title: string;
        icon: string;
        color: string;
        emptyStateMessage: string;
        allowedActions: string[];
      }
    >,
  ) {
    const meta = dictionary[code];
    return {
      code,
      title: meta.title,
      icon: meta.icon,
      color: meta.color,
      order,
      emptyStateMessage: meta.emptyStateMessage,
      allowedActions: meta.allowedActions,
    };
  }

  private getQueueStageDictionary(profile: ProviderWorkflowProfileCode) {
    const consultationTitle = this.getConsultationStageTitle(profile);
    const waitingTitle = this.getDashboardWaitingTitle(profile);
    const readyTitle = this.getReadyStageTitle(profile);

    return {
      WAITING: {
        title: waitingTitle,
        icon: 'queue',
        color: 'orange',
        emptyStateMessage: this.getWaitingEmptyState(profile),
        allowedActions: ['Open patient'],
      },
      ACCEPTED: {
        title: 'Accepted',
        icon: 'assignment',
        color: 'blue',
        emptyStateMessage: 'No accepted patients are queued here.',
        allowedActions: ['Open patient', this.getAcceptedPrimaryAction(profile)],
      },
      CONSULTATION: {
        title: consultationTitle,
        icon: 'care',
        color: 'blue',
        emptyStateMessage: this.getConsultationEmptyState(profile),
        allowedActions: ['Open patient', 'Continue care'],
      },
      WAITING_PAYMENT: {
        title: 'Waiting for Payment',
        icon: 'payments',
        color: 'amber',
        emptyStateMessage: 'No billing items are waiting for payment right now.',
        allowedActions: ['Open patient', 'Open billing'],
      },
      READY_TO_COMPLETE: {
        title: readyTitle,
        icon: 'checklist',
        color: 'green',
        emptyStateMessage: 'Nothing is waiting to be completed.',
        allowedActions: ['Open patient', 'Finish visit'],
      },
      COMPLETED: {
        title: 'Completed',
        icon: 'done',
        color: 'slate',
        emptyStateMessage: 'No completed items have been loaded yet.',
        allowedActions: ['Open patient', 'View summary'],
      },
    };
  }

  private getWorkspaceTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Pharmacy Workspace';
      case 'DENTAL':
        return 'Dental Workspace';
      case 'LABORATORY':
        return 'Laboratory Workspace';
      case 'HOME_VISIT':
        return 'Home Care Workspace';
      case 'COSMETIC':
        return 'Cosmetic Care Workspace';
      case 'DIETITIAN':
        return 'Dietitian Workspace';
      case 'CLINIC':
        return 'Clinic Workspace';
      case 'GENERAL':
      default:
        return 'Provider Care Hub';
    }
  }

  private getWorkspaceHeadline(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Verification, dispensing, billing, and patient records in one place';
      case 'DENTAL':
        return 'Treatments, appointments, records, and follow-ups in one place';
      case 'LABORATORY':
        return 'Samples, reports, appointments, and patient history in one place';
      case 'HOME_VISIT':
        return 'Visits, notes, records, and follow-ups in one place';
      default:
        return 'Patients, appointments, records, and payments in one place';
    }
  }

  private getRecordsNavigationTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'LABORATORY':
        return 'Lab Reports';
      default:
        return 'Medical Records';
    }
  }

  private getPrescriptionsNavigationTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Prescription Review';
      case 'LABORATORY':
        return 'Reports';
      default:
        return 'Prescriptions';
    }
  }

  private getDashboardWaitingTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Waiting for Verification';
      case 'DENTAL':
        return 'Waiting for Treatment';
      case 'LABORATORY':
        return 'Waiting for Sample';
      case 'HOME_VISIT':
        return 'Waiting for Visit Start';
      default:
        return 'Waiting for Consultation';
    }
  }

  private getConsultationStageTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Dispensing';
      case 'DENTAL':
        return 'Treatment in Progress';
      case 'LABORATORY':
        return 'Sample in Progress';
      case 'HOME_VISIT':
        return 'Visit in Progress';
      case 'COSMETIC':
        return 'Session in Progress';
      case 'DIETITIAN':
        return 'Plan Review in Progress';
      default:
        return 'Consultation';
    }
  }

  private getReadyStageTitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Ready for Handover';
      case 'LABORATORY':
        return 'Ready to Upload Report';
      case 'HOME_VISIT':
        return 'Ready to Close Visit';
      default:
        return 'Ready to Complete';
    }
  }

  private getWaitingEmptyState(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'No prescriptions or customers are waiting for verification right now.';
      case 'DENTAL':
        return 'No patients are waiting for treatment right now.';
      case 'LABORATORY':
        return 'No samples are waiting to be collected right now.';
      default:
        return 'No patients are waiting right now.';
    }
  }

  private getConsultationEmptyState(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'No dispensing work is in progress.';
      case 'DENTAL':
        return 'No dental treatment is in progress.';
      case 'LABORATORY':
        return 'No sample processing is in progress.';
      default:
        return 'No consultations are in progress.';
    }
  }

  private getAcceptedPrimaryAction(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Start verification';
      case 'DENTAL':
        return 'Start treatment';
      case 'LABORATORY':
        return 'Start sample collection';
      default:
        return 'Start consultation';
    }
  }

  private getSearchSubtitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Open one patient and keep verification, records, membership, and payments together in a single workspace.';
      case 'LABORATORY':
        return 'Open one patient and keep sample work, reports, billing, and follow-up together in a single workspace.';
      default:
        return 'Open one patient and keep appointments, medical records, membership, and payments together in a single workspace.';
    }
  }

  private getTimelineSubtitle(profile: ProviderWorkflowProfileCode) {
    switch (profile) {
      case 'PHARMACY':
        return 'Use the patient timeline to track verification, dispensing, and payment activity in one place.';
      case 'LABORATORY':
        return 'Use the patient timeline to track sample, report, and billing activity in one place.';
      default:
        return 'Use the patient timeline to follow the full care story in one place.';
    }
  }
}
