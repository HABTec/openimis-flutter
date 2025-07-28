import '../../base/idto.dart';

List<ProfessionDto> professionFromJson(List<dynamic> list) =>
    List<ProfessionDto>.from(list.map((x) => ProfessionDto.fromJson(x)));

class ProfessionDto implements IDto {
  ProfessionDto({
    this.id,
    this.profession,
  });

  ProfessionDto.fromJson(dynamic json) {
    id = json['id'];
    profession = json['profession'];
  }

  int? id;
  String? profession;

  ProfessionDto copyWith({
    int? id,
    String? profession,
  }) =>
      ProfessionDto(
        id: id ?? this.id,
        profession: profession ?? this.profession,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['profession'] = profession;
    return map;
  }
}
