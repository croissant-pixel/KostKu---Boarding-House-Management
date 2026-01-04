import 'package:kostku/features/auth/models/user_model.dart';
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
      version: 4, // upgrade versi untuk tambah kost + photo gallery
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
    return await db.insert('tenants', tenant.toMap());
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

    await db.transaction((txn) async {
      // Update tenant
      await txn.update(
        'tenants',
        {
          'room_id': roomId,
          'check_in_date': checkInDate.toIso8601String(),
          'duration_month': durationMonth,
          'check_in_lat': lat,
          'check_in_lng': lng,
        },
        where: 'id = ?',
        whereArgs: [tenantId],
      );

      // Update room status AND tenant_id
      await txn.update(
        'rooms',
        {'status': RoomStatus.occupied.name, 'tenant_id': tenantId},
        where: 'id = ?',
        whereArgs: [roomId],
      );
    });
  }

  Future<Tenant?> getActiveTenantByRoom(int roomId) async {
    final db = await database;

    final maps = await db.query(
      'tenants',
      where: 'room_id = ? AND check_out_date IS NULL',
      whereArgs: [roomId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Tenant.fromMap(maps.first);
    }
    return null;
  }

  Future<void> checkOutTenant({
    required int tenantId,
    required int roomId,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      // Update tenant
      await txn.update(
        'tenants',
        {'check_out_date': DateTime.now().toIso8601String(), 'room_id': null},
        where: 'id = ?',
        whereArgs: [tenantId],
      );

      // Update room status jadi available
      await txn.update(
        'rooms',
        {'status': RoomStatus.available.name},
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
}
