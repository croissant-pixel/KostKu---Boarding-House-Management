class Tenant {
  int? id;
  final String name;
  final String phone;
  final String email;
  final int? roomId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? ktpPhoto;
  final String? profilePhoto;
  final String? emergencyContact;
  final double? checkInLat;
  final double? checkInLng;
  final int durationMonth;

  Tenant({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.roomId,
    this.checkInDate,
    this.checkOutDate,
    this.ktpPhoto,
    this.profilePhoto,
    this.emergencyContact,
    this.checkInLat,
    this.checkInLng,
    this.durationMonth = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'room_id': roomId,
      'check_in_date': checkInDate?.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
      'duration_month': durationMonth,
      'ktp_photo': ktpPhoto,
      'profile_photo': profilePhoto,
      'emergency_contact': emergencyContact,
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] as int?,
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      roomId: map['room_id'] as int?,
      checkInDate: map['check_in_date'] != null
          ? DateTime.parse(map['check_in_date'])
          : null,
      checkOutDate: map['check_out_date'] != null
          ? DateTime.parse(map['check_out_date'])
          : null,
      durationMonth: map['duration_month'] ?? 1,
      ktpPhoto: map['ktp_photo'],
      profilePhoto: map['profile_photo'],
      emergencyContact: map['emergency_contact'],
      checkInLat: map['check_in_lat'] != null
          ? map['check_in_lat'] as double
          : null,
      checkInLng: map['check_in_lng'] != null
          ? map['check_in_lng'] as double
          : null, 
    );
  }

  Tenant copyWith({
    DateTime? checkInDate,
    DateTime? checkOutDate,
    double? checkInLat,
    double? checkInLng,
    int? id,
    int? roomId,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name,
      phone: phone,
      email: email,
      roomId: roomId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      durationMonth: durationMonth ?? this.durationMonth,
      ktpPhoto: ktpPhoto,
      profilePhoto: profilePhoto,
      emergencyContact: emergencyContact,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
    );
  }


}
