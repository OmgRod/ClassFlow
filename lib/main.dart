import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/services.dart';
import 'screens/screens.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.initialize();

  runApp(const DetentionSafeApp());
}

class DetentionSafeApp extends StatelessWidget {
  const DetentionSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubjectService()),
        ChangeNotifierProvider(create: (_) => BookService()),
        ChangeNotifierProvider(create: (_) => TimetableService()),
      ],
      child: Builder(
        builder: (context) {
          final modeStr =
              (DatabaseService.settings['themeMode'] as String?) ?? 'system';
          ThemeMode mode = ThemeMode.system;
          if (modeStr == 'light') mode = ThemeMode.light;
          if (modeStr == 'dark') mode = ThemeMode.dark;

          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: ThemeData.dark(),
            themeMode: mode,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
