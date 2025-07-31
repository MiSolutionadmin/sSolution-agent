class PhoneVerificationModel {
  final String name;
  final String agency;
  final String group;
  final String phoneNumber;
  final String password;
  final String verificationType;
  
  PhoneVerificationModel({
    required this.name,
    required this.agency,
    required this.group,
    required this.phoneNumber,
    required this.password,
    required this.verificationType,
  });
  
  factory PhoneVerificationModel.fromUserData(Map<String, dynamic> userData, String verificationType) {
    return PhoneVerificationModel(
      name: userData['name']?.toString() ?? '',
      agency: userData['agency']?.toString() ?? userData['address']?.toString() ?? '',
      group: userData['group']?.toString() ?? userData['control_type']?.toString() ?? '0',
      phoneNumber: userData['phoneNumber']?.toString() ?? userData['phone_number']?.toString() ?? '',
      password: userData['pw']?.toString() ?? userData['password']?.toString() ?? '',
      verificationType: verificationType,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'agency': agency,
      'group': group,
      'phoneNumber': phoneNumber,
      'password': password,
      'verificationType': verificationType,
    };
  }
  
  factory PhoneVerificationModel.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationModel(
      name: json['name']?.toString() ?? '',
      agency: json['agency']?.toString() ?? '',
      group: json['group']?.toString() ?? '0',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      verificationType: json['verificationType']?.toString() ?? '',
    );
  }
  
  PhoneVerificationModel copyWith({
    String? name,
    String? agency,
    String? group,
    String? phoneNumber,
    String? password,
    String? verificationType,
  }) {
    return PhoneVerificationModel(
      name: name ?? this.name,
      agency: agency ?? this.agency,
      group: group ?? this.group,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      verificationType: verificationType ?? this.verificationType,
    );
  }
  
  String get formattedPhoneNumber {
    String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanedPhoneNumber.length < 11) {
      return phoneNumber;
    }
    
    return '${cleanedPhoneNumber.substring(0, 3)}-${cleanedPhoneNumber.substring(3, 7)}-${cleanedPhoneNumber.substring(7)}';
  }
  
  String get groupText {
    switch (int.tryParse(group) ?? 0) {
      case 0:
        return '아파트';
      case 1:
        return '빌딩';
      case 2:
        return '학교';
      case 3:
        return '관공서';
      case 4:
        return '기타';
      default:
        return '없음';
    }
  }
  
  bool get isValid {
    return name.isNotEmpty && 
           agency.isNotEmpty && 
           phoneNumber.isNotEmpty && 
           password.isNotEmpty;
  }
  
  @override
  String toString() {
    return 'PhoneVerificationModel(name: $name, agency: $agency, group: $group, phoneNumber: [HIDDEN], verificationType: $verificationType)';
  }
}

class PhoneVerificationResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  
  PhoneVerificationResponse({
    required this.success,
    required this.message,
    this.data,
  });
  
  factory PhoneVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PhoneVerificationResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
  
  factory PhoneVerificationResponse.success(String message, {Map<String, dynamic>? data}) {
    return PhoneVerificationResponse(
      success: true,
      message: message,
      data: data,
    );
  }
  
  factory PhoneVerificationResponse.error(String message) {
    return PhoneVerificationResponse(
      success: false,
      message: message,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
  
  @override
  String toString() {
    return 'PhoneVerificationResponse(success: $success, message: $message)';
  }
}

enum VerificationType {
  first('first'),
  renewal('renewal'),
  change('change');
  
  const VerificationType(this.value);
  final String value;
  
  static VerificationType fromString(String value) {
    return VerificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => VerificationType.first,
    );
  }
}

enum GroupType {
  apartment(0, '아파트'),
  building(1, '빌딩'),
  school(2, '학교'),
  government(3, '관공서'),
  others(4, '기타');
  
  const GroupType(this.value, this.displayName);
  final int value;
  final String displayName;
  
  static GroupType fromValue(int value) {
    return GroupType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => GroupType.apartment,
    );
  }
  
  static GroupType fromString(String value) {
    final intValue = int.tryParse(value) ?? 0;
    return fromValue(intValue);
  }
}