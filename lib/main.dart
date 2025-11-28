import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/services.dart';
import 'services/theme_service.dart';
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
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: ThemeData.dark(),
            themeMode: themeService.mode,
            debugShowCheckedModeBanner: false,
            home: const _RootWithOnboarding(),
          );
        },
      ),
    );
  }
}

class _RootWithOnboarding extends StatefulWidget {
  const _RootWithOnboarding();

  @override
  State<_RootWithOnboarding> createState() => _RootWithOnboardingState();
}

class _RootWithOnboardingState extends State<_RootWithOnboarding> {
  bool _shownOnboarding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shownOnboarding) return;
    _shownOnboarding = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final timetable = context.read<TimetableService>();
      final hasLessons = timetable.lessons.isNotEmpty;
      final usesWeekNumbers = timetable.lessons.any((l) => l.weekNumber != 0);

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: Text('Welcome to ${AppConstants.appName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This app helps you keep track of your lessons and the books you need for each one.',
                ),
                const SizedBox(height: 12),
                if (!hasLessons)
                  const Text(
                    'Start by adding lessons in the Timetable tab. You can set each lesson to repeat every week, every two weeks, or with a custom interval – no fixed A/B pattern required.',
                  )
                else if (usesWeekNumbers)
                  const Text(
                    'We detected existing lessons using an A/B (week 1 / week 2) pattern. Those will keep working exactly as before. New lessons can still use flexible recurrence like every week, every two weeks, or custom intervals.',
                  )
                else
                  const Text(
                    'Your existing lessons will continue to repeat according to their recurrence settings. You are not limited to an A/B week pattern – use weekly, biweekly, or custom intervals per lesson.',
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Tip: Tap a lesson in the timetable to see its details, edit it, or manage notes and books.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
