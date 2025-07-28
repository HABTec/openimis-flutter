import '../../base/idto.dart';

List<ConfirmationTypeDto> confirmationTypeFromJson(List<dynamic> list) =>
    List<ConfirmationTypeDto>.from(
        list.map((x) => ConfirmationTypeDto.fromJson(x)));

class ConfirmationTypeDto implements IDto {
  ConfirmationTypeDto({
    this.code,
    this.confirmationtype,
    this.isConfirmationNumberRequired,
  });

  ConfirmationTypeDto.fromJson(dynamic json) {
    code = json['code'];
    confirmationtype = json['confirmationtype'];
    isConfirmationNumberRequired = json['isConfirmationNumberRequired'];
  }

  String? code;
  String? confirmationtype;
  bool? isConfirmationNumberRequired;

  ConfirmationTypeDto copyWith({
    String? code,
    String? confirmationtype,
    bool? isConfirmationNumberRequired,
  }) =>
      ConfirmationTypeDto(
        code: code ?? this.code,
        confirmationtype: confirmationtype ?? this.confirmationtype,
        isConfirmationNumberRequired:
            isConfirmationNumberRequired ?? this.isConfirmationNumberRequired,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = code;
    map['confirmationtype'] = confirmationtype;
    map['isConfirmationNumberRequired'] = isConfirmationNumberRequired;
    return map;
  }
}
