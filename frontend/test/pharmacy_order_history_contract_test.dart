import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_history_model.dart';

void main() {
  group('PharmacyOrderHistoryResponse Deserialization Contract', () {
    test('deserializes canonical backend payload with items and metrics', () {
      final json = {
        'items': [
          {
            'id': '10',
            'orderNumber': 'INV-UAT-006',
            'status': 'COMPLETED',
            'paymentStatus': 'PAID',
            'orderSource': 'PRESCRIPTION',
            'fulfillmentPreference': 'COLLECT_FROM_PHARMACY',
            'totalAmount': 650.0,
            'payableAmount': 650.0,
            'submittedAt': '2026-08-19T04:05:38.800Z',
            'statusUpdatedAt': '2026-08-19T04:05:38.800Z',
            'customer': {
              'id': '28',
              'customerCode': 'UAT-CUST-001',
              'fullName': 'Anoop Sharma',
              'mobile': '9876543210'
            },
            'items': [
              {
                'id': '101',
                'name': 'Amoxicillin 500mg',
                'quantity': 2,
                'unitPrice': 325.0,
                'lineTotal': 650.0
              }
            ]
          }
        ],
        'pagination': {
          'page': 1,
          'pageSize': 20,
          'total': 7,
          'totalPages': 1
        },
        'metrics': {
          'completedCount': 5,
          'completedValue': 650.0,
          'cancelledCount': 1,
          'rejectedCount': 1
        }
      };

      final response = PharmacyOrderHistoryResponse.fromJson(json);

      expect(response.orders.length, equals(1));
      expect(response.orders.first.orderNumber, equals('INV-UAT-006'));
      expect(response.pagination.total, equals(7));
      expect(response.pagination.page, equals(1));
      expect(response.summary.totalCompletedCount, equals(5));
      expect(response.summary.completedOrderValue, equals(650.0));
      expect(response.summary.totalCancelledCount, equals(1));
      expect(response.summary.totalRejectedCount, equals(1));
    });

    test('deserializes legacy alias payload with orders and summary', () {
      final json = {
        'orders': [
          {
            'id': '11',
            'orderNumber': 'INV-UAT-011',
            'status': 'CANCELLED',
            'totalAmount': 400.0,
            'payableAmount': 400.0,
            'submittedAt': '2026-08-19T04:05:38.800Z',
            'statusUpdatedAt': '2026-08-19T04:05:38.800Z',
            'customer': {
              'id': '28',
              'fullName': 'Anoop Sharma',
              'mobile': '9876543210'
            },
            'items': []
          }
        ],
        'pagination': {
          'page': 1,
          'pageSize': 20,
          'total': 1,
          'totalPages': 1
        },
        'summary': {
          'totalCompletedCount': 0,
          'completedOrderValue': 0.0,
          'totalCancelledCount': 1,
          'totalRejectedCount': 0
        }
      };

      final response = PharmacyOrderHistoryResponse.fromJson(json);

      expect(response.orders.length, equals(1));
      expect(response.orders.first.orderNumber, equals('INV-UAT-011'));
      expect(response.pagination.total, equals(1));
      expect(response.summary.totalCancelledCount, equals(1));
    });
  });
}
