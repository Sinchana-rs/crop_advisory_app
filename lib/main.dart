
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Restore the saved language (English / Kannada / Hindi) before
  // the first frame so the app never starts in the wrong language.
  await LanguageService.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole MaterialApp whenever the language changes,
    // so built-in widgets (dialogs, date pickers, tooltips) and every
    // screen follow the selected language.
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.lang,
      builder: (context, language, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: LanguageService.t("appName"),
          locale: Locale(language),
          supportedLocales: const [
            Locale('en'),
            Locale('kn'),
            Locale('hi'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Roboto',
          ),
          home: SplashScreen(),
        );
      },
    );
  }
}
