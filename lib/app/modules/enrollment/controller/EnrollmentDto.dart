import 'package:openimis_app/app/data/remote/base/idto.dart';

class EnrollmentDto implements IDto {
  EnrollmentDto({
    this.chfid,
    this.eaCode,
    this.lastName,
    this.givenName,
    this.phone,
    this.email,
    this.identificationNo,
    this.birthdate,
    this.gender,
    this.maritalStatus,
    this.isHead,
    this.photo,
    this.headChfid,
    this.newEnrollment,
    this.healthFacilityLevel,
    this.healthFacility,
    this.familyType,
    this.confirmationType,
    this.confirmationNumber,
    this.addressDetail,
    this.family,
    this.relationShip,
    this.disabilityStatus,
    this.syncStatus = 0,
  });

  EnrollmentDto.fromJson(Map<String, dynamic> json) {
    chfid = json['chfid'];
    eaCode = json['eaCode'];
    lastName = json['lastName'];
    givenName = json['givenName'];
    phone = json['phone'];
    email = json['email'];
    identificationNo = json['identificationNo'];
    birthdate = json['birthdate'];
    gender = json['gender'];
    maritalStatus = json['maritalStatus'];
    isHead = json['isHead'];
    photo = json['photo'];
    headChfid = json['headChfid'];
    newEnrollment = json['newEnrollment'];
    healthFacilityLevel = json['healthFacilityLevel'];
    healthFacility = json['healthFacility'];
    familyType = json['familyType'];
    confirmationType = json['confirmationType'];
    confirmationNumber = json['confirmationNumber'];
    addressDetail = json['addressDetail'];
    relationShip = json['relationShip'];
    disabilityStatus = json['disabilityStatus'];
    syncStatus = json['syncStatus'] ?? 0;

    family = json['family'] != null ? Family.fromJson(json['family']) : null;
  }

  String? chfid;
  String? eaCode;
  String? lastName;
  String? givenName;
  String? phone;
  String? email;
  String? identificationNo;
  String? birthdate;
  String? gender;
  String? maritalStatus;
  bool? isHead;
  String? photo; // assuming photo will be stored as a base64 string
  String? headChfid;
  bool? newEnrollment;
  String? healthFacilityLevel;
  String? healthFacility;
  String? familyType;
  String? confirmationType;
  String? confirmationNumber;
  String? addressDetail;
  Family? family;
  String? relationShip;
  String? disabilityStatus; // None, Physical, Visual, Hearing, Mental, Other
  int? syncStatus; // 0 = not synced, 1 = synced

  EnrollmentDto copyWith({
    String? chfid,
    String? eaCode,
    String? lastName,
    String? givenName,
    String? phone,
    String? email,
    String? identificationNo,
    String? birthdate,
    String? gender,
    String? maritalStatus,
    bool? isHead,
    String? photo,
    String? headChfid,
    bool? newEnrollment,
    String? healthFacilityLevel,
    String? healthFacility,
    String? familyType,
    String? confirmationType,
    String? confirmationNumber,
    String? addressDetail,
    Family? family,
    String? relationShip,
    String? disabilityStatus,
    int? syncStatus,
  }) =>
      EnrollmentDto(
        chfid: chfid ?? this.chfid,
        eaCode: eaCode ?? this.eaCode,
        lastName: lastName ?? this.lastName,
        givenName: givenName ?? this.givenName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        identificationNo: identificationNo ?? this.identificationNo,
        birthdate: birthdate ?? this.birthdate,
        gender: gender ?? this.gender,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        isHead: isHead ?? this.isHead,
        photo: photo ?? this.photo,
        headChfid: headChfid ?? this.headChfid,
        newEnrollment: newEnrollment ?? this.newEnrollment,
        healthFacilityLevel: healthFacilityLevel ?? this.healthFacilityLevel,
        healthFacility: healthFacility ?? this.healthFacility,
        familyType: familyType ?? this.familyType,
        confirmationType: confirmationType ?? this.confirmationType,
        confirmationNumber: confirmationNumber ?? this.confirmationNumber,
        addressDetail: addressDetail ?? this.addressDetail,
        relationShip: relationShip ?? this.relationShip,
        family: family ?? this.family,
        disabilityStatus: disabilityStatus ?? this.disabilityStatus,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['chfid'] = chfid;
    map['eaCode'] = eaCode;
    map['lastName'] = lastName;
    map['givenName'] = givenName;
    map['phone'] = phone;
    map['email'] = email;
    map['identificationNo'] = identificationNo;
    map['birthdate'] = birthdate;
    map['gender'] = gender;
    map['maritalStatus'] = maritalStatus;
    map['isHead'] = isHead;
    map['photo'] = photo;
    map['headChfid'] = headChfid;
    map['newEnrollment'] = newEnrollment;
    map['healthFacilityLevel'] = healthFacilityLevel;
    map['healthFacility'] = healthFacility;
    map['familyType'] = familyType;
    map['confirmationType'] = confirmationType;
    map['confirmationNumber'] = confirmationNumber;
    map['addressDetail'] = addressDetail;
    map['relationShip'] = relationShip;
    map['disabilityStatus'] = disabilityStatus;
    map['syncStatus'] = syncStatus;
    if (family != null) {
      map['family'] = family!.toJson();
    }
    return map;
  }
}

class Family {
  Family({
    this.members,
    this.familyType,
  });

  Family.fromJson(Map<String, dynamic> json) {
    if (json['members'] != null) {
      members = List<FamilyMember>.from(
        json['members'].map((x) => FamilyMember.fromJson(x)),
      );
    }
    familyType = json['familyType'];
  }

  List<FamilyMember>? members;
  String? familyType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (members != null) {
      map['members'] = members!.map((x) => x.toJson()).toList();
    }
    map['familyType'] = familyType;
    return map;
  }
}

class FamilyMember {
  FamilyMember({
    this.name,
    this.relationship,
  });

  FamilyMember.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    relationship = json['relationship'];
  }

  String? name;
  String? relationship;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['relationship'] = relationship;
    return map;
  }
}
