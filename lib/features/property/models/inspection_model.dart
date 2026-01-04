class Inspection {
  final int? id;
  final int roomId;
  final DateTime date;
  final String conditionNotes;
  final String photoUrl;

  Inspection({
    this.id,
    required this.roomId,
    required this.date,
    required this.conditionNotes,
    required this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'date': date.toIso8601String(),
      'condition_notes': conditionNotes,
      'photo_url': photoUrl,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] as int?,
      roomId: map['room_id'],
      date: DateTime.parse(map['date']),
      conditionNotes: map['condition_notes'],
      photoUrl: map['photo_url'],
    );
  }
}
