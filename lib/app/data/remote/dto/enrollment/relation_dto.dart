import '../../base/idto.dart';

List<RelationDto> relationFromJson(List<dynamic> list) =>
    List<RelationDto>.from(list.map((x) => RelationDto.fromJson(x)));

class RelationDto implements IDto {
  RelationDto({
    this.id,
    this.relation,
  });

  RelationDto.fromJson(dynamic json) {
    id = json['id'];
    relation = json['relation'];
  }

  int? id;
  String? relation;

  RelationDto copyWith({
    int? id,
    String? relation,
  }) =>
      RelationDto(
        id: id ?? this.id,
        relation: relation ?? this.relation,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['relation'] = relation;
    return map;
  }
}
