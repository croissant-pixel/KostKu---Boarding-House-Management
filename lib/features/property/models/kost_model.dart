class Kost {
  int? id;
  String name;
  String address;
  String description;

  Kost({
    this.id,
    required this.name,
    required this.address,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
    };
  }

  factory Kost.fromMap(Map<String, dynamic> map) {
    return Kost(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      description: map['description'],
    );
  }
}
