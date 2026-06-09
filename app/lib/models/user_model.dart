class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePhoto;
  final String? bloodGroup;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePhoto,
    this.bloodGroup,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      profilePhoto: (json['profilePhoto'] ?? json['profilePhotoUrl'])?.toString(),
      bloodGroup: json['bloodGroup'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'bloodGroup': bloodGroup,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    String? bloodGroup,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }
}
