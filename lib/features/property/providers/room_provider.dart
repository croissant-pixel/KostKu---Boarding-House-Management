import 'package:flutter/material.dart';
import 'package:kostku/features/tenant/models/tenant_model.dart';
import '../../../core/database/db_helper.dart';
import '../models/room_model.dart';

class RoomProvider with ChangeNotifier {
  List<Room> _rooms = [];
  bool _isLoading = false;
  
  // Map roomId -> list of photo URLs
  Map<int, List<String>> _roomPhotos = {};

  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  Map<int, List<String>> get roomPhotos => _roomPhotos;

  List<Room> get availableRooms =>
      _rooms.where((r) => r.status == RoomStatus.available).toList();


  final DBHelper _dbHelper = DBHelper();

  // ================== Rooms ==================
  Future<void> fetchRooms() async {
    _isLoading = true;
    notifyListeners();

    final roomsFromDb = await _dbHelper.getRooms();

    for (var room in roomsFromDb) {
      // load gallery photos
      final photos = await _dbHelper.getRoomPhotos(room.id!);
      room.photos = photos;
      _roomPhotos[room.id!] = photos;

      // ambil tenant aktif (HANYA untuk nama)
      final tenant = await _dbHelper.getActiveTenantByRoom(room.id!);
      room.tenantName = tenant?.name;
      // ❌ JANGAN UBAH room.status DI SINI
    }

    _rooms = roomsFromDb;

    _isLoading = false;
    notifyListeners();
  }


  Future<void> addRoom(Room room) async {
    final db = await DBHelper.database;
    await db.insert('rooms', room.toMap());
    await fetchRooms();
  }

  Future<void> updateRoom(Room room, {int? tenantId}) async {
    await _dbHelper.updateRoom(room);
    await fetchRooms();
  }

  Future<void> deleteRoom(int id) async {
    await _dbHelper.deleteRoom(id);
    _roomPhotos.remove(id);
    await fetchRooms();
  }

  // ================== Room Photos ==================
  Future<void> addRoomPhoto(int roomId, String photoUrl) async {
    await _dbHelper.addRoomPhoto(roomId, photoUrl);
    _roomPhotos[roomId] = await _dbHelper.getRoomPhotos(roomId);
    notifyListeners();
  }

  Future<void> removeRoomPhoto(int roomId, String photoUrl) async {
    await _dbHelper.deleteRoomPhoto(roomId, photoUrl);
    _roomPhotos[roomId] = await _dbHelper.getRoomPhotos(roomId);
    notifyListeners();
  }

  Future<void> assignTenant({
    required int roomId,
    required int tenantId,
  }) async {
    await _dbHelper.assignTenantToRoom(roomId: roomId, tenantId: tenantId);
    await fetchRooms();
  }

  Future<void> checkoutRoom(int roomId) async {
    await _dbHelper.clearRoomTenant(roomId);
    await fetchRooms();
  }

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
    await fetchRooms();
  }
}
