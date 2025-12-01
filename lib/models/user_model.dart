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

  factory User.fromJson(Map<String, dynamic> json) {
    // -------- SAFE BALANCE PARSER --------
    double parseBalance(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble(); // int OR double
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return User(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),

      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',

      // FIX: Safe fallback chain for avatar
      avatar:
          (json['avatar'] ?? json['photo'] ?? json['profile_url'] ?? '')
              ?.toString() ??
          '',

      balance: parseBalance(json['balance']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'balance': balance,
  };

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    double? balance,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, phone: $phone, balance: \$${balance.toStringAsFixed(2)})';
  }
}
