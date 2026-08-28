import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String name,
    required String email,
    required String role,
    String? token,
  }) : super(id: id, name: name, email: email, role: role, token: token);

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    final u = json['user'] ?? json;
    return UserModel(
      id: '${u['id'] ?? u['user_id'] ?? ''}',
      name: '${u['name'] ?? u['first_name'] ?? 'Usuario'}',
      email: '${u['email'] ?? ''}',
      role: '${u['role'] ?? 'collector'}',
      token: token ?? json['token'] ?? json['access_token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'token': token,
      };
}
