class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String avatar; // URL (can be empty)
  final double balance; // dollars

  User({
    this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.balance = 0.0,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] is int
        ? json['id']
        : (json['id'] != null ? int.parse(json['id'].toString()) : null),
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    avatar: json['avatar'] ?? json['profile_url'] ?? '',
    balance: (json['balance'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'balance': balance,
  };
}
