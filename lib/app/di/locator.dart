import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:openimis_app/app/data/remote/repositories/enrollment/enrollment_repository.dart';
import 'package:openimis_app/app/data/remote/repositories/public_enrollment/public_enrollment_repository.dart';
import 'package:openimis_app/app/data/remote/repositories/root/root_repository.dart';
import 'package:openimis_app/app/data/remote/services/enrollment/enrollment_service.dart';
import 'package:openimis_app/app/data/remote/services/enrollment/family_service.dart';
import 'package:openimis_app/app/data/remote/services/enrollment_public/public_enrollment_service.dart';
import 'package:openimis_app/app/data/remote/services/root/root_service.dart';
import '../data/local/services/storage_service.dart';
import '../data/remote/api/dio_client.dart';
import '../data/remote/repositories/auth/auth_repository.dart';
import '../data/remote/repositories/company/company_repository.dart';
import '../data/remote/repositories/customer/customer_repository.dart';
import '../data/remote/repositories/search/search_repository.dart';
import '../data/remote/services/auth/auth_service.dart';
import '../data/remote/services/company/comapny_service.dart';
import '../data/remote/services/customer/customer_service.dart';
import '../data/remote/services/search/search_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  /// Dio Client
  getIt.registerSingleton(Dio());
  getIt.registerSingleton(DioClient(getIt<Dio>()));

  /// Storage Service
  getIt.registerSingleton(GetStorage());
  getIt.registerSingleton(StorageService(getIt<GetStorage>()));

  /// Search Service & Repository
  getIt.registerSingleton(SearchService(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(SearchRepository(service: getIt<SearchService>()));

  /// Family Service (GraphQL)
  getIt.registerSingleton(FamilyService(dioClient: getIt<DioClient>()));

  /// Enrolllment Service & Repo
  getIt.registerSingleton(EnrollmentService(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(EnrollmentRepository(
    service: getIt<EnrollmentService>(),
    familyService: getIt<FamilyService>(),
  ));

  // Public Enrollment & Repository

  getIt.registerSingleton(
      PublicEnrollmentService(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(
      PublicEnrollmentRepository(service: getIt<PublicEnrollmentService>()));

  /// Company Service & Repository -> company as organization insurance
  getIt.registerSingleton(CompanyService(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(CompanyRepository(service: getIt<CompanyService>()));

  /// Customer Service & Repository
  getIt.registerSingleton(CustomerService(dioClient: getIt<DioClient>()));
  getIt
      .registerSingleton(CustomerRepository(service: getIt<CustomerService>()));

  /// Auth Service & Repository
  getIt.registerSingleton(AuthService(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(AuthRepository(
    authService: getIt<AuthService>(),
    storageService: getIt<StorageService>(),
  ));

  /// Root Service & Repository
  getIt.registerSingleton(RootService(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(RootRepository(
    rootService: getIt<RootService>(),
  ));
}
