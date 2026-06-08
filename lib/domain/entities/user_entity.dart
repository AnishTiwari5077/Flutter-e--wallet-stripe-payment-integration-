class UserEntity {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final double balance;

  const UserEntity({
    this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.balance = 0.0,
  });

  bool get isValid => id != null && name.isNotEmpty && email.isNotEmpty;
  bool get hasAvatar => avatar.isNotEmpty;
  bool get hasPhone => phone.isNotEmpty;
}
