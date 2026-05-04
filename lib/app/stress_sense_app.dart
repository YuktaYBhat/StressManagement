import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/activity_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recommendations_screen.dart';
import 'stress_sense_theme.dart';
//lib/app/stress_sense_app.dart registers Providers + routes + theme
class StressSenseApp extends StatelessWidget {
  const StressSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'StressSense',
            debugShowCheckedModeBanner: false,
            theme: StressSenseTheme.lightTheme,
            darkTheme: StressSenseTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/login',
            routes: {
              '/login': (_) => const LoginScreen(),
              '/home': (_) => const HomeScreen(),
              '/analytics': (_) => const AnalyticsScreen(),
              '/recommendations': (_) => const RecommendationsScreen(),
              '/activity': (_) => const ActivityScreen(),
              '/profile': (_) => const ProfileScreen(),
              '/history': (_) => const HistoryScreen(),
            },
          );
        },
      ),
    );
  }
}

