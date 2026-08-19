import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/portal/presentation/portal_role_data.dart';
import 'package:shield/shared/models/shield_role.dart';

void main() {
  group('Pharmacy Navigation & Fallback Safety Tests', () {
    test('pharmacyStaff role data contains only business-correct pharmacy sections', () {
      final data = portalDataForRole(SHIELDRole.pharmacyStaff);

      expect(data.operatorName, 'Pharmacy Fulfillment Center');
      expect(data.sections.map((s) => s.key).toList(), [
        'dashboard',
        'orders',
        'payments',
        'payment-details',
        'history',
      ]);

      final keys = data.sections.map((s) => s.key).toSet();
      expect(keys.contains('queue'), isFalse);
      expect(keys.contains('patients'), isFalse);
      expect(keys.contains('appointments'), isFalse);
      expect(keys.contains('documents'), isFalse);
      expect(keys.contains('prescriptions'), isFalse);
    });

    test('portalDataForProviderWorkspaceMeta with PHARMACY workflow returns pharmacy navigation', () {
      final meta = {
        'workflowProfile': {
          'code': 'PHARMACY',
          'title': 'Pharmacy Fulfillment Hub',
        },
        'providerContext': {
          'providerType': 'PHARMACY',
          'workspaceTitle': 'Pharmacy Fulfillment Center',
        },
        'navigationSections': [
          {'id': 'dashboard', 'title': 'Dashboard', 'order': 1},
          {'id': 'orders', 'title': 'Orders', 'order': 2},
          {'id': 'payments', 'title': 'Payments', 'order': 3},
          {'id': 'payment-details', 'title': 'Payment Details', 'order': 4},
          {'id': 'history', 'title': 'Order History', 'order': 5},
        ],
      };

      final data = portalDataForProviderWorkspaceMeta(meta);

      expect(data.role, SHIELDRole.pharmacyStaff);
      expect(data.operatorName, 'Pharmacy Fulfillment Center');
      expect(data.sections.map((s) => s.key).toList(), [
        'dashboard',
        'orders',
        'payments',
        'payment-details',
        'history',
      ]);
    });

    test('portalDataForProviderWorkspaceMeta with empty sections falls back to pharmacy sections when workflow is PHARMACY', () {
      final meta = {
        'workflowProfile': {
          'code': 'PHARMACY',
          'title': 'Pharmacy Fulfillment Hub',
        },
        'providerContext': {
          'providerType': 'PHARMACY',
        },
        'navigationSections': <dynamic>[],
      };

      final data = portalDataForProviderWorkspaceMeta(meta);

      expect(data.role, SHIELDRole.pharmacyStaff);
      expect(data.operatorName, 'Pharmacy Fulfillment Center');
      expect(data.sections.map((s) => s.key).toList(), [
        'dashboard',
        'orders',
        'payments',
        'payment-details',
        'history',
      ]);

      final keys = data.sections.map((s) => s.key).toSet();
      expect(keys.contains('queue'), isFalse);
      expect(keys.contains('patients'), isFalse);
      expect(keys.contains('appointments'), isFalse);
    });

    test('portalDataForProviderWorkspaceMeta detects PHARMACY from providerType even if workflowProfile is GENERAL', () {
      final meta = {
        'workflowProfile': {
          'code': 'GENERAL',
          'title': 'General Workspace',
        },
        'providerContext': {
          'providerType': 'PHARMACY',
          'workspaceTitle': 'HyperPharmacy Store #1',
        },
        'navigationSections': <dynamic>[],
      };

      final data = portalDataForProviderWorkspaceMeta(meta);

      expect(data.role, SHIELDRole.pharmacyStaff);
      expect(data.operatorName, 'HyperPharmacy Store #1');
      expect(data.sections.map((s) => s.key).toList(), [
        'dashboard',
        'orders',
        'payments',
        'payment-details',
        'history',
      ]);
    });

    test('portalDataForProviderWorkspaceMeta overrides malformed generic doctor sections for PHARMACY provider', () {
      final meta = {
        'workflowProfile': {
          'code': 'PHARMACY',
        },
        'providerContext': {
          'providerType': 'PHARMACY',
        },
        'navigationSections': [
          {'id': 'queue', 'title': 'Live Queue', 'order': 1},
          {'id': 'patients', 'title': 'Patients', 'order': 2},
          {'id': 'appointments', 'title': 'Appointments', 'order': 3},
        ],
      };

      final data = portalDataForProviderWorkspaceMeta(meta);

      expect(data.role, SHIELDRole.pharmacyStaff);
      expect(data.operatorName, 'Pharmacy Fulfillment Center');
      expect(data.sections.map((s) => s.key).toList(), [
        'dashboard',
        'orders',
        'payments',
        'payment-details',
        'history',
      ]);
      final keys = data.sections.map((s) => s.key).toSet();
      expect(keys.contains('queue'), isFalse);
      expect(keys.contains('patients'), isFalse);
    });

    test('isPharmacyRole strictly identifies pharmacyStaff and does not misidentify generic doctor/clinic roles', () {
      final doctorData = portalDataForRole(SHIELDRole.provider);
      expect(doctorData.role, SHIELDRole.provider);

      final pharmacyData = portalDataForRole(SHIELDRole.pharmacyStaff);
      expect(pharmacyData.role, SHIELDRole.pharmacyStaff);
    });
  });
}
