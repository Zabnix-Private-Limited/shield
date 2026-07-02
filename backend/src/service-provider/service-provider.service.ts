import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import { ProviderScopeService } from '../auth/provider-scope.service';
import { CustomerService } from '../customer/customer.service';
import { WalletService } from '../wallet/wallet.service';
import { AppointmentService } from '../appointment/appointment.service';
import type { ShieldPrincipal } from '../auth/auth.types';
import { DocumentService } from '../document/document.service';
import { NotificationService } from '../notification/notification.service';
import { PharmacyService } from '../pharmacy/pharmacy.service';
import { PlatformPrintService } from '../platform-capabilities/platform-print.service';
import { TimelineService } from '../timeline/timeline.service';
import { StorageService } from '../storage/storage.service';

type ProviderProfileAssetType = 'photo' | 'signature';

@Injectable()
export class ServiceProviderService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly providerScopeService: ProviderScopeService,
    private readonly customerService: CustomerService,
    private readonly walletService: WalletService,
    private readonly appointmentService: AppointmentService,
    private readonly documentService: DocumentService,
    private readonly notificationService: NotificationService,
    private readonly pharmacyService: PharmacyService,
    private readonly timelineService: TimelineService,
    private readonly platformPrintService: PlatformPrintService,
    private readonly storageService: StorageService,
  ) {}

  async create(data: any) {
    return this.prisma.serviceProvider.create({
      data: {
        uuid: randomUUID(),
        providerName: data.providerName,
        providerType: data.providerType,
        status: data.status || 'ACTIVE',
        businessId: data.businessId ? BigInt(data.businessId) : null,
      },
      include: {
        business: true,
      },
    });
  }

  async findAll() {
    return this.prisma.serviceProvider.findMany({
      include: {
        business: true,
      },
      orderBy: {
        id: 'asc',
      },
    });
  }

  async findOne(id: bigint) {
    const provider = await this.prisma.serviceProvider.findUnique({
      where: { id },
      include: {
        business: true,
      },
    });
    if (!provider) {
      throw new NotFoundException(`Service Provider with ID ${id} not found`);
    }
    return provider;
  }

  async update(id: bigint, data: any) {
    await this.findOne(id);
    return this.prisma.serviceProvider.update({
      where: { id },
      data: {
        providerName: data.providerName,
        providerType: data.providerType,
        status: data.status,
        businessId: data.businessId ? BigInt(data.businessId) : null,
      },
      include: {
        business: true,
      },
    });
  }

  async remove(id: bigint) {
    await this.findOne(id);
    return this.prisma.serviceProvider.delete({
      where: { id },
    });
  }

  async getPerformance(id: bigint) {
    await this.findOne(id);

    const [
      totalAppointments,
      completedAppointments,
      cancelledAppointments,
      totalPurchases,
      billingAggregate,
      uniquePatientsAppointments,
      uniquePatientsPurchases,
    ] = await Promise.all([
      this.prisma.appointment.count({ where: { providerId: id } }),
      this.prisma.appointment.count({ where: { providerId: id, status: 'COMPLETED' } }),
      this.prisma.appointment.count({ where: { providerId: id, status: 'CANCELLED' } }),
      this.prisma.purchase.count({ where: { providerId: id } }),
      this.prisma.purchase.aggregate({
        where: { providerId: id },
        _sum: { payableAmount: true, totalAmount: true },
      }),
      this.prisma.appointment.findMany({
        where: { providerId: id },
        distinct: ['customerId'],
        select: { customerId: true },
      }),
      this.prisma.purchase.findMany({
        where: { providerId: id },
        distinct: ['customerId'],
        select: { customerId: true },
      }),
    ]);

    // Compute unique patients union
    const patientIds = new Set<string>();
    uniquePatientsAppointments.forEach((item) => {
      if (item.customerId) patientIds.add(item.customerId.toString());
    });
    uniquePatientsPurchases.forEach((item) => {
      if (item.customerId) patientIds.add(item.customerId.toString());
    });

    const revenue = Number(billingAggregate._sum.payableAmount || 0);
    const totalBilled = Number(billingAggregate._sum.totalAmount || 0);

    return {
      providerId: id.toString(),
      totalAppointments,
      completedAppointments,
      cancelledAppointments,
      totalPurchases,
      revenue,
      totalBilled,
      uniquePatients: patientIds.size,
      completionRate: totalAppointments > 0 ? (completedAppointments / totalAppointments) * 100 : 0,
    };
  }

  async getAnalytics() {
    const providers = await this.prisma.serviceProvider.findMany({
      include: {
        business: true,
      },
    });

    const analytics = await Promise.all(
      providers.map(async (provider) => {
        const perf = await this.getPerformance(provider.id);
        return {
          id: provider.id.toString(),
          name: provider.providerName,
          type: provider.providerType,
          status: provider.status,
          branch: provider.business?.name || 'Central Group',
          appointments: perf.totalAppointments,
          completedAppointments: perf.completedAppointments,
          revenue: perf.revenue,
          uniquePatients: perf.uniquePatients,
        };
      }),
    );

    // Group-level summary
    const typeSummary: Record<string, { count: number; appointments: number; revenue: number }> = {};
    let totalRevenue = 0;
    let totalAppointments = 0;

    for (const item of analytics) {
      const type = item.type || 'UNKNOWN';
      if (!typeSummary[type]) {
        typeSummary[type] = { count: 0, appointments: 0, revenue: 0 };
      }
      typeSummary[type].count += 1;
      typeSummary[type].appointments += item.appointments;
      typeSummary[type].revenue += item.revenue;

      totalRevenue += item.revenue;
      totalAppointments += item.appointments;
    }

    return {
      generatedAt: new Date().toISOString(),
      totalRevenue,
      totalAppointments,
      providerCount: providers.length,
      byType: Object.entries(typeSummary).map(([type, stats]) => ({
        type,
        ...stats,
      })),
      providers: analytics,
    };
  }

  async getCurrentProviderProfile(principal?: ShieldPrincipal) {
    const context = await this.resolveCurrentProviderContext(principal);
    return this.buildCurrentProviderProfileResponse(context.user, context.profile);
  }

  async updateCurrentProviderProfile(principal: ShieldPrincipal | undefined, data: any) {
    const context = await this.resolveCurrentProviderContext(principal);
    const normalized = await this.normalizeProviderProfileInput(
      data,
      context.user,
      context.profile,
    );

    const profile = await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: context.user.id },
        data: {
          branchBusinessId: normalized.primaryBranchId,
          departmentId: normalized.departmentId,
        },
      });

      const ensuredProfile = context.profile
        ? context.profile
        : await tx.providerProfile.create({
            data: {
              uuid: randomUUID(),
              userId: context.user.id,
            },
          });

      await tx.providerProfile.update({
        where: { id: ensuredProfile.id },
        data: {
          displayName: normalized.displayName,
          contactEmail: normalized.contactEmail,
          contactPhone: normalized.contactPhone,
          qualifications: normalized.qualifications,
          specialization: normalized.specialization,
          registrationDetails: normalized.registrationDetails,
          consultationAvailability: normalized.consultationAvailability,
          workingHours: normalized.workingHours,
          notificationPreferences: normalized.notificationPreferences,
          printPreferences: normalized.printPreferences,
          themePreference: normalized.themePreference,
          languagePreference: normalized.languagePreference,
          defaultPrinter: normalized.defaultPrinter,
          timezone: normalized.timezone,
        },
      });

      await tx.providerProfileBranchAssignment.deleteMany({
        where: { providerProfileId: ensuredProfile.id },
      });

      if (normalized.assignedBranchIds.length > 0) {
        await tx.providerProfileBranchAssignment.createMany({
          data: normalized.assignedBranchIds.map((businessId) => ({
            providerProfileId: ensuredProfile.id,
            businessId,
            isPrimary:
              normalized.primaryBranchId != null &&
              businessId === normalized.primaryBranchId,
          })),
        });
      }

      return tx.user.findUnique({
        where: { id: context.user.id },
        include: this.providerProfileInclude(),
      });
    });

    return this.buildCurrentProviderProfileResponse(profile, profile?.providerProfile);
  }

  async updateCurrentProviderPreferences(
    principal: ShieldPrincipal | undefined,
    data: any,
  ) {
    return this.updateCurrentProviderProfile(principal, { preferences: data });
  }

  async uploadCurrentProviderAsset(
    principal: ShieldPrincipal | undefined,
    assetType: ProviderProfileAssetType,
    file: any,
  ) {
    const context = await this.resolveCurrentProviderContext(principal);
    if (!file?.buffer?.length) {
      throw new BadRequestException('Select a file to continue.');
    }

    const mimeType = (file.mimetype || '').toString().trim().toLowerCase();
    const allowedMimeTypes =
      assetType === 'photo'
        ? ['image/png', 'image/jpeg', 'image/webp']
        : ['image/png', 'image/jpeg', 'image/webp'];
    if (!allowedMimeTypes.includes(mimeType)) {
      throw new BadRequestException(
        assetType === 'photo'
          ? 'Profile photo must be a PNG, JPG, or WEBP image.'
          : 'Digital signature must be a PNG, JPG, or WEBP image.',
      );
    }

    const fileName =
      file.originalname?.toString().trim() ||
      (assetType === 'photo' ? 'profile-photo.png' : 'digital-signature.png');
    const persistedFile = await this.storageService.persistScopedPrivateObject({
      scope: `providers/${assetType === 'photo' ? 'photos' : 'signatures'}`,
      ownerId: `user-${context.user.id.toString()}`,
      objectUuid: randomUUID(),
      fileName,
      mimeType,
      buffer: file.buffer,
    });
    if (!persistedFile?.storagePath) {
      throw new BadRequestException('Unable to store the uploaded file.');
    }

    const profile = await this.prisma.providerProfile.upsert({
      where: { userId: context.user.id },
      update:
        assetType === 'photo'
          ? {
              profilePhotoStoragePath: persistedFile.storagePath,
              profilePhotoFileName: fileName,
            }
          : {
              signatureStoragePath: persistedFile.storagePath,
              signatureFileName: fileName,
            },
      create: {
        uuid: randomUUID(),
        userId: context.user.id,
        ...(assetType === 'photo'
          ? {
              profilePhotoStoragePath: persistedFile.storagePath,
              profilePhotoFileName: fileName,
            }
          : {
              signatureStoragePath: persistedFile.storagePath,
              signatureFileName: fileName,
            }),
      },
    });

    const user = await this.prisma.user.findUnique({
      where: { id: context.user.id },
      include: this.providerProfileInclude(),
    });

    return this.buildCurrentProviderProfileResponse(user, profile ?? user?.providerProfile);
  }

  async getPatientWorkspace(customerId: bigint, principal?: ShieldPrincipal) {
    await this.providerScopeService.assertProviderCanAccessCustomer(
      customerId,
      principal,
    );
    const [
      patient,
      membership,
      wallet,
      documents,
      appointments,
      notifications,
      purchases,
    ] = await Promise.all([
      this.customerService.findOne(customerId),
      this.customerService.getCustomerPortalMembership(customerId),
      this.walletService.getCustomerWalletBundle(customerId),
      this.documentService.list(customerId, principal),
      this.appointmentService.list(customerId, principal),
      this.notificationService.list(customerId, principal),
      this.pharmacyService.listPurchases(customerId, principal),
    ]);

    const activeAppointment = this.resolvePrimaryVisitAppointment(appointments);
    const activeVisitWorkspace = activeAppointment
      ? await this.appointmentService.getConsultationWorkspace(
          activeAppointment.id,
          principal,
        )
      : null;
    const timeline = await this.timelineService.getPatientTimeline(customerId);

    if (principal?.userId) {
      await this.timelineService.recordAuditLog({
        action: 'VIEWED_PATIENT',
        entityType: 'PATIENT',
        entityId: customerId,
        userId: BigInt(principal.userId),
        newData: {
          customerId: customerId.toString(),
          roleCode: principal.roleCode,
        },
      });
    }

    const totalBilled = purchases.reduce(
      (sum, purchase) => sum + Number(purchase.totalAmount || 0),
      0,
    );
    const totalPayable = purchases.reduce(
      (sum, purchase) => sum + Number(purchase.payableAmount || 0),
      0,
    );
    const totalDiscount = purchases.reduce(
      (sum, purchase) => sum + Number(purchase.discountAmount || 0),
      0,
    );
    const openAppointments = appointments.filter(
      (appointment) =>
        !this.isCompletedAppointmentStatus(appointment.status) &&
        !this.isCancelledAppointmentStatus(appointment.status),
    );
    const completedAppointments = appointments.filter((appointment) =>
      this.isCompletedAppointmentStatus(appointment.status),
    );
    const unreadNotifications = notifications.filter(
      (notification) =>
        (notification.status || '').toString().toUpperCase() !== 'READ',
    );
    const printing = this.platformPrintService.buildProviderPatientPrintContext({
      providerContext: principal
        ? {
            providerName: 'SHIELD Provider',
            role: principal.roleCode ?? 'Provider',
            branch: { name: 'Branch not assigned' },
            business: { name: 'SHIELD' },
          }
        : null,
      patient: patient as Record<string, any>,
      membership: membership as Record<string, any>,
      wallet: wallet as Record<string, any>,
      activeVisit: activeAppointment
        ? {
            appointmentId: activeAppointment.id.toString(),
            appointment: activeAppointment,
            status:
              activeVisitWorkspace?.statusLabel ??
              this.humanizeCode(activeAppointment.status),
            workspace: activeVisitWorkspace,
          }
        : null,
      billing: {
        summary: {
          totalInvoices: purchases.length,
          totalBilled,
          totalPayable,
          totalDiscount,
          lastInvoiceDate: purchases[0]?.purchaseDate ?? null,
          lastInvoiceNumber: purchases[0]?.invoiceNumber ?? null,
        },
      },
      timeline: timeline as Array<Record<string, any>>,
      documents: documents as Array<Record<string, any>>,
    });

    return {
      patient,
      membership,
      wallet,
      activeVisit: activeAppointment
        ? {
            appointmentId: activeAppointment.id.toString(),
            appointment: activeAppointment,
            status: activeVisitWorkspace?.statusLabel ?? this.humanizeCode(activeAppointment.status),
            workspace: activeVisitWorkspace,
          }
        : null,
      timeline,
      documents: {
        items: documents,
        total: documents.length,
        groupedCounts: {
          prescriptions: documents.filter((document) =>
            this.matchesAnyCode(document.documentType, ['PRESCRIPTION']),
          ).length,
          labReports: documents.filter((document) =>
            this.matchesAnyCode(document.documentType, ['LAB_REPORT']),
          ).length,
          invoices: documents.filter((document) =>
            this.matchesAnyCode(document.documentType, ['INVOICE', 'PHARMACY_BILL']),
          ).length,
          other: documents.filter(
            (document) =>
              !this.matchesAnyCode(document.documentType, [
                'PRESCRIPTION',
                'LAB_REPORT',
                'INVOICE',
                'PHARMACY_BILL',
              ]),
          ).length,
        },
      },
      billing: {
        items: purchases,
        summary: {
          totalInvoices: purchases.length,
          totalBilled,
          totalPayable,
          totalDiscount,
          lastInvoiceDate: purchases[0]?.purchaseDate ?? null,
        },
      },
      notifications: {
        items: notifications,
        unreadCount: unreadNotifications.length,
      },
      appointments: {
        items: appointments,
        summary: {
          total: appointments.length,
          active: openAppointments.length,
          completed: completedAppointments.length,
          upcoming: openAppointments.filter(
            (appointment) =>
              appointment.appointmentDate != null &&
              new Date(appointment.appointmentDate).getTime() > Date.now(),
          ).length,
        },
      },
      analytics: {
        totalDocuments: documents.length,
        totalTimelineEvents: timeline.length,
        totalNotifications: notifications.length,
        totalPurchases: purchases.length,
        totalWalletTransactions: Array.isArray(wallet.recentTransactions)
          ? wallet.recentTransactions.length
          : 0,
        pendingAppointments: openAppointments.length,
        completedAppointments: completedAppointments.length,
      },
      printing,
      actions: this.buildWorkspaceActions(!!activeAppointment),
    };
  }

  private providerProfileInclude() {
    return {
      role: true,
      department: true,
      branchBusiness: true,
      providerProfile: {
        include: {
          branchAssignments: {
            include: {
              business: true,
            },
            orderBy: {
              businessId: 'asc' as const,
            },
          },
        },
      },
    };
  }

  private async resolveCurrentProviderContext(principal?: ShieldPrincipal) {
    if (!principal?.userId) {
      throw new UnauthorizedException('Authenticated provider context is required.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: BigInt(principal.userId) },
      include: this.providerProfileInclude(),
    });
    if (!user) {
      throw new NotFoundException('Provider account not found.');
    }

    return {
      user,
      profile: user.providerProfile,
    };
  }

  private async buildCurrentProviderProfileResponse(user: any, profile: any) {
    if (!user) {
      throw new NotFoundException('Provider account not found.');
    }

    const activeBusinesses = await this.prisma.business.findMany({
      where: { status: 'ACTIVE' },
      orderBy: [{ name: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        name: true,
        businessType: true,
        status: true,
      },
    });
    const activeDepartments = await this.prisma.department.findMany({
      where: { status: 'ACTIVE' },
      orderBy: [{ name: 'asc' }],
      select: {
        id: true,
        uuid: true,
        code: true,
        name: true,
        status: true,
        businessId: true,
        business: {
          select: {
            id: true,
            code: true,
            name: true,
          },
        },
      },
    });

    const assignedBranches = new Map<string, any>();
    for (const assignment of profile?.branchAssignments ?? []) {
      if (assignment.business) {
        assignedBranches.set(assignment.businessId.toString(), {
          id: assignment.business.id.toString(),
          code: assignment.business.code,
          name: assignment.business.name,
          businessType: assignment.business.businessType,
          status: assignment.business.status,
          isPrimary: assignment.isPrimary === true,
        });
      }
    }
    if (user.branchBusiness) {
      assignedBranches.set(user.branchBusiness.id.toString(), {
        id: user.branchBusiness.id.toString(),
        code: user.branchBusiness.code,
        name: user.branchBusiness.name,
        businessType: user.branchBusiness.businessType,
        status: user.branchBusiness.status,
        isPrimary: true,
      });
    }

    const photoUrl = profile?.profilePhotoStoragePath
      ? await this.storageService.createDownloadUrl(profile.profilePhotoStoragePath)
      : null;
    const signatureUrl = profile?.signatureStoragePath
      ? await this.storageService.createDownloadUrl(profile.signatureStoragePath)
      : null;

    return {
      profileId: profile?.id?.toString() ?? null,
      userId: user.id.toString(),
      displayName:
        profile?.displayName?.trim() ||
        [user.firstName, user.lastName].filter(Boolean).join(' ').trim() ||
        user.email ||
        'SHIELD Provider',
      contact: {
        email: profile?.contactEmail?.trim() || user.email || null,
        phone: profile?.contactPhone?.trim() || user.mobile || null,
        signInEmail: user.email || null,
        signInMobile: user.mobile || null,
      },
      role: user.role
        ? {
            code: user.role.code,
            name: user.role.name,
          }
        : null,
      department: user.department
        ? {
            id: user.department.id.toString(),
            code: user.department.code,
            name: user.department.name,
            businessId: user.department.businessId?.toString() ?? null,
          }
        : null,
      primaryBranch: user.branchBusiness
        ? {
            id: user.branchBusiness.id.toString(),
            code: user.branchBusiness.code,
            name: user.branchBusiness.name,
            businessType: user.branchBusiness.businessType,
            status: user.branchBusiness.status,
          }
        : null,
      assignedBranches: Array.from(assignedBranches.values()),
      qualifications: profile?.qualifications ?? '',
      specialization: profile?.specialization ?? '',
      registration: this.normalizeStoredObject(profile?.registrationDetails),
      consultationAvailability: this.normalizeStoredObject(
        profile?.consultationAvailability,
      ),
      workingHours: this.normalizeStoredObject(profile?.workingHours),
      assets: {
        profilePhoto: {
          fileName: profile?.profilePhotoFileName ?? null,
          url: photoUrl,
        },
        digitalSignature: {
          fileName: profile?.signatureFileName ?? null,
          url: signatureUrl,
        },
      },
      preferences: {
        notifications: this.normalizeStoredObject(profile?.notificationPreferences, {
          appointmentChanges: true,
          visitUpdates: true,
          prescriptionUpdates: true,
          billingUpdates: true,
        }),
        theme: profile?.themePreference ?? 'system',
        language: profile?.languagePreference ?? 'en',
        defaultPrinter: profile?.defaultPrinter ?? '',
        print: this.normalizeStoredObject(profile?.printPreferences, {
          autoOpenPdf: true,
          includeSignature: true,
          paperSize: 'A4',
        }),
        timezone: profile?.timezone ?? 'Asia/Calcutta',
      },
      lookups: {
        branches: activeBusinesses.map((business) => ({
          id: business.id.toString(),
          uuid: business.uuid,
          code: business.code,
          name: business.name,
          businessType: business.businessType,
          status: business.status,
        })),
        departments: activeDepartments.map((department) => ({
          id: department.id.toString(),
          uuid: department.uuid,
          code: department.code,
          name: department.name,
          status: department.status,
          businessId: department.businessId.toString(),
          businessName: department.business?.name ?? null,
          businessCode: department.business?.code ?? null,
        })),
      },
      updatedAt: profile?.updatedAt ? profile.updatedAt.toISOString() : null,
    };
  }

  private async normalizeProviderProfileInput(data: any, user: any, profile: any) {
    const preferences = this.normalizeObject(data?.preferences);
    const existingAssignedBranchIds = [
      ...(profile?.branchAssignments ?? []).map((assignment: any) => assignment.businessId),
      ...(user.branchBusinessId != null ? [user.branchBusinessId] : []),
    ];
    const branchIds = this.normalizeIdList(
      data?.assignedBranchIds ??
        data?.assignedBranches?.map?.((branch: any) => branch?.id ?? branch) ??
        existingAssignedBranchIds,
    );
    const primaryBranchId = this.normalizeOptionalBigInt(
      data?.primaryBranchId ?? data?.primaryBranch?.id ?? user.branchBusinessId,
    );
    if (primaryBranchId != null && !branchIds.some((branchId) => branchId === primaryBranchId)) {
      branchIds.unshift(primaryBranchId);
    }

    const uniqueBranchIds = Array.from(
      new Map(branchIds.map((branchId) => [branchId.toString(), branchId])).values(),
    );
    if (uniqueBranchIds.length > 0) {
      const branchCount = await this.prisma.business.count({
        where: {
          id: { in: uniqueBranchIds },
        },
      });
      if (branchCount !== uniqueBranchIds.length) {
        throw new BadRequestException('One or more assigned branches are invalid.');
      }
    }

    const departmentId = this.normalizeOptionalBigInt(
      data?.departmentId ?? data?.department?.id ?? user.departmentId,
    );
    if (departmentId != null) {
      const department = await this.prisma.department.findUnique({
        where: { id: departmentId },
        select: { id: true, businessId: true },
      });
      if (!department) {
        throw new BadRequestException('Selected department is invalid.');
      }
      if (
        uniqueBranchIds.length > 0 &&
        !uniqueBranchIds.some((branchId) => branchId === department.businessId)
      ) {
        throw new BadRequestException(
          'Selected department must belong to an assigned branch.',
        );
      }
    }

    return {
      displayName: this.normalizeOptionalText(
        data?.displayName ?? profile?.displayName,
      ),
      contactEmail: this.normalizeOptionalText(
        data?.contactEmail ?? data?.contact?.email ?? profile?.contactEmail,
      ),
      contactPhone: this.normalizeOptionalText(
        data?.contactPhone ?? data?.contact?.phone ?? profile?.contactPhone,
      ),
      qualifications: this.normalizeOptionalText(
        data?.qualifications ?? profile?.qualifications,
      ),
      specialization: this.normalizeOptionalText(
        data?.specialization ?? profile?.specialization,
      ),
      registrationDetails: this.normalizeObject(
        data?.registration ?? data?.registrationDetails ?? profile?.registrationDetails,
      ),
      consultationAvailability: this.normalizeObject(
        data?.consultationAvailability ?? profile?.consultationAvailability,
      ),
      workingHours: this.normalizeObject(
        data?.workingHours ?? profile?.workingHours,
      ),
      notificationPreferences: this.normalizeObject(
        preferences['notifications'] ??
          data?.notificationPreferences ??
          profile?.notificationPreferences,
      ),
      printPreferences: this.normalizeObject(
        preferences['print'] ?? data?.printPreferences ?? profile?.printPreferences,
      ),
      themePreference: this.normalizeOptionalText(
        preferences['theme'] ?? data?.themePreference ?? profile?.themePreference,
      ),
      languagePreference: this.normalizeOptionalText(
        preferences['language'] ??
          data?.languagePreference ??
          profile?.languagePreference,
      ),
      defaultPrinter: this.normalizeOptionalText(
        preferences['defaultPrinter'] ??
          data?.defaultPrinter ??
          profile?.defaultPrinter,
      ),
      timezone: this.normalizeOptionalText(
        preferences['timezone'] ?? data?.timezone ?? profile?.timezone,
      ),
      primaryBranchId,
      departmentId,
      assignedBranchIds: uniqueBranchIds,
    };
  }

  private normalizeOptionalText(value: unknown) {
    if (value == null) {
      return null;
    }
    const normalized = value.toString().trim();
    return normalized.length === 0 ? null : normalized;
  }

  private normalizeOptionalBigInt(value: unknown) {
    if (value == null) {
      return null;
    }
    const normalized = value.toString().trim();
    if (!normalized) {
      return null;
    }
    return BigInt(normalized);
  }

  private normalizeIdList(value: unknown) {
    if (!Array.isArray(value)) {
      return [] as bigint[];
    }
    return value
      .map((entry) => this.normalizeOptionalBigInt(entry))
      .filter((entry): entry is bigint => entry != null);
  }

  private normalizeObject(value: unknown, fallback: Record<string, any> = {}) {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return fallback;
    }
    return JSON.parse(JSON.stringify(value));
  }

  private normalizeStoredObject(value: unknown, fallback: Record<string, any> = {}) {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return fallback;
    }
    return value as Record<string, any>;
  }

  private resolvePrimaryVisitAppointment(appointments: Array<any>) {
    const incomplete = appointments
      .filter(
        (appointment) =>
          !this.isCompletedAppointmentStatus(appointment.status) &&
          !this.isCancelledAppointmentStatus(appointment.status),
      )
      .sort(
        (left, right) =>
          new Date(left.appointmentDate).getTime() -
          new Date(right.appointmentDate).getTime(),
      );

    if (incomplete.length > 0) {
      return incomplete[0];
    }

    const completed = [...appointments].sort(
      (left, right) =>
        new Date(right.appointmentDate).getTime() -
        new Date(left.appointmentDate).getTime(),
    );

    return completed[0] ?? null;
  }

  private buildWorkspaceActions(hasActiveVisit: boolean) {
    return [
      {
        code: hasActiveVisit ? 'CONTINUE_VISIT' : 'START_VISIT',
        title: hasActiveVisit ? 'Continue Visit' : 'Start Visit',
        icon: hasActiveVisit ? 'play_circle' : 'play_arrow',
        targetTab: 'today-visit',
      },
      {
        code: 'COMPLETE_VISIT',
        title: 'Complete Visit',
        icon: 'task_alt',
        targetTab: 'today-visit',
      },
      {
        code: 'ADD_CLINICAL_NOTE',
        title: 'Add Clinical Note',
        icon: 'note_alt',
        targetTab: 'today-visit',
      },
      {
        code: 'BOOK_APPOINTMENT',
        title: 'Book Appointment',
        icon: 'event',
        targetTab: 'appointments',
      },
      {
        code: 'UPLOAD_DOCUMENT',
        title: 'Upload Document',
        icon: 'upload_file',
        targetTab: 'documents',
      },
      {
        code: 'UPLOAD_LAB_REPORT',
        title: 'Upload Lab Report',
        icon: 'lab_profile',
        targetTab: 'records',
      },
      {
        code: 'GENERATE_PRESCRIPTION',
        title: 'Generate Prescription',
        icon: 'medication',
        targetTab: 'prescriptions',
      },
      {
        code: 'BOOK_FOLLOW_UP',
        title: 'Book Follow-up',
        icon: 'event_repeat',
        targetTab: 'appointments',
      },
      {
        code: 'GENERATE_INVOICE',
        title: 'Generate Invoice',
        icon: 'receipt_long',
        targetTab: 'payments',
      },
      {
        code: 'RECORD_PAYMENT',
        title: 'Record Payment',
        icon: 'payments',
        targetTab: 'today-visit',
      },
      {
        code: 'SEND_NOTIFICATION',
        title: 'Send Notification',
        icon: 'notifications',
        targetTab: 'overview',
      },
      {
        code: 'PRINT_PRESCRIPTION',
        title: 'Print Prescription',
        icon: 'print',
        targetTab: 'prescriptions',
      },
      {
        code: 'PRINT_INVOICE',
        title: 'Print Invoice',
        icon: 'print',
        targetTab: 'payments',
      },
      {
        code: 'PRINT_VISIT_SUMMARY',
        title: 'Print Visit Summary',
        icon: 'print',
        targetTab: 'today-visit',
      },
    ];
  }

  private isCompletedAppointmentStatus(status: string | null | undefined) {
    return (status || '').toString().toUpperCase() === 'COMPLETED';
  }

  private isCancelledAppointmentStatus(status: string | null | undefined) {
    return (status || '').toString().toUpperCase() === 'CANCELLED';
  }

  private matchesAnyCode(value: string | null | undefined, codes: Array<string>) {
    const normalized = (value || '').toString().trim().toUpperCase();
    return codes.includes(normalized);
  }

  private humanizeCode(value: string | null | undefined) {
    const normalized = (value || '').toString().trim();
    if (!normalized) {
      return '';
    }

    return normalized
      .replace(/_/g, ' ')
      .toLowerCase()
      .replace(/\b\w/g, (character) => character.toUpperCase());
  }
}
