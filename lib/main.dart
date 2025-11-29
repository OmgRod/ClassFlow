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

  runApp(const ClassFlowApp());
}

class ClassFlowApp extends StatelessWidget {
  const ClassFlowApp({super.key});

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
      final settings = DatabaseService.settings;
      final alreadySeen = settings['hasSeenTutorial'] as bool? ?? false;
      if (alreadySeen) return;

      final timetable = context.read<TimetableService>();
      final hasLessons = timetable.lessons.isNotEmpty;
      final usesWeekNumbers = timetable.lessons.any((l) => l.weekNumber != 0);

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return TutorialDialog(
            hasLessons: hasLessons,
            usesWeekNumbers: usesWeekNumbers,
          );
        },
      );

      // Note: hasSeenTutorial is now set by the dialog itself if "Don't show again" is checked
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

class TutorialDialog extends StatefulWidget {
  final bool hasLessons;
  final bool usesWeekNumbers;

  const TutorialDialog({
    super.key,
    required this.hasLessons,
    required this.usesWeekNumbers,
  });

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _page = 0;
  bool _dontShowAgain = false;

  void _next() {
    setState(() {
      _page = (_page + 1).clamp(0, 2);
    });
  }

  void _prev() {
    setState(() {
      _page = (_page - 1).clamp(0, 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Welcome to ClassFlow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Keep track of your timetable and which books you need for each lesson.',
          ),
        ],
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flexible schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (!widget.hasLessons)
            const Text(
              'Start by adding lessons in the Timetable tab. Each lesson can repeat every week, every two weeks, or with a custom interval – no fixed A/B pattern required.',
            )
          else if (widget.usesWeekNumbers)
            const Text(
              'We detected existing lessons using an A/B (week 1 / week 2) pattern. Those will keep working exactly as before. New lessons can still use flexible recurrence.',
            )
          else
            const Text(
              'Your existing lessons will continue to repeat according to their recurrence settings. You are not limited to an A/B week pattern – use weekly, biweekly, or custom intervals per lesson.',
            ),
        ],
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Tips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('• Tap a lesson to edit details and books.'),
          SizedBox(height: 4),
          Text('• Use the Scanner tab to quickly find a book by QR code.'),
        ],
      ),
    ];

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          pages[_page],
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (value) {
                  setState(() {
                    _dontShowAgain = value ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  "Don't show this again",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _page == 0 ? null : _prev,
                child: const Text('Previous'),
              ),
              Row(
                children: List.generate(
                  pages.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _page == pages.length - 1
                    ? () async {
                        if (_dontShowAgain) {
                          DatabaseService.settings['hasSeenTutorial'] = true;
                          await DatabaseService.save();
                        }
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      }
                    : _next,
                child: Text(_page == pages.length - 1 ? 'Done' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
