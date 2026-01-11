import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:prism/firebase_options.dart';
import 'package:prism/services/auth/auth_gate.dart';
import 'package:prism/themes/theme_provider.dart';
import 'package:provider/provider.dart';

import 'services/database/database_provider.dart';

void main() async {
  // Firebase setup
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env.dev");
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize ThemeProvider before running the app
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeFromPrefs();

  // Initialize GetX DatabaseProvider
  Get.put(DatabaseProvider());

  // Run app
  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
      },
      theme: themeProvider.themeData,
    );
  }
}
