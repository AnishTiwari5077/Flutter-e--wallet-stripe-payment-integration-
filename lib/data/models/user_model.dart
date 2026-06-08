import 'package:flutter/material.dart';
import 'package:app_wallet/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    super.id,
    required super.name,
    required super.email,
    super.phone = '',
    super.avatar = '',
    super.balance = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      int? parseId(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        return null;
      }

      double parseBalance(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      String parseAvatar(dynamic value) {
        if (value == null) return '';
        final avatarStr = value.toString();
        if (avatarStr.isNotEmpty) {
          debugPrint('📸 Avatar received: ${avatarStr.length} chars');
        }
        return avatarStr;
      }

      return UserModel(
        id: parseId(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        avatar: parseAvatar(json['avatar']),
        balance: parseBalance(json['balance']),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ UserModel.fromJson error: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('JSON: $json');

      return const UserModel(
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

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    double? balance,
  }) {
    return UserModel(
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
    return 'UserModel(id: $id, name: $name, email: $email, '
        'phone: $phone, balance: \$${balance.toStringAsFixed(2)}, '
        'avatarSize: ${avatar.length} chars)';
  }
}
