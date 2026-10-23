class AuthUser {

  final int id;
  final String name;
  final String? email;
  final String phone;
  final String role;

  const AuthUser({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.role,
  });

  bool get isFarmer => role == 'farmer';
  bool get isOwner => role == 'owner' || role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'farmer',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
  };
}

class EmergencyContact {
  final String? name;
  final String? phone;
  final String? relationship;

  const EmergencyContact({this.name, this.phone, this.relationship});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      relationship: json['relationship']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'relationship': relationship,
  };
}

class FarmerProfile {
  final int id;
  final String farmerCode;
  final String fullName;
  final String phone;
  final String? nid;
  final String? gender;
  final String? address;
  final String? primaryActivity;
  final int experienceYears;
  final String? profilePhotoUrl;
  final bool appAccessEnabled;
  final String status;
  final EmergencyContact? emergencyContact;
  final List<dynamic> locations;

  const FarmerProfile({
    required this.id,
    required this.farmerCode,
    required this.fullName,
    required this.phone,
    this.nid,
    this.gender,
    this.address,
    this.primaryActivity,
    this.experienceYears = 0,
    this.profilePhotoUrl,
    this.appAccessEnabled = true,
    this.status = 'active',
    this.emergencyContact,
    this.locations = const [],
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      farmerCode: json['farmer_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      nid: json['nid']?.toString(),
      gender: json['gender']?.toString(),
      address: json['address']?.toString(),
      primaryActivity: json['primary_activity']?.toString(),
      experienceYears: json['experience_years'] is int
          ? json['experience_years']
          : int.tryParse(json['experience_years']?.toString() ?? '0') ?? 0,
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      appAccessEnabled: json['app_access_enabled'] == true,
      status: json['status']?.toString() ?? 'active',
      emergencyContact: json['emergency_contact'] is Map<String, dynamic>
          ? EmergencyContact.fromJson(json['emergency_contact'])
          : null,
      locations: json['locations'] is List ? json['locations'] : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_code': farmerCode,
    'full_name': fullName,
    'phone': phone,
    'nid': nid,
    'gender': gender,
    'address': address,
    'primary_activity': primaryActivity,
    'experience_years': experienceYears,
    'profile_photo_url': profilePhotoUrl,
    'app_access_enabled': appAccessEnabled,
    'status': status,
    'emergency_contact': emergencyContact?.toJson(),
    'locations': locations,
  };
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final String tokenType;
  final AuthUser? user;
  final FarmerProfile? farmerProfile;

  const LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.tokenType = 'Bearer',
    this.user,
    this.farmerProfile,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return LoginResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      token: data?['token']?.toString(),
      tokenType: data?['token_type']?.toString() ?? 'Bearer',
      user: data?['user'] != null ? AuthUser.fromJson(data!['user']) : null,
      farmerProfile: data?['farmer_profile'] != null
          ? FarmerProfile.fromJson(data!['farmer_profile'])
          : null,
    );
  }
}
