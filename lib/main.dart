import 'package:country_codes/country_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:openimis_app/app/language/languages.dart';
import 'package:openimis_app/app/modules/root/controllers/root_controller.dart';
import 'dart:io'; // To check the platform
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/theme_service.dart';
import 'app/data/remote/base/status.dart';
import 'app/di/locator.dart';
import 'app/language/language_service.dart';
import 'app/modules/auth/bindings/auth_binding.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/modules/auth/views/login/login_view.dart';
import 'app/modules/root/views/root_view.dart';
import 'app/routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Initialize local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  // Firebase initialization
  if (Platform.isAndroid) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await CountryCodes.init();

  await GetStorage.init();
  final languageService = Get.put(LanguageService());
  final themeService = Get.put(ThemeService());
  // Local Notifications Setup
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  if (!Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  // Request permission for iOS
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Listen to messages while the app is in foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground Message: ${message.notification?.title}");
    _showLocalNotification(message);
  });

  // Listen to messages when the app is opened from a terminated state
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("Message opened: ${message.notification?.title}");
  });

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final rootController = Get.put(RootController());
  await Future.delayed(Duration(milliseconds: 100));
  await rootController.fetchConfigurations(); // Fetch configurations here
  await rootController.fetchSupportedPartners();

  runApp(
    KhaltiScope(
        publicKey: 'test_public_key_dc65060e070640009301000000000000',
        builder: (context, navigatorKey) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, child) => GetMaterialApp(
              navigatorKey: navigatorKey,
              translations: Languages(),
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('ne', 'NP'),
              ],
              localizationsDelegates: const [KhaltiLocalizations.delegate],
              fallbackLocale: const Locale('en', 'US'),
              locale: languageService.currentLocale ?? const Locale('en', 'US'),
              debugShowCheckedModeBanner: false,
              initialBinding: AuthBinding(),
              home: Obx(
                () {
                  if (rootController.configurationStatus.value ==
                      Status.loading) {
                    return const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Fetching configurations..."),
                          ],
                        ),
                      ),
                    );
                  }

                  // Show the main app views after loading is complete
                  return AuthController.to.currentUser != null
                      ? const RootView()
                      : const LoginView();
                },
              ),
              getPages: AppPages.routes,
              theme: themeService.isDarkTheme.value
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme,
              defaultTransition: Transition.cupertino,
            ),
          );
        }),
  );
}

void _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel_id',
    'Default Channel',
    channelDescription: 'This is the default channel',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title,
    message.notification?.body,
    notificationDetails,
  );
}
