import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // In debug mode, show the standard Flutter error widget so it's
    // easy to see where the error comes from in the console.
    if (kDebugMode) {
      debugPrint('Flutter framework error: ${details.exceptionAsString()}');
      debugPrintStack(stackTrace: details.stack);
      return ErrorWidget(details.exception);
    }

    // In release/profile, show a single friendly error screen.
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 5 seconds to allow error widget on new screens
      Future.delayed(const Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('ar', 'SA'));

  void changeTheme(ThemeMode themeMode) {
    themeNotifier.value = themeMode;
  }

  void changeLocale(Locale locale) {
    localeNotifier.value = locale;
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentThemeMode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: localeNotifier,
            builder: (context, currentLocale, _) {
              return MaterialApp(
                title: 'bensa_service_platform',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: currentThemeMode,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('ar', 'SA'),
                  Locale('en', 'US'),
                ],
                locale: currentLocale,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: child!,
                  );
                },
                debugShowCheckedModeBanner: false,
                routes: AppRoutes.routes,
                initialRoute: AppRoutes.initial,
              );
            },
          );
        },
      );
    });
  }
}
