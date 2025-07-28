import '../../base/idto.dart';

List<EducationDto> educationFromJson(List<dynamic> list) =>
    List<EducationDto>.from(list.map((x) => EducationDto.fromJson(x)));

class EducationDto implements IDto {
  EducationDto({
    this.id,
    this.education,
  });

  EducationDto.fromJson(dynamic json) {
    id = json['id'];
    education = json['education'];
  }

  int? id;
  String? education;

  EducationDto copyWith({
    int? id,
    String? education,
  }) =>
      EducationDto(
        id: id ?? this.id,
        education: education ?? this.education,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['education'] = education;
    return map;
  }
}
