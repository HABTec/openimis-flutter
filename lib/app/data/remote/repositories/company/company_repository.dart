import 'package:dio/dio.dart';

import '../../base/status.dart';
import '../../dto/company/company_out_dto.dart';
import '../../exceptions/dio_exceptions.dart';
import '../../services/company/i_company_service.dart';
import 'i_company_repository.dart';

class CompanyRepository implements ICompanyRepository<CompanyOutDto> {
  final ICompanyService service;

  CompanyRepository({required this.service});

  @override
  Future<Status<CompanyOutDto>> get({required String uuid}) async {
    try {
      // final response = await service.get(uuid: uuid);
      final response = {
        "id": "123",
        "name": "Tech Solutions Inc.",
        "email": "contact@techsolutions.com",
        "phone": "+1234567890",
        "description": "A leading provider of tech solutions.",
        "work_type": "Remote",
        "city": "San Francisco",
        "address": "123 Tech Street, San Francisco, CA 94107",
        "image": "https://example.com/image.png",
        "statusCode" : 200
      };
      if (response["statusCode"] == 200) {
        final CompanyOutDto job = CompanyOutDto.fromJson(response);
        return Status.success(data: job);
      }
      return const Status.failure(reason: "Something went wrong!");
    } on DioError catch (e) {
      final errMsg = DioExceptions.fromDioError(e).toString();
      return Status.failure(reason: errMsg);
    }
  }
}
