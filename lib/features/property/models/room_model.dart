enum RoomStatus {
  available,
  occupied
}

class Room {
  final int? id;
  final String number;
  final String type;
  final int price;
  RoomStatus status;
  final String facilities;
  final String photoUrl;
  List<String>? photos;
  int? tenantId;
  String? tenantName;

  Room({
    this.id,
    required this.number,
    required this.type,
    required this.price,
    required this.status,
    required this.facilities,
    required this.photoUrl,
    this.photos,
    this.tenantId,
    this.tenantName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'type': type,
      'price': price,
      'status': status.name,
      'facilities': facilities,
      'photoUrl': photoUrl,
      'tenant_id': tenantId,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      number: map['number'],
      type: map['type'],
      price: map['price'],
      status: RoomStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      tenantId: map['tenant_id'],
      facilities: map['facilities'],
      photoUrl: map['photoUrl'],
      photos: [],
    );
  }
  
  Room copyWith({RoomStatus? status, int? tenantId}) {
    return Room(
      id: id,
      number: number,
      type: type,
      price: price,
      status: status ?? this.status,
      facilities: facilities,
      photoUrl: photoUrl,
      photos: photos,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  bool get isAvailable => status == RoomStatus.available;
  bool get isOccupied => status == RoomStatus.occupied;

}
