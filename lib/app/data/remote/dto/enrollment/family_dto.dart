import '../../base/idto.dart';

// Response DTOs for GraphQL family query
class FamilyResponse implements IDto {
  FamilyResponse({
    this.data,
  });

  FamilyResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? FamilyData.fromJson(json['data']) : null;
  }

  FamilyData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class FamilyData implements IDto {
  FamilyData({
    this.families,
  });

  FamilyData.fromJson(Map<String, dynamic> json) {
    families = json['families'] != null
        ? FamiliesConnection.fromJson(json['families'])
        : null;
  }

  FamiliesConnection? families;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (families != null) {
      map['families'] = families!.toJson();
    }
    return map;
  }
}

class FamiliesConnection implements IDto {
  FamiliesConnection({
    this.totalCount,
    this.pageInfo,
    this.edges,
  });

  FamiliesConnection.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    pageInfo =
        json['pageInfo'] != null ? PageInfo.fromJson(json['pageInfo']) : null;
    if (json['edges'] != null) {
      edges = <FamilyEdge>[];
      json['edges'].forEach((v) {
        edges!.add(FamilyEdge.fromJson(v));
      });
    }
  }

  int? totalCount;
  PageInfo? pageInfo;
  List<FamilyEdge>? edges;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['totalCount'] = totalCount;
    if (pageInfo != null) {
      map['pageInfo'] = pageInfo!.toJson();
    }
    if (edges != null) {
      map['edges'] = edges!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class PageInfo implements IDto {
  PageInfo({
    this.hasNextPage,
    this.hasPreviousPage,
    this.startCursor,
    this.endCursor,
  });

  PageInfo.fromJson(Map<String, dynamic> json) {
    hasNextPage = json['hasNextPage'];
    hasPreviousPage = json['hasPreviousPage'];
    startCursor = json['startCursor'];
    endCursor = json['endCursor'];
  }

  bool? hasNextPage;
  bool? hasPreviousPage;
  String? startCursor;
  String? endCursor;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['hasNextPage'] = hasNextPage;
    map['hasPreviousPage'] = hasPreviousPage;
    map['startCursor'] = startCursor;
    map['endCursor'] = endCursor;
    return map;
  }
}

class FamilyEdge implements IDto {
  FamilyEdge({
    this.node,
  });

  FamilyEdge.fromJson(Map<String, dynamic> json) {
    node = json['node'] != null ? FamilyNode.fromJson(json['node']) : null;
  }

  FamilyNode? node;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (node != null) {
      map['node'] = node!.toJson();
    }
    return map;
  }
}

class FamilyNode implements IDto {
  FamilyNode({
    this.id,
    this.uuid,
    this.poverty,
    this.confirmationNo,
    this.validityFrom,
    this.validityTo,
    this.headInsuree,
    this.location,
  });

  FamilyNode.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    poverty = json['poverty'];
    confirmationNo = json['confirmationNo'];
    validityFrom = json['validityFrom'];
    validityTo = json['validityTo'];
    headInsuree = json['headInsuree'] != null
        ? HeadInsuree.fromJson(json['headInsuree'])
        : null;
    location = json['location'] != null
        ? LocationNode.fromJson(json['location'])
        : null;
  }

  String? id;
  String? uuid;
  bool? poverty;
  String? confirmationNo;
  String? validityFrom;
  String? validityTo;
  HeadInsuree? headInsuree;
  LocationNode? location;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['uuid'] = uuid;
    map['poverty'] = poverty;
    map['confirmationNo'] = confirmationNo;
    map['validityFrom'] = validityFrom;
    map['validityTo'] = validityTo;
    if (headInsuree != null) {
      map['headInsuree'] = headInsuree!.toJson();
    }
    if (location != null) {
      map['location'] = location!.toJson();
    }
    return map;
  }
}

class HeadInsuree implements IDto {
  HeadInsuree({
    this.id,
    this.uuid,
    this.chfId,
    this.lastName,
    this.otherNames,
    this.email,
    this.phone,
    this.dob,
  });

  HeadInsuree.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    chfId = json['chfId'];
    lastName = json['lastName'];
    otherNames = json['otherNames'];
    email = json['email'];
    phone = json['phone'];
    dob = json['dob'];
  }

  String? id;
  String? uuid;
  String? chfId;
  String? lastName;
  String? otherNames;
  String? email;
  String? phone;
  String? dob;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['uuid'] = uuid;
    map['chfId'] = chfId;
    map['lastName'] = lastName;
    map['otherNames'] = otherNames;
    map['email'] = email;
    map['phone'] = phone;
    map['dob'] = dob;
    return map;
  }
}

class LocationNode implements IDto {
  LocationNode({
    this.id,
    this.uuid,
    this.code,
    this.name,
    this.type,
    this.parent,
  });

  LocationNode.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    code = json['code'];
    name = json['name'];
    type = json['type'];
    parent =
        json['parent'] != null ? LocationNode.fromJson(json['parent']) : null;
  }

  String? id;
  String? uuid;
  String? code;
  String? name;
  String? type;
  LocationNode? parent;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['uuid'] = uuid;
    map['code'] = code;
    map['name'] = name;
    map['type'] = type;
    if (parent != null) {
      map['parent'] = parent!.toJson();
    }
    return map;
  }
}

// Helper function to convert JSON list to FamilyResponse
FamilyResponse familyResponseFromJson(Map<String, dynamic> json) =>
    FamilyResponse.fromJson(json);

// Helper function to get flat list of families from response
List<FamilyNode> getFamiliesFromResponse(FamilyResponse response) {
  return response.data?.families?.edges?.map((edge) => edge.node!).toList() ??
      [];
}
