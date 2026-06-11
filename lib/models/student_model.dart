class Student {
  final String? id;
  final String name;
  final String nim;
  final String birthDate;
  final String hobby;
  final String phoneNumber;
  final String address;
  final String photoUrl;

  Student({
    this.id,
    required this.name,
    required this.nim,
    required this.birthDate,
    required this.hobby,
    required this.phoneNumber,
    required this.address,
    required this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nim': nim,
      'birthDate': birthDate,
      'hobby': hobby,
      'phoneNumber': phoneNumber,
      'address': address,
      'photoUrl': photoUrl,
    };
  }

  factory Student.fromMap(String id, Map<String, dynamic> map) {
    return Student(
      id: id,
      name: map['name'] ?? '',
      nim: map['nim'] ?? '',
      birthDate: map['birthDate'] ?? '',
      hobby: map['hobby'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }
}