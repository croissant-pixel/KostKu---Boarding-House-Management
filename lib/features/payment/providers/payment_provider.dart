import 'package:flutter/material.dart';
import 'package:kostku/core/database/db_helper.dart';
import '../models/payment_model.dart';

class PaymentProvider with ChangeNotifier {
  List<Payment> _payments = [];
  bool _isLoading = false;

  // Analytics data
  int _monthlyRevenue = 0;
  double _paymentCollectionRate = 0.0;
  double _occupancyRate = 0.0;
  int _outstandingPaymentsCount = 0;
  List<Map<String, dynamic>> _revenueChartData = [];

  // Getters
  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  int get monthlyRevenue => _monthlyRevenue;
  double get paymentCollectionRate => _paymentCollectionRate;
  double get occupancyRate => _occupancyRate;
  int get outstandingPaymentsCount => _outstandingPaymentsCount;
  List<Map<String, dynamic>> get revenueChartData => _revenueChartData;

  final DBHelper _dbHelper = DBHelper();

  // Filtered lists
  List<Payment> get pendingPayments =>
      _payments.where((p) => p.status == PaymentStatus.pending).toList();

  List<Payment> get paidPayments =>
      _payments.where((p) => p.status == PaymentStatus.paid).toList();

  List<Payment> get overduePayments =>
      _payments.where((p) => p.status == PaymentStatus.overdue).toList();

  // ==================== FETCH PAYMENTS ====================
  Future<void> fetchPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Update status overdue dulu
      await _dbHelper.updateOverduePayments();

      // Ambil semua payments
      _payments = await _dbHelper.getPayments();

      print('📊 Fetched ${_payments.length} payments');
      print('   Pending: ${pendingPayments.length}');
      print('   Paid: ${paidPayments.length}');
      print('   Overdue: ${overduePayments.length}');
    } catch (e) {
      print('❌ Error fetching payments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== FETCH ANALYTICS ====================
  Future<void> fetchAnalytics() async {
    try {
      final now = DateTime.now();

      _monthlyRevenue = await _dbHelper.getMonthlyRevenue(now);
      _paymentCollectionRate = await _dbHelper.getPaymentCollectionRate(now);
      _occupancyRate = await _dbHelper.getOccupancyRate();
      _outstandingPaymentsCount = await _dbHelper.getOutstandingPaymentsCount();
      _revenueChartData = await _dbHelper.getRevenueChartData();

      print('📊 Analytics updated:');
      print('   Monthly Revenue: Rp $_monthlyRevenue');
      print(
        '   Collection Rate: ${_paymentCollectionRate.toStringAsFixed(1)}%',
      );
      print('   Occupancy Rate: ${_occupancyRate.toStringAsFixed(1)}%');
      print('   Outstanding: $_outstandingPaymentsCount');

      notifyListeners();
    } catch (e) {
      print('❌ Error fetching analytics: $e');
    }
  }

  // ==================== ADD PAYMENT ====================
  Future<int> addPayment(Payment payment) async {
    try {
      final id = await _dbHelper.addPayment(payment);
      await fetchPayments();
      await fetchAnalytics();
      return id;
    } catch (e) {
      print('❌ Error adding payment: $e');
      rethrow;
    }
  }

  // ==================== UPDATE PAYMENT ====================
  Future<void> updatePayment(Payment payment) async {
    try {
      await _dbHelper.updatePayment(payment);
      await fetchPayments();
      await fetchAnalytics();
    } catch (e) {
      print('❌ Error updating payment: $e');
      rethrow;
    }
  }

  // ==================== DELETE PAYMENT ====================
  Future<void> deletePayment(int id) async {
    try {
      await _dbHelper.deletePayment(id);
      await fetchPayments();
      await fetchAnalytics();
    } catch (e) {
      print('❌ Error deleting payment: $e');
      rethrow;
    }
  }

  // ==================== MARK AS PAID ====================
  Future<void> markAsPaid({
    required int paymentId,
    required DateTime paidDate,
    String? receiptPhoto,
  }) async {
    try {
      await _dbHelper.markPaymentAsPaid(
        paymentId: paymentId,
        paidDate: paidDate,
        receiptPhoto: receiptPhoto,
      );
      await fetchPayments();
      await fetchAnalytics();
    } catch (e) {
      print('❌ Error marking payment as paid: $e');
      rethrow;
    }
  }

  // ==================== GENERATE MONTHLY PAYMENTS ====================
  Future<void> generateMonthlyPayments(DateTime month) async {
    try {
      print('💰 Generating monthly payments for ${month.year}-${month.month}');
      await _dbHelper.generateMonthlyPayments(month);
      await fetchPayments();
      await fetchAnalytics();
      print('✅ Monthly payments generated successfully');
    } catch (e) {
      print('❌ Error generating monthly payments: $e');
      rethrow;
    }
  }

  // ==================== GET PAYMENTS BY TENANT ====================
  Future<List<Payment>> getPaymentsByTenant(int tenantId) async {
    try {
      return await _dbHelper.getPaymentsByTenant(tenantId);
    } catch (e) {
      print('❌ Error fetching payments by tenant: $e');
      return [];
    }
  }

  // ==================== GET PAYMENTS BY MONTH ====================
  Future<List<Payment>> getPaymentsByMonth(DateTime month) async {
    try {
      return await _dbHelper.getPaymentsByMonth(month);
    } catch (e) {
      print('❌ Error fetching payments by month: $e');
      return [];
    }
  }

  // ==================== HELPER: FORMAT CURRENCY ====================
  String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
