import 'package:flutter/material.dart';
import '../services/services.dart';

/// Enhanced onboarding system with step-by-step coach marks
class OnboardingCoach extends StatefulWidget {
  final Widget child;

  const OnboardingCoach({super.key, required this.child});

  @override
  State<OnboardingCoach> createState() => _OnboardingCoachState();
}

class _OnboardingCoachState extends State<OnboardingCoach> {
  int _currentStep = 0;
  bool _showCoachMark = false;
  final List<CoachMarkStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
    });
  }

  void _initializeSteps() {
    _steps.addAll([
      CoachMarkStep(
        title: 'Subjects',
        description:
            'Create subjects for your classes. Each subject can have a custom color and associated books.',
        icon: Icons.subject,
        targetKey: 'subjects_tab',
      ),
      CoachMarkStep(
        title: 'Timetable',
        description:
            'Add lessons to your weekly schedule. Lessons can repeat weekly, biweekly, or on custom intervals.',
        icon: Icons.calendar_today,
        targetKey: 'timetable_tab',
      ),
      CoachMarkStep(
        title: 'Books',
        description:
            'Register your textbooks and link them to subjects for quick reference.',
        icon: Icons.book,
        targetKey: 'books_tab',
      ),
      CoachMarkStep(
        title: 'Scanner',
        description:
            'Quickly find books by scanning their QR codes or generating codes for your books.',
        icon: Icons.qr_code_scanner,
        targetKey: 'scanner_tab',
      ),
    ]);
  }

  Future<void> _checkAndShowOnboarding() async {
    final settings = DatabaseService.settings;
    final completedOnboarding =
        settings['completedOnboarding'] as bool? ?? false;

    if (!completedOnboarding && mounted) {
      setState(() {
        _showCoachMark = true;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _skipOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Tutorial?'),
        content: const Text(
          'You can restart the tutorial anytime from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Tutorial'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeOnboarding();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    DatabaseService.settings['completedOnboarding'] = true;
    await DatabaseService.save();
    if (mounted) {
      setState(() {
        _showCoachMark = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [widget.child, if (_showCoachMark) _buildCoachMarkOverlay()],
    );
  }

  Widget _buildCoachMarkOverlay() {
    final step = _steps[_currentStep];

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Stack(
          children: [
            // Tap to dismiss hint
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _skipOnboarding,
              ),
            ),

            // Coach mark content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          step.icon,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Progress indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _steps.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentStep
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).disabledColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Navigation buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentStep > 0)
                              TextButton(
                                onPressed: _previousStep,
                                child: const Text('Previous'),
                              )
                            else
                              const SizedBox.shrink(),

                            Text(
                              '${_currentStep + 1} / ${_steps.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),

                            ElevatedButton(
                              onPressed: _nextStep,
                              child: Text(
                                _currentStep == _steps.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoachMarkStep {
  final String title;
  final String description;
  final IconData icon;
  final String targetKey;

  CoachMarkStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.targetKey,
  });
}

/// Service to manage onboarding state
class OnboardingService extends ChangeNotifier {
  bool _completedOnboarding = false;

  OnboardingService() {
    _loadState();
  }

  bool get completedOnboarding => _completedOnboarding;

  Future<void> _loadState() async {
    _completedOnboarding =
        DatabaseService.settings['completedOnboarding'] as bool? ?? false;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    DatabaseService.settings['completedOnboarding'] = false;
    await DatabaseService.save();
    _completedOnboarding = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    DatabaseService.settings['completedOnboarding'] = true;
    await DatabaseService.save();
    _completedOnboarding = true;
    notifyListeners();
  }
}
