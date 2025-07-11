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
    this.transactionId,
    this.paymentMethod,
    this.paymentDate,
    this.receiptImagePath,
    this.isOfflinePayment = false,
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
    transactionId = json['transactionId'];
    paymentMethod = json['paymentMethod'];
    paymentDate = json['paymentDate'] != null
        ? DateTime.parse(json['paymentDate'])
        : null;
    receiptImagePath = json['receiptImagePath'];
    isOfflinePayment = json['isOfflinePayment'] ?? false;

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
  String? transactionId; // Transaction ID for offline payments
  String? paymentMethod; // online, offline_manual, offline_ocr
  DateTime? paymentDate; // Date when payment was made
  String? receiptImagePath; // Path to stored receipt image
  bool? isOfflinePayment; // Flag to indicate if it's an offline payment

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
    String? transactionId,
    String? paymentMethod,
    DateTime? paymentDate,
    String? receiptImagePath,
    bool? isOfflinePayment,
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
        transactionId: transactionId ?? this.transactionId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentDate: paymentDate ?? this.paymentDate,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
        isOfflinePayment: isOfflinePayment ?? this.isOfflinePayment,
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
    map['transactionId'] = transactionId;
    map['paymentMethod'] = paymentMethod;
    map['paymentDate'] = paymentDate?.toIso8601String();
    map['receiptImagePath'] = receiptImagePath;
    map['isOfflinePayment'] = isOfflinePayment;
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
