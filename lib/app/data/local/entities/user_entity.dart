import 'package:openimis_app/app/data/local/base/i_entity.dart';

class UserEntity implements IEntity {
  String? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? token;
  String? status;
  String? role;
  String? refresh;
  bool? isOfficer;
  bool? isInsuree;
  InsureeInfo? insureeInfo; // Add insureeInfo field
  String? username;
  String? csrfToken;
  OfficerInfo? officerInfo; // For officer users

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.token,
    this.status,
    this.role,
    this.refresh,
    this.isOfficer,
    this.isInsuree,
    this.insureeInfo, // Optional field
    this.username,
    this.csrfToken,
    this.officerInfo,
  });

  @override
  UserEntity.fromMap(dynamic map) {
    id = map['id'];
    name = map['name'];
    email = map['email'];
    phoneNumber = map['phone'];
    token = map['token'];
    status = map['status'];
    role = map['role'];
    refresh = map['refresh'];
    isOfficer = map['is_officer'];
    isInsuree = map['is_insuree'];
    username = map['username'];
    csrfToken = map['csrf_token'];
    // Deserialize insureeInfo if present
    insureeInfo = map['insuree_info'] != null
        ? InsureeInfo.fromMap(map['insuree_info'])
        : null;
    // Deserialize officerInfo if present
    officerInfo = map['officer_info'] != null
        ? OfficerInfo.fromMap(map['officer_info'])
        : null;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['email'] = email;
    map['phone'] = phoneNumber;
    map['token'] = token;
    map['role'] = role;
    map['status'] = status;
    map['refresh'] = refresh;
    map['is_officer'] = isOfficer;
    map['is_insuree'] = isInsuree;
    map['username'] = username;
    map['csrf_token'] = csrfToken;
    // Serialize insureeInfo if present
    if (insureeInfo != null) {
      map['insuree_info'] = insureeInfo!.toMap();
    }
    // Serialize officerInfo if present
    if (officerInfo != null) {
      map['officer_info'] = officerInfo!.toMap();
    }
    return map;
  }
}

// Define OfficerInfo class
class OfficerInfo {
  int? id;
  String? language;
  String? lastName;
  String? otherNames;
  int? healthFacilityId;
  List<int>? rights;
  bool? hasPassword;

  OfficerInfo({
    this.id,
    this.language,
    this.lastName,
    this.otherNames,
    this.healthFacilityId,
    this.rights,
    this.hasPassword,
  });

  OfficerInfo.fromMap(dynamic map) {
    id = map['id'];
    language = map['language'];
    lastName = map['last_name'];
    otherNames = map['other_names'];
    healthFacilityId = map['health_facility_id'];
    rights = map['rights'] != null ? List<int>.from(map['rights']) : null;
    hasPassword = map['has_password'];
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['language'] = language;
    map['last_name'] = lastName;
    map['other_names'] = otherNames;
    map['health_facility_id'] = healthFacilityId;
    map['rights'] = rights;
    map['has_password'] = hasPassword;
    return map;
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory OfficerInfo.fromJson(Map<String, dynamic> json) {
    return OfficerInfo(
      id: json['id'],
      language: json['language'],
      lastName: json['last_name'],
      otherNames: json['other_names'],
      healthFacilityId: json['health_facility_id'],
      rights: json['rights'] != null ? List<int>.from(json['rights']) : null,
      hasPassword: json['has_password'],
    );
  }
}

// Define InsureeInfo class
class InsureeInfo {
  String? firstName;
  String? lastName;
  String? chfid;
  String? uuid;
  dynamic? family;

  InsureeInfo({
    this.firstName,
    this.lastName,
    this.chfid,
    this.uuid,
    this.family,
  });

  InsureeInfo.fromMap(dynamic map) {
    firstName = map['first_name'];
    lastName = map['last_name'];
    chfid = map['chfid'];
    uuid = map['uuid'];
    family = map['family'];
  }

// toJson method
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'chfid': chfid,
      'uuid': uuid,
      'family': family,
    };
  }

  factory InsureeInfo.fromJson(Map<String, dynamic> json) {
    return InsureeInfo(
        firstName: json['first_name'],
        lastName: json['last_name'],
        chfid: json['chfid'],
        uuid: json['uuid'],
        family: json['family']);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['chfid'] = chfid;
    map['uuid'] = uuid;
    map['family'] = family;
    return map;
  }
}
