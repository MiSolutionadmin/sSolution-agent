class LoginModel {
  final String id;
  final String password;
  final bool saveId;
  
  LoginModel({
    required this.id,
    required this.password,
    this.saveId = false,
  });
  
  LoginModel copyWith({
    String? id,
    String? password,
    bool? saveId,
  }) {
    return LoginModel(
      id: id ?? this.id,
      password: password ?? this.password,
      saveId: saveId ?? this.saveId,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
      'saveId': saveId,
    };
  }
  
  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      id: json['id'] ?? '',
      password: json['password'] ?? '',
      saveId: json['saveId'] ?? false,
    );
  }
  
  bool get isValid => id.isNotEmpty && password.isNotEmpty;
  
  @override
  String toString() {
    return 'LoginModel(id: $id, password: [HIDDEN], saveId: $saveId)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is LoginModel &&
      other.id == id &&
      other.password == password &&
      other.saveId == saveId;
  }
  
  @override
  int get hashCode => id.hashCode ^ password.hashCode ^ saveId.hashCode;
}

class LoginResponse {
  final Map<String, dynamic> user;
  final String token;
  final bool success;
  final String? message;
  
  LoginResponse({
    required this.user,
    required this.token,
    this.success = true,
    this.message,
  });
  
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: json['user'] ?? {},
      token: json['token'] ?? '',
      success: json['success'] ?? true,
      message: json['message'],
    );
  }
  
  factory LoginResponse.error(String message) {
    return LoginResponse(
      user: {},
      token: '',
      success: false,
      message: message,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'token': token,
      'success': success,
      'message': message,
    };
  }
  
  @override
  String toString() {
    return 'LoginResponse(success: $success, message: $message, token: ${token.isNotEmpty ? '[TOKEN]' : 'null'})';
  }
}

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final int? first; // 최초 로그인 여부
  final String? phone;
  final String? role;
  
  UserModel({
    this.id,
    this.name,
    this.email,
    this.first,
    this.phone,
    this.role,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      first: json['first'] is int ? json['first'] : int.tryParse(json['first']?.toString() ?? '0'),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'first': first,
      'phone': phone,
      'role': role,
    };
  }
  
  bool get isFirstLogin => first == 1;
  
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, first: $first, role: $role)';
  }
}