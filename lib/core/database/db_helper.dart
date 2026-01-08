import 'package:kostku/features/auth/models/user_model.dart';
import 'package:kostku/features/payment/models/payment_model.dart';
import 'package:kostku/features/property/models/room_model.dart';
import 'package:kostku/features/property/models/kost_model.dart';
import 'package:kostku/features/tenant/models/tenant_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kostku.db');

    return await openDatabase(
      path,
      version: 5, // upgrade versi untuk payment
      onCreate: (db, version) async {
        // Tabel rooms
        await db.execute('''
          CREATE TABLE rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT,
            type TEXT,
            price INTEGER,
            status TEXT,
            facilities TEXT,
            photoUrl TEXT,
            tenant_id INTEGER
          )
        ''');

        // Tabel kost (profil)
        await db.execute('''
          CREATE TABLE kost (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            address TEXT,
            description TEXT
          )
        ''');

        // Tabel kost_photos
        await db.execute('''
          CREATE TABLE kost_photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kost_id INTEGER,
            photo_url TEXT,
            FOREIGN KEY (kost_id) REFERENCES kost(id)
          )
        ''');

        // Tabel inspections
        await db.execute('''
          CREATE TABLE inspections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER,
            date TEXT,
            condition_notes TEXT,
            photo_url TEXT,
            FOREIGN KEY (room_id) REFERENCES rooms(id)
          )
        ''');

        // Tabel room_photos
        await db.execute('''
          CREATE TABLE room_photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER,
            photo_url TEXT,
            FOREIGN KEY (room_id) REFERENCES rooms(id)
          )
        ''');

        // Tabel tenants
        await db.execute('''
          CREATE TABLE tenants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            email TEXT,
            room_id INTEGER,
            check_in_date TEXT,
            check_out_date TEXT,
            duration_month INTEGER DEFAULT 1,
            ktp_photo TEXT,
            profile_photo TEXT,
            emergency_contact TEXT,
            check_in_lat REAL,
            check_in_lng REAL,
            check_out_lat REAL,
            check_out_lng REAL,
            FOREIGN KEY (room_id) REFERENCES rooms(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT  -- "owner" atau "tenant" nanti
          )
        ''');

        await db.execute('''
          CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tenant_id INTEGER NOT NULL,
            month TEXT NOT NULL,
            amount INTEGER NOT NULL,
            paid_date TEXT,
            status TEXT NOT NULL,
            receipt_photo TEXT,
            notes TEXT,
            FOREIGN KEY (tenant_id) REFERENCES tenants(id)
          )
        ''');

                // Tabel monthly_stats untuk analytics
                await db.execute('''
          CREATE TABLE monthly_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            month TEXT NOT NULL UNIQUE,
            occupancy_rate REAL,
            total_revenue INTEGER,
            payment_collection_rate REAL
          )
        ''');
      },
    );
  }

  // ==================== Room ====================
  Future<int> updateRoom(Room room) async {
    final db = await DBHelper.database;
    return await db.update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  Future<void> deleteRoom(int id) async {
    final db = await database;
    await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Room Photos ====================
  Future<int> addRoomPhoto(int roomId, String photoUrl) async {
    final db = await database;
    return await db.insert('room_photos', {
      'room_id': roomId,
      'photo_url': photoUrl,
    });
  }

  Future<List<String>> getRoomPhotos(int roomId) async {
    final db = await database;
    final maps = await db.query(
      'room_photos',
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
    return maps.map((e) => e['photo_url'] as String).toList();
  }

  Future<void> deleteRoomPhoto(int roomId, String photoUrl) async {
    final db = await database;
    await db.delete(
      'room_photos',
      where: 'room_id = ? AND photo_url = ?',
      whereArgs: [roomId, photoUrl],
    );
  }

  // ==================== Kost ====================
  Future<int> insertKost(Kost kost) async {
    final db = await database;
    return await db.insert(
      'kost',
      kost.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Kost?> getKost() async {
    final db = await database;
    final maps = await db.query('kost', limit: 1);
    if (maps.isNotEmpty) return Kost.fromMap(maps.first);
    return null;
  }

  Future<int> updateKost(Kost kost) async {
    final db = await database;
    return await db.update(
      'kost',
      kost.toMap(),
      where: 'id = ?',
      whereArgs: [kost.id],
    );
  }

  // ==================== Kost Photos ====================
  Future<int> addKostPhoto(int kostId, String photoUrl) async {
    final db = await database;
    return await db.insert('kost_photos', {
      'kost_id': kostId,
      'photo_url': photoUrl,
    });
  }

  Future<List<String>> getKostPhotos(int kostId) async {
    final db = await database;
    final maps = await db.query(
      'kost_photos',
      where: 'kost_id = ?',
      whereArgs: [kostId],
    );
    return maps.map((e) => e['photo_url'] as String).toList();
  }

  Future<void> deleteKostPhoto(int id) async {
    final db = await database;
    await db.delete('kost_photos', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Inspections ====================
  Future<List<Map<String, dynamic>>> getInspectionsByRoom(int roomId) async {
    final db = await database;
    return await db.query(
      'inspections',
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
  }

  Future<int> addInspection(
    int roomId,
    String conditionNotes,
    String photoUrl,
  ) async {
    final db = await database;
    return await db.insert('inspections', {
      'room_id': roomId,
      'date': DateTime.now().toIso8601String(),
      'condition_notes': conditionNotes,
      'photo_url': photoUrl,
    });
  }

  Future<void> deleteInspection(int id) async {
    final db = await database;
    await db.delete('inspections', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Tenants ====================
  Future<int> addTenant(Tenant tenant) async {
    final db = await database;

    final id = await db.insert('tenants', {
      'name': tenant.name,
      'phone': tenant.phone,
      'email': tenant.email,
      'room_id': tenant.roomId, // ✅ Simpan room_id
      'check_in_date': tenant.checkInDate?.toIso8601String(),
      'check_out_date': tenant.checkOutDate?.toIso8601String(),
      'duration_month': tenant.durationMonth,
      'ktp_photo': tenant.ktpPhoto,
      'profile_photo': tenant.profilePhoto,
      'emergency_contact': tenant.emergencyContact,
      'check_in_lat': tenant.checkInLat,
      'check_in_lng': tenant.checkInLng,
    });
    return id;
  }

  Future<List<Tenant>> getTenants() async {
    final db = await database;
    final maps = await db.query('tenants');
    return maps.map((e) => Tenant.fromMap(e)).toList();
  }

  Future<int> updateTenant(Tenant tenant) async {
    final db = await database;
    return await db.update(
      'tenants',
      tenant.toMap(),
      where: 'id = ?',
      whereArgs: [tenant.id],
    );
  }

  Future<void> deleteTenant(int id) async {
    final db = await database;
    await db.delete('tenants', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Users ====================
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<void> updateRoomStatus(int roomId, String status) async {
    final db = await database;
    await db.update(
      'rooms',
      {'status': status},
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  Future<void> assignTenantToRoom({
    required int roomId,
    required int tenantId,
  }) async {
    final db = await database;
    await db.update(
      'rooms',
      {'status': RoomStatus.occupied.name, 'tenant_id': tenantId},
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  Future<void> clearRoomTenant(int roomId) async {
    final db = await database;
    await db.update(
      'rooms',
      {'status': RoomStatus.available.name, 'tenant_id': null},
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  Future<void> checkInTenant({
    required int tenantId,
    required int roomId,
    required DateTime checkInDate,
    required int durationMonth,
    required double lat,
    required double lng,
  }) async {
    final db = await database;

    // Hitung check-out date
    final checkOutDate = DateTime(
      checkInDate.year,
      checkInDate.month + durationMonth,
      checkInDate.day,
    );


    // Update tenant data
    await db.update(
      'tenants',
      {
        'room_id': roomId,
        'check_in_date': checkInDate.toIso8601String(),
        'check_out_date': checkOutDate.toIso8601String(),
        'duration_month': durationMonth,
        'check_in_lat': lat,
        'check_in_lng': lng,
      },
      where: 'id = ?',
      whereArgs: [tenantId],
    );


    // Update room status ke occupied
    await db.update(
      'rooms',
      {
        'status': 'occupied', // ✅ Set status occupied
        'tenant_id': tenantId,
      },
      where: 'id = ?',
      whereArgs: [roomId],
    );


    // Verify
    final room = await db.query('rooms', where: 'id = ?', whereArgs: [roomId]);
  }

  Future<Tenant?> getActiveTenantByRoom(int roomId) async {
    final db = await database;


    // Cari tenant yang room_id-nya sesuai (tenant yang checkout akan punya room_id = null)
    final List<Map<String, dynamic>> maps = await db.query(
      'tenants',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'check_in_date DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    final tenant = Tenant.fromMap(maps.first);

    return tenant;
  }

  Future<void> checkOutTenant({
    required int tenantId,
    required int roomId,
    double? lat, // ✅ GPS checkout
    double? lng, // ✅ GPS checkout
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      // Update tenant - set room_id = null
      await txn.update(
        'tenants',
        {
          'check_out_date': DateTime.now().toIso8601String(),
          'room_id': null, // ✅ PENTING: Set null
          'check_out_lat': lat, // ✅ Simpan lokasi checkout
          'check_out_lng': lng, // ✅ Simpan lokasi checkout
        },
        where: 'id = ?',
        whereArgs: [tenantId],
      );

      // Update room status jadi available
      await txn.update(
        'rooms',
        {'status': RoomStatus.available.name, 'tenant_id': null},
        where: 'id = ?',
        whereArgs: [roomId],
      );
    });

  }

  Future<List<Room>> getRooms() async {
    final db = await database;
    final maps = await db.query('rooms'); // ambil semua row

    // convert dari Map ke Room
    return maps.map((e) => Room.fromMap(e)).toList();
  }

  // ==================== Payments ====================
  Future<int> getMonthlyRevenue(DateTime month) async {
    final db = await database;

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final result = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(amount), 0) as total
    FROM payments
    WHERE status = 'paid'
    AND paid_date >= ? AND paid_date <= ?
  ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    return result.first['total'] as int;
  }

  Future<double> getPaymentCollectionRate(DateTime month) async {
    final db = await database;

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final result = await db.rawQuery(
      '''
    SELECT 
      COUNT(*) as total,
      SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as paid_count
    FROM payments
    WHERE month >= ? AND month <= ?
  ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    final total = result.first['total'] as int;
    final paidCount = result.first['paid_count'] as int;

    if (total == 0) return 0.0;
    return (paidCount / total) * 100;
  }
  
  Future<double> getOccupancyRate() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT 
      COUNT(*) as total_rooms,
      SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END) as occupied_rooms
    FROM rooms
  ''');

    final total = result.first['total_rooms'] as int;
    final occupied = result.first['occupied_rooms'] as int;

    if (total == 0) return 0.0;
    return (occupied / total) * 100;
  }

  Future<int> getOutstandingPaymentsCount() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM payments
    WHERE status IN ('pending', 'overdue')
  ''');

    return result.first['count'] as int;
  }

  // Get monthly revenue chart data (last 6 months)
  Future<List<Map<String, dynamic>>> getRevenueChartData() async {
    final db = await database;
    final now = DateTime.now();

    List<Map<String, dynamic>> data = [];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final endOfMonth = DateTime(now.year, now.month - i + 1, 0);

      final result = await db.rawQuery(
        '''
      SELECT COALESCE(SUM(amount), 0) as revenue
      FROM payments
      WHERE status = 'paid'
      AND paid_date >= ? AND paid_date <= ?
    ''',
        [month.toIso8601String(), endOfMonth.toIso8601String()],
      );

      data.add({'month': month, 'revenue': result.first['revenue'] as int});
    }

    return data;
  }

  // ==================== PAYMENT METHODS ====================

  Future<int> addPayment(Payment payment) async {
    final db = await database;

    final id = await db.insert('payments', payment.toMap());
    return id;
  }

  Future<List<Payment>> getPayments() async {
    final db = await database;

    final maps = await db.rawQuery('''
      SELECT 
        p.*,
        t.name as tenant_name,
        r.number as room_number
      FROM payments p
      LEFT JOIN tenants t ON p.tenant_id = t.id
      LEFT JOIN rooms r ON t.room_id = r.id
      ORDER BY p.month DESC, p.status ASC
    ''');

    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getPaymentsByTenant(int tenantId) async {
    final db = await database;

    final maps = await db.rawQuery(
      '''
      SELECT 
        p.*,
        t.name as tenant_name,
        r.number as room_number
      FROM payments p
      LEFT JOIN tenants t ON p.tenant_id = t.id
      LEFT JOIN rooms r ON t.room_id = r.id
      WHERE p.tenant_id = ?
      ORDER BY p.month DESC
    ''',
      [tenantId],
    );

    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getPaymentsByMonth(DateTime month) async {
    final db = await database;

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final maps = await db.rawQuery(
      '''
      SELECT 
        p.*,
        t.name as tenant_name,
        r.number as room_number
      FROM payments p
      LEFT JOIN tenants t ON p.tenant_id = t.id
      LEFT JOIN rooms r ON t.room_id = r.id
      WHERE p.month >= ? AND p.month <= ?
      ORDER BY p.status ASC, t.name ASC
    ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;

    final count = await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );

    return count;
  }

  Future<void> deletePayment(int id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markPaymentAsPaid({
    required int paymentId,
    required DateTime paidDate,
    String? receiptPhoto,
  }) async {
    final db = await database;

    await db.update(
      'payments',
      {
        'status': 'paid',
        'paid_date': paidDate.toIso8601String(),
        'receipt_photo': receiptPhoto,
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  Future<void> updateOverduePayments() async {
    final db = await database;

    final now = DateTime.now();

    await db.rawUpdate(
      '''
      UPDATE payments
      SET status = 'overdue'
      WHERE status = 'pending'
      AND date(month) < date(?)
    ''',
      [now.toIso8601String()],
    );
  }

  Future<void> generateMonthlyPayments(DateTime month) async {
    final db = await database;


    final tenants = await db.rawQuery('''
      SELECT t.*, r.price
      FROM tenants t
      JOIN rooms r ON t.room_id = r.id
      WHERE t.room_id IS NOT NULL
    ''');

    final startOfMonth = DateTime(month.year, month.month, 1);

    for (var tenant in tenants) {
      final existing = await db.query(
        'payments',
        where: 'tenant_id = ? AND month = ?',
        whereArgs: [tenant['id'], startOfMonth.toIso8601String()],
      );

      if (existing.isEmpty) {
        await db.insert('payments', {
          'tenant_id': tenant['id'],
          'month': startOfMonth.toIso8601String(),
          'amount': tenant['price'],
          'status': 'pending',
        });
      }
    }
  }
}
