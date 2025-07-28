import '../../base/idto.dart';

List<FamilyTypeDto> familyTypeFromJson(List<dynamic> list) =>
    List<FamilyTypeDto>.from(list.map((x) => FamilyTypeDto.fromJson(x)));

class FamilyTypeDto implements IDto {
  FamilyTypeDto({
    this.code,
    this.type,
  });

  FamilyTypeDto.fromJson(dynamic json) {
    code = json['code'];
    type = json['type'];
  }

  String? code;
  String? type;

  FamilyTypeDto copyWith({
    String? code,
    String? type,
  }) =>
      FamilyTypeDto(
        code: code ?? this.code,
        type: type ?? this.type,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = code;
    map['type'] = type;
    return map;
  }
}
