import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_provider.dart';
import 'firebase_options.dart';
import 'providers/book_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/router_pop_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: const AlNisarApp(),
    ),
  );
}

class AlNisarApp extends StatelessWidget {
  const AlNisarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(context.watch<AuthProvider>());
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'AL Nisar App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      builder: (context, child) => RouterPopScope(
        router: router,
        isAuthenticated: context.watch<AuthProvider>().isAuthenticated,
        child: child,
      ),
    );
  }
}
