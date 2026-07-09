import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_provider.dart';
import 'firebase_options.dart';
import 'providers/book_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'widgets/router_pop_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final themeProvider = context.watch<ThemeProvider>();
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(themeProvider.fontScale),
          ),
          child: RouterPopScope(
            router: router,
            isAuthenticated: context.watch<AuthProvider>().isAuthenticated,
            child: child,
          ),
        );
      },
    );
  }
}
