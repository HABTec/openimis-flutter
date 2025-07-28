import '../../base/idto.dart';

class LocationHierarchyResponse implements IDto {
  LocationHierarchyResponse({
    this.data,
  });

  LocationHierarchyResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? LocationData.fromJson(json['data']) : null;
  }

  LocationData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class LocationData implements IDto {
  LocationData({
    this.locationsStr,
  });

  LocationData.fromJson(Map<String, dynamic> json) {
    if (json['locationsStr'] != null) {
      locationsStr = LocationsStr.fromJson(json['locationsStr']);
    }
  }

  LocationsStr? locationsStr;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (locationsStr != null) {
      map['locationsStr'] = locationsStr!.toJson();
    }
    return map;
  }
}

class LocationsStr implements IDto {
  LocationsStr({
    this.edges,
  });

  LocationsStr.fromJson(Map<String, dynamic> json) {
    if (json['edges'] != null) {
      edges = <LocationEdge>[];
      json['edges'].forEach((v) {
        edges!.add(LocationEdge.fromJson(v));
      });
    }
  }

  List<LocationEdge>? edges;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (edges != null) {
      map['edges'] = edges!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class LocationEdge implements IDto {
  LocationEdge({
    this.node,
  });

  LocationEdge.fromJson(Map<String, dynamic> json) {
    node = json['node'] != null ? LocationNode.fromJson(json['node']) : null;
  }

  LocationNode? node;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (node != null) {
      map['node'] = node!.toJson();
    }
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
    this.clientMutationId,
    this.children,
  });

  LocationNode.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    code = json['code'];
    name = json['name'];
    type = json['type'];
    clientMutationId = json['clientMutationId'];
    children = json['children'] != null
        ? LocationChildren.fromJson(json['children'])
        : null;
  }

  String? id;
  String? uuid;
  String? code;
  String? name;
  String? type; // R = Region, D = District, W = Municipality, V = Village
  String? clientMutationId;
  LocationChildren? children;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['uuid'] = uuid;
    map['code'] = code;
    map['name'] = name;
    map['type'] = type;
    map['clientMutationId'] = clientMutationId;
    if (children != null) {
      map['children'] = children!.toJson();
    }
    return map;
  }
}

class LocationChildren implements IDto {
  LocationChildren({
    this.edges,
  });

  LocationChildren.fromJson(Map<String, dynamic> json) {
    if (json['edges'] != null) {
      edges = <LocationEdge>[];
      json['edges'].forEach((v) {
        edges!.add(LocationEdge.fromJson(v));
      });
    }
  }

  List<LocationEdge>? edges;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (edges != null) {
      map['edges'] = edges!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

// Helper class for flattened location selection
class FlatLocationDto implements IDto {
  FlatLocationDto({
    this.id,
    this.uuid,
    this.code,
    this.name,
    this.type,
    this.fullPath,
    this.parentId,
  });

  FlatLocationDto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    code = json['code'];
    name = json['name'];
    type = json['type'];
    fullPath = json['fullPath'];
    parentId = json['parentId'];
  }

  String? id;
  String? uuid;
  String? code;
  String? name;
  String? type;
  String? fullPath; // e.g., "Region 1 > District 1 > Achi > Rachla"
  String? parentId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['uuid'] = uuid;
    map['code'] = code;
    map['name'] = name;
    map['type'] = type;
    map['fullPath'] = fullPath;
    map['parentId'] = parentId;
    return map;
  }
}

// Utility functions for location processing
class LocationHierarchyUtils {
  static List<FlatLocationDto> flattenLocationHierarchy(
      LocationHierarchyResponse response) {
    List<FlatLocationDto> flatList = [];

    if (response.data?.locationsStr?.edges != null) {
      for (var edge in response.data!.locationsStr!.edges!) {
        if (edge.node != null) {
          _processLocationNode(edge.node!, flatList, "", parentId: null);
        }
      }
    }
    return flatList;
  }

  static void _processLocationNode(
      LocationNode node, List<FlatLocationDto> flatList, String parentPath,
      {String? parentId}) {
    String currentPath =
        parentPath.isEmpty ? node.name! : "$parentPath > ${node.name!}";

    flatList.add(FlatLocationDto(
      id: node.id,
      uuid: node.uuid,
      code: node.code,
      name: node.name,
      type: node.type,
      fullPath: currentPath,
      parentId: parentId, // Set the parent ID
    ));

    if (node.children?.edges != null) {
      for (var childEdge in node.children!.edges!) {
        if (childEdge.node != null) {
          _processLocationNode(childEdge.node!, flatList, currentPath,
              parentId: node.id); // Pass current node ID as parent for children
        }
      }
    }
  }

  static List<FlatLocationDto> getLocationsByType(
      List<FlatLocationDto> locations, String type) {
    return locations.where((location) => location.type == type).toList();
  }
}
