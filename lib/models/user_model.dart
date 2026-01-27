import 'package:flutter/material.dart';

class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final double balance;

  User({
    this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.balance = 0.0,
  });

  // ✅ IMPROVED: Better parsing with detailed logging
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      // Parse ID safely
      int? parseId(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        return null;
      }

      // Parse balance safely
      double parseBalance(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      // Parse avatar - ONLY use 'avatar' key
      String parseAvatar(dynamic value) {
        if (value == null) return '';
        final avatarStr = value.toString();
        if (avatarStr.isNotEmpty) {
          debugPrint('📸 Avatar received: ${avatarStr.length} chars');
        }
        return avatarStr;
      }

      return User(
        id: parseId(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        avatar: parseAvatar(json['avatar']), // ✅ Only 'avatar'
        balance: parseBalance(json['balance']),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ User.fromJson error: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('JSON: $json');

      // Return safe default
      return User(
        id: null,
        name: 'Unknown',
        email: '',
        phone: '',
        avatar: '',
        balance: 0.0,
      );
    }
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

  // ✅ IMPROVED: Better toString
  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, '
        'phone: $phone, balance: \$${balance.toStringAsFixed(2)}, '
        'avatarSize: ${avatar.length} chars)';
  }

  // ✅ NEW: Validation methods
  bool get isValid => id != null && name.isNotEmpty && email.isNotEmpty;
  bool get hasAvatar => avatar.isNotEmpty;
  bool get hasPhone => phone.isNotEmpty;
}
