import '../../base/idto.dart';

class InsureeDto implements IDto {
  InsureeDto({
    this.localId,
    this.chfId,
    this.lastName,
    this.otherNames,
    this.genderId,
    this.dob,
    this.head,
    this.marital,
    this.passport,
    this.phone,
    this.email,
    this.photo,
    this.cardIssued,
    this.professionId,
    this.educationId,
    this.typeOfIdId,
    this.familyId,
    this.relationshipId,
    this.status,
    this.disabilityStatus,
    this.jsonExt,
    this.syncStatus,
    this.localFamilyId,
    this.createdAt,
    this.updatedAt,
    this.syncError,
  });

  InsureeDto.fromJson(Map<String, dynamic> json) {
    localId = json['localId'];
    chfId = json['chfId'];
    lastName = json['lastName'];
    otherNames = json['otherNames'];
    genderId = json['genderId'];
    dob = json['dob'];
    head = json['head'];
    marital = json['marital'];
    passport = json['passport'];
    phone = json['phone'];
    email = json['email'];
    photo = json['photo'] != null ? PhotoDto.fromJson(json['photo']) : null;
    cardIssued = json['cardIssued'];
    professionId = json['professionId'];
    educationId = json['educationId'];
    typeOfIdId = json['typeOfIdId'];
    familyId = json['familyId'];
    relationshipId = json['relationshipId'];
    status = json['status'];
    disabilityStatus = json['disabilityStatus'];
    jsonExt = json['jsonExt'];
    syncStatus = json['syncStatus'] ?? 0;
    localFamilyId = json['localFamilyId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    syncError = json['syncError'];
  }

  int? localId; // Local database ID
  String? chfId;
  String? lastName;
  String? otherNames;
  String? genderId; // M, F
  String? dob; // Date in YYYY-MM-DD format
  bool? head;
  String? marital; // N, W, S, D, M
  String? passport;
  String? phone;
  String? email;
  PhotoDto? photo;
  bool? cardIssued;
  int? professionId;
  int? educationId;
  String? typeOfIdId; // D, N, P, V
  int? familyId; // Remote family ID after sync
  int? relationshipId;
  String? status; // AC (Active)
  String? disabilityStatus; // Disability status from the 15-item list
  String? jsonExt;
  int? syncStatus; // 0 = pending, 1 = synced, 2 = failed
  int? localFamilyId; // Local family ID before sync
  String? createdAt;
  String? updatedAt;
  String? syncError;

  InsureeDto copyWith({
    int? localId,
    String? chfId,
    String? lastName,
    String? otherNames,
    String? genderId,
    String? dob,
    bool? head,
    String? marital,
    String? passport,
    String? phone,
    String? email,
    PhotoDto? photo,
    bool? cardIssued,
    int? professionId,
    int? educationId,
    String? typeOfIdId,
    int? familyId,
    int? relationshipId,
    String? status,
    String? disabilityStatus,
    String? jsonExt,
    int? syncStatus,
    int? localFamilyId,
    String? createdAt,
    String? updatedAt,
    String? syncError,
  }) =>
      InsureeDto(
        localId: localId ?? this.localId,
        chfId: chfId ?? this.chfId,
        lastName: lastName ?? this.lastName,
        otherNames: otherNames ?? this.otherNames,
        genderId: genderId ?? this.genderId,
        dob: dob ?? this.dob,
        head: head ?? this.head,
        marital: marital ?? this.marital,
        passport: passport ?? this.passport,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        photo: photo ?? this.photo,
        cardIssued: cardIssued ?? this.cardIssued,
        professionId: professionId ?? this.professionId,
        educationId: educationId ?? this.educationId,
        typeOfIdId: typeOfIdId ?? this.typeOfIdId,
        familyId: familyId ?? this.familyId,
        relationshipId: relationshipId ?? this.relationshipId,
        status: status ?? this.status,
        disabilityStatus: disabilityStatus ?? this.disabilityStatus,
        jsonExt: jsonExt ?? this.jsonExt,
        syncStatus: syncStatus ?? this.syncStatus,
        localFamilyId: localFamilyId ?? this.localFamilyId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncError: syncError ?? this.syncError,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['localId'] = localId;
    map['chfId'] = chfId;
    map['lastName'] = lastName;
    map['otherNames'] = otherNames;
    map['genderId'] = genderId;
    map['dob'] = dob;
    map['head'] = head;
    map['marital'] = marital;
    map['passport'] = passport;
    map['phone'] = phone;
    map['email'] = email;
    if (photo != null) {
      map['photo'] = photo!.toJson();
    }
    map['cardIssued'] = cardIssued;
    map['professionId'] = professionId;
    map['educationId'] = educationId;
    map['typeOfIdId'] = typeOfIdId;
    map['familyId'] = familyId;
    map['relationshipId'] = relationshipId;
    map['status'] = status;
    map['disabilityStatus'] = disabilityStatus;
    map['jsonExt'] = jsonExt;
    map['syncStatus'] = syncStatus;
    map['localFamilyId'] = localFamilyId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['syncError'] = syncError;
    return map;
  }

  // Convert to GraphQL mutation format
  Map<String, dynamic> toGraphQLInput(int officerId) {
    return {
      'chfId': chfId,
      'lastName': lastName,
      'otherNames': otherNames,
      'genderId': genderId,
      'dob': dob,
      'head': head ?? false,
      'marital': marital ?? 'N',
      'passport': passport ?? '',
      'phone': phone ?? '',
      'email': email ?? '',
      'photo': photo?.toGraphQLInput(officerId),
      'cardIssued': cardIssued ?? true,
      'professionId': professionId,
      'educationId': educationId,
      'typeOfIdId': typeOfIdId ?? 'D',
      'familyId': familyId,
      'relationshipId': relationshipId,
      'status': status ?? 'AC',
      'jsonExt': jsonExt ?? '{}',
    };
  }
}

class PhotoDto implements IDto {
  PhotoDto({
    this.officerId,
    this.date,
    this.photo,
  });

  PhotoDto.fromJson(Map<String, dynamic> json) {
    officerId = json['officerId'];
    date = json['date'];
    photo = json['photo'];
  }

  int? officerId;
  String? date;
  String? photo; // Base64 encoded image

  PhotoDto copyWith({
    int? officerId,
    String? date,
    String? photo,
  }) =>
      PhotoDto(
        officerId: officerId ?? this.officerId,
        date: date ?? this.date,
        photo: photo ?? this.photo,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['officerId'] = officerId;
    map['date'] = date;
    map['photo'] = photo;
    return map;
  }

  Map<String, dynamic> toGraphQLInput(int defaultOfficerId) {
    return {
      'officerId': officerId ?? defaultOfficerId,
      'date': date ?? DateTime.now().toIso8601String().split('T')[0],
      'photo': photo ?? '',
    };
  }
}

class FamilyDto implements IDto {
  FamilyDto({
    this.localId,
    this.headInsuree,
    this.locationId,
    this.poverty,
    this.familyTypeId,
    this.address,
    this.confirmationTypeId,
    this.confirmationNo,
    this.jsonExt,
    this.syncStatus,
    this.remoteFamilyId,
    this.createdAt,
    this.updatedAt,
    this.syncError,
  });

  FamilyDto.fromJson(Map<String, dynamic> json) {
    localId = json['localId'];
    headInsuree = json['headInsuree'] != null
        ? InsureeDto.fromJson(json['headInsuree'])
        : null;
    locationId = json['locationId'];
    poverty = json['poverty'];
    familyTypeId = json['familyTypeId'];
    address = json['address'];
    confirmationTypeId = json['confirmationTypeId'];
    confirmationNo = json['confirmationNo'];
    jsonExt = json['jsonExt'];
    syncStatus = json['syncStatus'] ?? 0;
    remoteFamilyId = json['remoteFamilyId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    syncError = json['syncError'];
  }

  int? localId; // Local database ID
  InsureeDto? headInsuree;
  int? locationId;
  bool? poverty;
  String? familyTypeId;
  String? address;
  String? confirmationTypeId;
  String? confirmationNo;
  String? jsonExt;
  int? syncStatus; // 0 = pending, 1 = synced, 2 = failed
  int? remoteFamilyId; // Remote family ID after sync
  String? createdAt;
  String? updatedAt;
  String? syncError;

  FamilyDto copyWith({
    int? localId,
    InsureeDto? headInsuree,
    int? locationId,
    bool? poverty,
    String? familyTypeId,
    String? address,
    String? confirmationTypeId,
    String? confirmationNo,
    String? jsonExt,
    int? syncStatus,
    int? remoteFamilyId,
    String? createdAt,
    String? updatedAt,
    String? syncError,
  }) =>
      FamilyDto(
        localId: localId ?? this.localId,
        headInsuree: headInsuree ?? this.headInsuree,
        locationId: locationId ?? this.locationId,
        poverty: poverty ?? this.poverty,
        familyTypeId: familyTypeId ?? this.familyTypeId,
        address: address ?? this.address,
        confirmationTypeId: confirmationTypeId ?? this.confirmationTypeId,
        confirmationNo: confirmationNo ?? this.confirmationNo,
        jsonExt: jsonExt ?? this.jsonExt,
        syncStatus: syncStatus ?? this.syncStatus,
        remoteFamilyId: remoteFamilyId ?? this.remoteFamilyId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncError: syncError ?? this.syncError,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['localId'] = localId;
    if (headInsuree != null) {
      map['headInsuree'] = headInsuree!.toJson();
    }
    map['locationId'] = locationId;
    map['poverty'] = poverty;
    map['familyTypeId'] = familyTypeId;
    map['address'] = address;
    map['confirmationTypeId'] = confirmationTypeId;
    map['confirmationNo'] = confirmationNo;
    map['jsonExt'] = jsonExt;
    map['syncStatus'] = syncStatus;
    map['remoteFamilyId'] = remoteFamilyId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['syncError'] = syncError;
    return map;
  }

  // Convert to GraphQL mutation format
  Map<String, dynamic> toGraphQLInput(int officerId, String clientMutationId) {
    return {
      'clientMutationId': clientMutationId,
      'clientMutationLabel':
          'Create family - ${headInsuree?.otherNames} ${headInsuree?.lastName} (${headInsuree?.chfId})',
      'headInsuree': headInsuree?.toGraphQLInput(officerId),
      'locationId': locationId,
      'poverty': poverty ?? false,
      'familyTypeId': familyTypeId ?? 'H',
      'address': address ?? '',
      'confirmationTypeId': confirmationTypeId ?? 'A',
      'confirmationNo': confirmationNo ?? '',
      'jsonExt': jsonExt ?? '{}',
    };
  }
}
