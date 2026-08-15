import 'dart:convert';

/// Model representing the authenticated user in SensorEPI Remoto.
class AuthUser {
  final int id;
  final int clientId;
  final String name;
  final String username;
  final String? email;
  final String? phone;
  final String role;
  final int active;
  final List<String> allowedTabs;
  final List<String> visibleGroups;
  final String? created;

  AuthUser({
    required this.id,
    required this.clientId,
    required this.name,
    required this.username,
    this.email,
    this.phone,
    required this.role,
    required this.active,
    required this.allowedTabs,
    required this.visibleGroups,
    this.created,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    return AuthUser(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'cliente',
      active: json['active'] as int? ?? 1,
      allowedTabs: parseStringList(json['allowed_tabs']),
      visibleGroups: parseStringList(json['visible_groups']),
      created: json['created'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'active': active,
      'allowed_tabs': allowedTabs,
      'visible_groups': visibleGroups,
      'created': created,
    };
  }
}

/// Model representing the response from POST /api/auth/login.
class LoginResponse {
  final String token;
  final String clientName;
  final List<String> allowedTabs;
  final AuthUser user;

  LoginResponse({
    required this.token,
    required this.clientName,
    required this.allowedTabs,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    List<String> parseTabs(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    return LoginResponse(
      token: json['token'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      allowedTabs: parseTabs(json['allowed_tabs']),
      user: json['user'] != null
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : AuthUser(
              id: 0,
              clientId: 0,
              name: '',
              username: '',
              role: 'cliente',
              active: 1,
              allowedTabs: [],
              visibleGroups: [],
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'client_name': clientName,
      'allowed_tabs': allowedTabs,
      'user': user.toJson(),
    };
  }
}
