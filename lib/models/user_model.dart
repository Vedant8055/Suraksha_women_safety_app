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
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profilePhoto: json['profilePhoto'],
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
}
