import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wtv/firebase_options.dart';
import 'package:wtv/screens/splash.dart';
import 'package:wtv/styles/app_sytles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WtvApp());
}

class WtvApp extends StatelessWidget {
  const WtvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home Design',
      theme: AppSytles.themeData,
      home: const Splash(),
      supportedLocales: [Locale('es')],
      localizationsDelegates: [
        FirebaseUILocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
