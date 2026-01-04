import 'package:flutter/material.dart';
import 'package:kostku/core/database/db_helper.dart';
import '../models/tenant_model.dart';

class TenantProvider with ChangeNotifier {
  List<Tenant> _tenants = [];

  List<Tenant> get tenants => _tenants;
  Tenant? getTenantByRoom(int roomId) {
    try {
      return _tenants.firstWhere(
        (t) => t.roomId == roomId && t.checkOutDate == null,
      );
    } catch (e) {
      return null;
    }
  }
  bool get isLoading => _isLoading;
  bool _isLoading = false;
  final DBHelper _dbHelper = DBHelper();

  /// Tenant aktif di room detail
  Tenant? _activeTenant;
  Tenant? get activeTenant => _activeTenant;

  // ==================== FETCH TENANTS ====================
  Future<void> fetchTenants() async {
    _isLoading = true;
    notifyListeners();

    _tenants = await _dbHelper.getTenants() ?? [];

    _isLoading = false;
    notifyListeners();
  }

  // ==================== ADD TENANT ====================
  Future<int> addTenant(Tenant tenant) async {
    final id = await _dbHelper.addTenant(tenant);
    await fetchTenants();
    return id;
  }

  // ==================== UPDATE TENANT ====================
  Future<void> updateTenant(Tenant tenant) async {
    await _dbHelper.updateTenant(tenant);
    await fetchTenants();
  }

  // ==================== DELETE TENANT ====================
  Future<void> deleteTenant(int tenantId) async {
    await _dbHelper.deleteTenant(tenantId);
    await fetchTenants();
  }

  // ==================== CHECK-IN TENANT ====================
  Future<void> checkInTenant({
    required int tenantId,
    required int roomId,
    required DateTime checkInDate,
    required int durationMonth,
    required double lat,
    required double lng,
  }) async {
    await _dbHelper.checkInTenant(
      tenantId: tenantId,
      roomId: roomId,
      checkInDate: checkInDate,
      durationMonth: durationMonth,
      lat: lat,
      lng: lng,
    );
    await fetchTenants();
  }

  // ==================== CHECK-OUT TENANT ====================
  Future<void> checkOutTenant({
    required int tenantId,
    required int roomId,
  }) async {
    // Gunakan method dari db_helper
    await _dbHelper.checkOutTenant(tenantId: tenantId, roomId: roomId);

    await fetchTenants();
  }

  // ==================== FETCH ACTIVE TENANT BY ROOM ====================
  Future<void> fetchActiveTenant(int roomId) async {
    _activeTenant = await _dbHelper.getActiveTenantByRoom(roomId);
    notifyListeners();
  }
}
