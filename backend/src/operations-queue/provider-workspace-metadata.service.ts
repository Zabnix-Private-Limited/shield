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
    options?: {
      providerContext?: Record<string, unknown>;
      permissions?: string[];
    },
  ) {
    const profileLabel = this.getWorkflowProfileLabel(profile);
    const moduleRegistry = this.buildModuleRegistry(profile);
    const dashboardLayout = this.buildDashboardLayout(profile);
    const workflowStages = this.buildWorkflowStages(profile);
    const queueStages = this.buildQueueStages(profile);
    const dashboardHighlights = this.buildDashboardHighlights(profile);
    const searchConfig = this.buildSearchConfig(profile);
    const timelineConfig = this.buildTimelineConfig(profile);
    const quickActions = this.buildPatientQuickActions(profile);
    const patientWorkspace = this.buildPatientWorkspace(profile);
    const workflowEngine = {
      title: 'Workflow Engine',
      description:
        'Backend-owned visit stages and provider workflow progression.',
      stages: workflowStages,
      completionActionTitle: this.getReadyStageTitle(profile),
    };
    const notificationEngine = this.buildNotificationEngine(profile);
    const auditEngine = this.buildAuditEngine(profile);
    const featureFlags = {
      realtimeQueue: false,
      patientTimeline: true,
      consultationEngine: true,
      smartAlerts: true,
    };
    const navigationSections = this.buildNavigationSections(profile, metrics);
    const permissions = options?.permissions?.length
      ? [...new Set(options.permissions)]
      : ['providers.view'];
    const topLevelWorklists = this.buildWorkspaceWorklists(
      profile,
      metrics,
      queueStages,
    );
    const dashboardWidgets = this.buildDashboardWidgets(
      profile,
      metrics,
      dashboardLayout,
    );
    const aggregatedFormSchemas = [
      ...new Set(
        moduleRegistry.flatMap((module) => {
          const formSchemas = (module as { formSchemas?: unknown[] }).formSchemas;
          return Array.isArray(formSchemas)
            ? formSchemas.map((item: unknown) => item?.toString() ?? '')
            : [];
        }),
      ),
    ].filter((value) => value.length > 0);
    return {
      providerContext: {
        providerType: profile,
        workspaceTitle: this.getWorkspaceTitle(profile),
        headline: this.getWorkspaceHeadline(profile),
        ...options?.providerContext,
      },
      workflowProfile: {
        code: profile,
        title: profileLabel,
      },
      navigation: navigationSections,
      navigationSections,
      moduleRegistry,
      dashboardLayout,
      dashboardWidgets,
      quickActions,
      worklists: topLevelWorklists,
      formSchemas: aggregatedFormSchemas,
      visitEngine: this.buildVisitEngine(profile),
      workflowEngine,
      workflowDefinitions: workflowStages,
      visitStages: workflowStages,
      queueStages,
      dashboardHighlights,
      searchConfig,
      filters: this.buildWorkspaceFilters(profile),
      timelineConfig,
      actionEngine: this.buildActionEngine(profile),
      notificationEngine,
      notificationTypes: notificationEngine.eventTypes,
      auditEngine,
      auditMetadata: auditEngine,
      featureFlags,
      permissions,
      patientWorkspace,
      statusMappings: this.buildStatusMappings(profile),
      labels: this.buildWorkspaceLabels(profile),
      messages: this.buildWorkspaceMessages(profile),
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
        moduleId: 'dashboard',
        title: 'Dashboard',
        icon: 'dashboard',
        route: '/portal/provider/dashboard',
        permission: 'providers.view',
        badge: metrics.activeCareCount,
        order: 1,
      },
      {
        id: 'queue',
        moduleId: 'queue',
        title: 'Live Queue',
        icon: 'queue',
        route: '/portal/provider/queue',
        permission: 'providers.view',
        badge: metrics.waitingCount + metrics.billingCount,
        order: 2,
      },
      {
        id: 'customers',
        moduleId: 'patient-workspace',
        title: 'Patient Record',
        icon: 'patient',
        route: '/portal/provider/customers',
        permission: 'providers.view',
        badge: 0,
        order: 3,
      },
      {
        id: 'appointments',
        moduleId: 'appointments',
        title: 'Appointments',
        icon: 'calendar',
        route: '/portal/provider/appointments',
        permission: 'providers.view',
        badge: metrics.pendingAppointments,
        order: 4,
      },
      {
        id: 'documents',
        moduleId: 'documents',
        title: this.getRecordsNavigationTitle(profile),
        icon: 'folder',
        route: '/portal/provider/documents',
        permission: 'providers.view',
        badge: 0,
        order: 5,
      },
      {
        id: 'prescriptions',
        moduleId: 'prescriptions',
        title: this.getPrescriptionsNavigationTitle(profile),
        icon: 'prescription',
        route: '/portal/provider/prescriptions',
        permission: 'providers.view',
        badge: 0,
        order: 6,
      },
      {
        id: 'profile',
        moduleId: 'profile',
        title: 'Profile',
        icon: 'profile',
        route: '/portal/provider/profile',
        permission: 'providers.view',
        badge: 0,
        order: 7,
      },
      {
        id: 'settings',
        moduleId: 'settings',
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
      {
        id: 'dashboard',
        title: 'Dashboard',
        permission: 'providers.view',
        renderer: 'dashboard',
        sectionKey: 'dashboard',
        category: 'workspace',
        description: 'Actionable control center for the provider workday.',
        emptyStateMessage: 'No dashboard widgets are available yet.',
        dashboardWidgets: ['today-patients', 'waiting-queue', 'tasks-waiting'],
        worklists: ['waiting', 'today-appointments', 'urgent'],
        actions: ['open-queue', 'open-patient-search'],
        featureFlags: ['dashboard-widgets'],
      },
      {
        id: 'queue',
        title: 'Live Queue',
        permission: 'providers.view',
        renderer: 'queue',
        sectionKey: 'queue',
        category: 'workflow',
        description: 'Live operational queue for the current provider workflow.',
        emptyStateMessage: 'No patients are waiting in the live queue right now.',
        worklists: ['waiting', 'accepted', 'in-progress', 'ready'],
        timelineEventTypes: ['CHECK_IN', 'ASSIGNED', 'STARTED', 'COMPLETED'],
        actions: ['open-patient', 'start-workflow', 'finish-workflow'],
        featureFlags: ['live-queue-board'],
      },
      {
        id: 'patient-workspace',
        title: 'Patient Record',
        permission: 'providers.view',
        renderer: 'patient-workspace',
        sectionKey: 'customers',
        category: 'workspace',
        description: 'One patient-centered record for visits, records, billing, and follow-up.',
        emptyStateMessage: 'Select a patient to open the full patient record.',
        searchConfig: this.buildSearchConfig(profile),
        actions: ['start-consultation', 'open-timeline', 'check-payments'],
        featureFlags: ['patient-workspace', 'visit-engine'],
      },
      {
        id: 'appointments',
        title: 'Appointments',
        permission: 'providers.view',
        renderer: 'appointments',
        sectionKey: 'appointments',
        category: 'schedule',
        description: 'Assigned appointments, follow-up visits, and care schedule.',
        emptyStateMessage: 'No appointments are available yet.',
        worklists: ['today-appointments', 'upcoming', 'completed'],
        actions: ['open-patient', 'start-visit'],
      },
      {
        id: 'documents',
        title: 'Medical Records',
        permission: 'providers.view',
        renderer: 'documents',
        sectionKey: 'documents',
        category: 'records',
        description: 'Medical records, uploaded files, and supporting care documents.',
        emptyStateMessage: 'No records have been uploaded yet.',
        timelineEventTypes: ['DOCUMENT_UPLOADED', 'REPORT_READY'],
        actions: ['open-patient', 'review-records'],
      },
      {
        id: 'profile',
        title: 'Profile',
        permission: 'providers.view',
        renderer: 'profile',
        sectionKey: 'profile',
        category: 'account',
        description: 'Provider identity, role, branch, and availability details.',
        emptyStateMessage: 'Provider profile is not available yet.',
      },
      {
        id: 'settings',
        title: 'Settings',
        permission: 'providers.view',
        renderer: 'settings',
        sectionKey: 'settings',
        category: 'account',
        description: 'Sessions, devices, notifications, and provider preferences.',
        emptyStateMessage: 'Settings are not available yet.',
      },
    ];

    switch (profile) {
      case 'PHARMACY':
        return [
          ...baseModules,
          {
            id: 'prescriptions',
            title: 'Prescription Verification',
            permission: 'providers.view',
            renderer: 'prescriptions',
            sectionKey: 'prescriptions',
            category: 'care-module',
            workflowTags: ['validation', 'dispensing', 'handover'],
            description:
              'Prescription validation and medicine handover for pharmacy workflows.',
            formSchemas: ['prescription-validation', 'dispense-medicines'],
            timelineEventTypes: ['PRESCRIPTION_VALIDATED', 'MEDICINES_DISPENSED'],
            actions: ['start-verification', 'dispense-medicines'],
          },
          {
            id: 'billing',
            title: 'Billing',
            permission: 'providers.view',
            renderer: 'billing',
            sectionKey: 'billing',
            category: 'billing',
            workflowTags: ['invoice', 'payment', 'benefits'],
            description:
              'Patient billing, wallet usage, benefits, and payment completion.',
            actions: ['open-billing', 'collect-payment'],
            timelineEventTypes: ['INVOICE_GENERATED', 'PAYMENT_COMPLETED'],
          },
        ];
      case 'LABORATORY':
        return [
          ...baseModules,
          {
            id: 'samples',
            title: 'Sample Collection',
            permission: 'providers.view',
            renderer: 'patient-workspace',
            sectionKey: 'customers',
            category: 'care-module',
            workflowTags: ['sample', 'processing', 'verification'],
            description:
              'Sample collection and processing work for laboratory patients.',
            formSchemas: ['sample-collection', 'sample-processing'],
            actions: ['collect-sample', 'update-processing'],
            timelineEventTypes: ['SAMPLE_COLLECTED', 'SAMPLE_PROCESSING'],
          },
          {
            id: 'reports',
            title: 'Lab Reports',
            permission: 'providers.view',
            renderer: 'documents',
            sectionKey: 'documents',
            category: 'records',
            workflowTags: ['reports', 'verification'],
            description: 'Laboratory reports and verification records.',
            actions: ['open-reports', 'verify-report'],
            timelineEventTypes: ['REPORT_UPLOADED', 'REPORT_VERIFIED'],
          },
        ];
      case 'DENTAL':
        return [
          ...baseModules,
          {
            id: 'treatments',
            title: 'Treatments',
            permission: 'providers.view',
            renderer: 'patient-workspace',
            sectionKey: 'customers',
            category: 'care-module',
            workflowTags: ['treatment', 'procedures', 'follow-up'],
            description: 'Dental treatment workflow and procedure tracking.',
            formSchemas: ['dental-procedure', 'treatment-plan'],
            actions: ['start-treatment', 'record-procedure'],
            timelineEventTypes: ['TREATMENT_STARTED', 'PROCEDURE_RECORDED'],
          },
          {
            id: 'prescriptions',
            title: 'Prescriptions',
            permission: 'providers.view',
            renderer: 'prescriptions',
            sectionKey: 'prescriptions',
            category: 'care-module',
            workflowTags: ['prescription', 'aftercare'],
            description: 'Dental aftercare prescriptions and care advice.',
            actions: ['create-prescription', 'review-aftercare'],
            timelineEventTypes: ['PRESCRIPTION_CREATED'],
          },
        ];
      default:
        return [
          ...baseModules,
          {
            id: 'prescriptions',
            title: 'Prescriptions',
            permission: 'providers.view',
            renderer: 'prescriptions',
            sectionKey: 'prescriptions',
            category: 'care-module',
            workflowTags: ['consultation', 'prescription', 'follow-up'],
            description:
              'Consultation-linked prescriptions and medication history.',
            formSchemas: ['consultation-prescription'],
            actions: ['create-prescription', 'review-prescriptions'],
            timelineEventTypes: ['PRESCRIPTION_CREATED'],
          },
        ];
    }
  }

  private buildDashboardLayout(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Provider Dashboard',
      description: 'Backend-owned dashboard layout for the provider workday.',
      widgets: [
        {
          id: 'today-patients',
          title: 'Today\'s Patients',
          metricKind: 'appointments-today',
          moduleId: 'dashboard',
          order: 1,
        },
        {
          id: 'waiting-queue',
          title: this.getDashboardWaitingTitle(profile),
          metricKind: 'queue-waiting',
          moduleId: 'queue',
          order: 2,
        },
        {
          id: 'tasks-waiting',
          title: 'Tasks Waiting',
          metricKind: 'active-care',
          moduleId: 'dashboard',
          order: 3,
        },
      ],
    };
  }

  private buildVisitEngine(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Visit Engine',
      description:
        'Every patient interaction is centered around one visit workflow.',
      stageCodes: this.buildWorkflowStages(profile).map((stage) => stage.code),
      linkedDomains: [
        'queue',
        'consultation',
        'documents',
        'prescriptions',
        'billing',
        'wallet',
        'timeline',
        'notes',
      ],
      primaryModuleId: 'patient-workspace',
    };
  }

  private buildWorkflowEngine(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Workflow Engine',
      description:
        'Backend-owned visit stages and provider workflow progression.',
      stages: this.buildWorkflowStages(profile),
      completionActionTitle: this.getReadyStageTitle(profile),
    };
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
        CHECK_IN: 'Check In',
        ASSIGNED: 'Assigned',
        STARTED: 'Care Started',
        COMPLETED: 'Completed',
      },
      emptyStateMessage: 'No patient history is available yet.',
    };
  }

  private buildActionEngine(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Action Engine',
      description: 'Buttons and quick actions are provided by backend contracts.',
      primaryActions: this.buildPatientQuickActions(profile),
    };
  }

  private buildNotificationEngine(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Notification Engine',
      description: 'Provider notifications are backend-generated event types.',
      eventTypes: [
        'PATIENT_ARRIVED',
        'REPORT_READY',
        'PRESCRIPTION_UPLOADED',
        'PAYMENT_COMPLETED',
      ],
      featureFlags: ['in-app-notifications'],
    };
  }

  private buildAuditEngine(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Audit Engine',
      description: 'Critical provider actions must remain auditable.',
      eventTypes: [
        'VIEWED_PATIENT',
        'STARTED_VISIT',
        'UPDATED_CONSULTATION',
        'COMPLETED_VISIT',
      ],
      scope: profile,
    };
  }

  private buildDashboardWidgets(
    profile: ProviderWorkflowProfileCode,
    metrics: {
      waitingCount: number;
      activeCareCount: number;
      billingCount: number;
      appointmentsToday: number;
      pendingAppointments: number;
    },
    dashboardLayout: {
      widgets: Array<{
        id: string;
        title: string;
        metricKind: string;
        moduleId: string;
        order: number;
      }>;
    },
  ) {
    return dashboardLayout.widgets.map((widget) => ({
      id: widget.id,
      title: widget.title,
      value: this.resolveDashboardWidgetValue(widget.metricKind, metrics),
      icon: this.resolveDashboardWidgetIcon(widget.metricKind),
      color: this.resolveDashboardWidgetColor(widget.metricKind),
      destinationModuleId: widget.moduleId,
      refreshIntervalSeconds: 60,
      visibilityRule: 'providers.view',
      order: widget.order,
      emptyStateMessage: this.getDashboardWidgetEmptyState(
        profile,
        widget.metricKind,
      ),
    }));
  }

  private buildWorkspaceWorklists(
    profile: ProviderWorkflowProfileCode,
    metrics: {
      waitingCount: number;
      activeCareCount: number;
      billingCount: number;
      appointmentsToday: number;
      pendingAppointments: number;
    },
    queueStages: Array<{ code: string }>,
  ) {
    return [
      {
        id: 'waiting',
        title: this.getDashboardWaitingTitle(profile),
        count: metrics.waitingCount,
        icon: 'queue',
        color: 'orange',
        stageCodes: ['WAITING', 'ACCEPTED'],
        emptyStateMessage: this.getWaitingEmptyState(profile),
      },
      {
        id: 'active-care',
        title: this.getConsultationStageTitle(profile),
        count: metrics.activeCareCount,
        icon: 'care',
        color: 'blue',
        stageCodes: ['CONSULTATION', 'READY_TO_COMPLETE'],
        emptyStateMessage: this.getConsultationEmptyState(profile),
      },
      {
        id: 'pending-payments',
        title: 'Pending Payments',
        count: metrics.billingCount,
        icon: 'payments',
        color: 'amber',
        stageCodes: ['WAITING_PAYMENT'],
        emptyStateMessage: 'No payments are waiting right now.',
      },
      {
        id: 'today-visits',
        title: "Today's Visits",
        count: metrics.appointmentsToday,
        icon: 'calendar',
        color: 'green',
        stageCodes: queueStages.map((stage) => stage.code),
        emptyStateMessage: 'No visits are scheduled for today.',
      },
    ];
  }

  private buildWorkspaceFilters(profile: ProviderWorkflowProfileCode) {
    return {
      queue: [
        {
          code: 'all-open',
          title: 'All Open Work',
          description: 'Show every active queue stage for this provider.',
          stageCodes: ['WAITING', 'ACCEPTED', 'CONSULTATION', 'WAITING_PAYMENT'],
        },
        {
          code: 'waiting',
          title: this.getDashboardWaitingTitle(profile),
          description: 'Only show patients waiting for the next staff action.',
          stageCodes: ['WAITING', 'ACCEPTED'],
        },
        {
          code: 'active-care',
          title: this.getConsultationStageTitle(profile),
          description: 'Only show active care or service work in progress.',
          stageCodes: ['CONSULTATION', 'READY_TO_COMPLETE'],
        },
        {
          code: 'billing',
          title: 'Pending Payments',
          description: 'Only show visits that still need billing completion.',
          stageCodes: ['WAITING_PAYMENT'],
        },
      ],
      search: [
        {
          code: 'patient-identity',
          title: 'Patient Identity',
          supportedQueries: ['Patient name', 'Patient ID', 'Phone number'],
        },
        {
          code: 'visit-access',
          title: 'Visit Access',
          supportedQueries: ['SHIELD card', 'Membership number', 'Appointment', 'Invoice'],
        },
      ],
    };
  }

  private buildStatusMappings(profile: ProviderWorkflowProfileCode) {
    return {
      queue: {
        WAITING: this.getDashboardWaitingTitle(profile),
        ACCEPTED: 'Accepted',
        CONSULTATION: this.getConsultationStageTitle(profile),
        WAITING_PAYMENT: 'Waiting for Payment',
        READY_TO_COMPLETE: this.getReadyStageTitle(profile),
        COMPLETED: 'Completed',
        CLOSED: 'Closed',
      },
      timeline: {
        APPOINTMENT: 'Visit',
        DOCUMENT: 'Record',
        CHECK_IN: 'Check In',
        ASSIGNED: 'Assigned',
        STARTED: 'Care Started',
        COMPLETED: 'Completed',
      },
    };
  }

  private buildWorkspaceLabels(profile: ProviderWorkflowProfileCode) {
    return {
      patient: 'Patient',
      visit: 'Visit',
      timeline: 'Timeline',
      records: this.getRecordsNavigationTitle(profile),
      prescriptions: this.getPrescriptionsNavigationTitle(profile),
      queueWaiting: this.getDashboardWaitingTitle(profile),
      queueActive: this.getConsultationStageTitle(profile),
      queueReady: this.getReadyStageTitle(profile),
    };
  }

  private buildWorkspaceMessages(profile: ProviderWorkflowProfileCode) {
    return {
      emptyStates: {
        queueWaiting: this.getWaitingEmptyState(profile),
        queueActive: this.getConsultationEmptyState(profile),
        patientWorkspace:
          'Select a patient to open the full care view. Visits, records, benefits, and payments stay together here.',
        search: 'No patients match this search yet.',
        timeline: 'No patient history is available yet.',
      },
      success: {
        consultationStarted: `${this.getConsultationStageTitle(profile)} started successfully.`,
        consultationSaved: 'Visit progress saved successfully.',
        consultationCompleted: 'Visit completed successfully.',
      },
      errors: {
          metadataUnavailable:
          'Provider details could not be loaded right now.',
        patientUnavailable: 'Patient details could not be loaded right now.',
        consultationUnavailable:
          'Visit details could not be loaded right now.',
      },
    };
  }

  private buildPatientWorkspace(profile: ProviderWorkflowProfileCode) {
    return {
      title: 'Patient Record',
      description:
        'Open one patient and keep visits, records, billing, and follow-up work together in one place.',
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

  private buildWorkflowStages(profile: ProviderWorkflowProfileCode) {
    return [
      {
        code: 'CHECK_IN',
        title: 'Check In',
        order: 1,
      },
      {
        code: 'ASSIGNED',
        title: 'Assigned',
        order: 2,
      },
      {
        code: 'IN_PROGRESS',
        title: this.getConsultationStageTitle(profile),
        order: 3,
      },
      {
        code: 'WAITING_PAYMENT',
        title: 'Waiting for Payment',
        order: 4,
      },
      {
        code: 'COMPLETED',
        title: 'Completed',
        order: 5,
      },
      {
        code: 'CLOSED',
        title: 'Closed',
        order: 6,
      },
    ];
  }

  private resolveDashboardWidgetValue(
    metricKind: string,
    metrics: {
      waitingCount: number;
      activeCareCount: number;
      billingCount: number;
      appointmentsToday: number;
      pendingAppointments: number;
    },
  ) {
    switch (metricKind) {
      case 'appointments-today':
        return metrics.appointmentsToday;
      case 'queue-waiting':
        return metrics.waitingCount;
      case 'active-care':
        return metrics.activeCareCount;
      case 'pending-appointments':
        return metrics.pendingAppointments;
      case 'pending-payments':
        return metrics.billingCount;
      default:
        return 0;
    }
  }

  private resolveDashboardWidgetIcon(metricKind: string) {
    switch (metricKind) {
      case 'appointments-today':
        return 'calendar';
      case 'queue-waiting':
        return 'queue';
      case 'active-care':
        return 'care';
      case 'pending-payments':
        return 'payments';
      default:
        return 'dashboard';
    }
  }

  private resolveDashboardWidgetColor(metricKind: string) {
    switch (metricKind) {
      case 'queue-waiting':
        return 'orange';
      case 'active-care':
        return 'blue';
      case 'pending-payments':
        return 'amber';
      default:
        return 'green';
    }
  }

  private getDashboardWidgetEmptyState(
    profile: ProviderWorkflowProfileCode,
    metricKind: string,
  ) {
    switch (metricKind) {
      case 'appointments-today':
        return 'No visits are scheduled for today.';
      case 'queue-waiting':
        return this.getWaitingEmptyState(profile);
      case 'active-care':
        return this.getConsultationEmptyState(profile);
      case 'pending-payments':
        return 'No payments are waiting right now.';
      default:
        return 'No dashboard activity is available yet.';
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
        return 'Pharmacy Operations';
      case 'DENTAL':
        return 'Dental Operations';
      case 'LABORATORY':
        return 'Laboratory Operations';
      case 'HOME_VISIT':
        return 'Home Care Operations';
      case 'COSMETIC':
        return 'Cosmetic Care Operations';
      case 'DIETITIAN':
        return 'Dietitian Operations';
      case 'CLINIC':
        return 'Clinic Operations';
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
      return 'Open one patient and keep verification, records, membership, and payments together in one place.';
      case 'LABORATORY':
      return 'Open one patient and keep sample work, reports, billing, and follow-up together in one place.';
      default:
      return 'Open one patient and keep appointments, medical records, membership, and payments together in one place.';
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
