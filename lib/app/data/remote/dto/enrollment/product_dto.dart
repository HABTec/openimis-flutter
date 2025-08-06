import '../../base/idto.dart';

class ProductDto implements IDto {
  ProductDto({
    this.id,
    this.code,
    this.name,
    this.membershipTypes,
    this.lumpSum,
    this.premiumAdult,
    this.ageMaximal,
    this.cardReplacementFee,
    this.enrolmentPeriodStartDate,
    this.enrolmentPeriodEndDate,
  });

  ProductDto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    name = json['name'];
    lumpSum = json['lumpSum'];
    premiumAdult = json['premiumAdult'];
    ageMaximal = json['ageMaximal'];
    cardReplacementFee = json['cardReplacementFee'];
    enrolmentPeriodStartDate = json['enrolmentPeriodStartDate'];
    enrolmentPeriodEndDate = json['enrolmentPeriodEndDate'];

    if (json['membershipTypes'] != null) {
      membershipTypes = <MembershipTypeDto>[];
      json['membershipTypes'].forEach((v) {
        membershipTypes!.add(MembershipTypeDto.fromJson(v));
      });
    }
  }

  String? id;
  String? code;
  String? name;
  List<MembershipTypeDto>? membershipTypes;
  String? lumpSum;
  String? premiumAdult;
  int? ageMaximal;
  String? cardReplacementFee;
  String? enrolmentPeriodStartDate;
  String? enrolmentPeriodEndDate;

  ProductDto copyWith({
    String? id,
    String? code,
    String? name,
    List<MembershipTypeDto>? membershipTypes,
    String? lumpSum,
    String? premiumAdult,
    int? ageMaximal,
    String? cardReplacementFee,
    String? enrolmentPeriodStartDate,
    String? enrolmentPeriodEndDate,
  }) =>
      ProductDto(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        membershipTypes: membershipTypes ?? this.membershipTypes,
        lumpSum: lumpSum ?? this.lumpSum,
        premiumAdult: premiumAdult ?? this.premiumAdult,
        ageMaximal: ageMaximal ?? this.ageMaximal,
        cardReplacementFee: cardReplacementFee ?? this.cardReplacementFee,
        enrolmentPeriodStartDate:
            enrolmentPeriodStartDate ?? this.enrolmentPeriodStartDate,
        enrolmentPeriodEndDate:
            enrolmentPeriodEndDate ?? this.enrolmentPeriodEndDate,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['code'] = code;
    map['name'] = name;
    if (membershipTypes != null) {
      map['membershipTypes'] = membershipTypes!.map((v) => v.toJson()).toList();
    }
    map['lumpSum'] = lumpSum;
    map['premiumAdult'] = premiumAdult;
    map['ageMaximal'] = ageMaximal;
    map['cardReplacementFee'] = cardReplacementFee;
    map['enrolmentPeriodStartDate'] = enrolmentPeriodStartDate;
    map['enrolmentPeriodEndDate'] = enrolmentPeriodEndDate;
    return map;
  }

  // Helper method to get premium adult amount
  double get premiumAdultAmount {
    return double.tryParse(premiumAdult ?? '0') ?? 0.0;
  }

  // Helper method to get lump sum amount
  double get lumpSumAmount {
    return double.tryParse(lumpSum ?? '0') ?? 0.0;
  }

  // Helper method to get card replacement fee
  double get cardReplacementFeeAmount {
    return double.tryParse(cardReplacementFee ?? '0') ?? 0.0;
  }
}

class MembershipTypeDto implements IDto {
  MembershipTypeDto({
    this.id,
    this.region,
    this.district,
    this.levelType,
    this.levelIndex,
    this.price,
  });

  MembershipTypeDto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    region = json['region'];
    district = json['district'];
    levelType = json['levelType'];
    levelIndex = json['levelIndex'];
    price = json['price'];
  }

  String? id;
  String? region;
  String? district;
  String? levelType;
  int? levelIndex;
  String? price;

  MembershipTypeDto copyWith({
    String? id,
    String? region,
    String? district,
    String? levelType,
    int? levelIndex,
    String? price,
  }) =>
      MembershipTypeDto(
        id: id ?? this.id,
        region: region ?? this.region,
        district: district ?? this.district,
        levelType: levelType ?? this.levelType,
        levelIndex: levelIndex ?? this.levelIndex,
        price: price ?? this.price,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['region'] = region;
    map['district'] = district;
    map['levelType'] = levelType;
    map['levelIndex'] = levelIndex;
    map['price'] = price;
    return map;
  }

  // Helper method to get registration fee (price)
  double get registrationFee {
    return double.tryParse(price ?? '0') ?? 0.0;
  }
}

// Response wrapper for the API
class UserProductsResponseDto implements IDto {
  UserProductsResponseDto({this.data});

  UserProductsResponseDto.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null
        ? UserProductsDataDto.fromJson(json['data'])
        : null;
  }

  UserProductsDataDto? data;

  UserProductsResponseDto copyWith({
    UserProductsDataDto? data,
  }) =>
      UserProductsResponseDto(
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class UserProductsDataDto implements IDto {
  UserProductsDataDto({this.userProducts});

  UserProductsDataDto.fromJson(Map<String, dynamic> json) {
    userProducts = json['userProducts'] != null
        ? UserProductsDto.fromJson(json['userProducts'])
        : null;
  }

  UserProductsDto? userProducts;

  UserProductsDataDto copyWith({
    UserProductsDto? userProducts,
  }) =>
      UserProductsDataDto(
        userProducts: userProducts ?? this.userProducts,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (userProducts != null) {
      map['userProducts'] = userProducts!.toJson();
    }
    return map;
  }
}

class UserProductsDto implements IDto {
  UserProductsDto({
    this.id,
    this.username,
    this.iUser,
  });

  UserProductsDto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    iUser = json['iUser'] != null ? IUserDto.fromJson(json['iUser']) : null;
  }

  String? id;
  String? username;
  IUserDto? iUser;

  UserProductsDto copyWith({
    String? id,
    String? username,
    IUserDto? iUser,
  }) =>
      UserProductsDto(
        id: id ?? this.id,
        username: username ?? this.username,
        iUser: iUser ?? this.iUser,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['username'] = username;
    if (iUser != null) {
      map['iUser'] = iUser!.toJson();
    }
    return map;
  }
}

class IUserDto implements IDto {
  IUserDto({
    this.healthFacilityId,
    this.products,
  });

  IUserDto.fromJson(Map<String, dynamic> json) {
    healthFacilityId = json['healthFacilityId'];
    if (json['products'] != null) {
      products = <ProductDto>[];
      json['products'].forEach((v) {
        products!.add(ProductDto.fromJson(v));
      });
    }
  }

  String? healthFacilityId;
  List<ProductDto>? products;

  IUserDto copyWith({
    String? healthFacilityId,
    List<ProductDto>? products,
  }) =>
      IUserDto(
        healthFacilityId: healthFacilityId ?? this.healthFacilityId,
        products: products ?? this.products,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['healthFacilityId'] = healthFacilityId;
    if (products != null) {
      map['products'] = products!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
