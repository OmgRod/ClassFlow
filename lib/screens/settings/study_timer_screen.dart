import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';

/// Screen for study timer with Pomodoro technique
class StudyTimerScreen extends StatefulWidget {
  final int? subjectId;

  const StudyTimerScreen({super.key, this.subjectId});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  late StudyTimerService _timerService;

  @override
  void initState() {
    super.initState();
    _timerService = StudyTimerService(subjectId: widget.subjectId);
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _timerService,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Timer'),
          actions: [
            PopupMenuButton<TimerMode>(
              icon: const Icon(Icons.settings),
              onSelected: (mode) => _timerService.setMode(mode),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: TimerMode.pomodoro,
                  child: Text('Pomodoro (25/5)'),
                ),
                const PopupMenuItem(
                  value: TimerMode.custom,
                  child: Text('Custom Duration'),
                ),
                const PopupMenuItem(
                  value: TimerMode.stopwatch,
                  child: Text('Stopwatch'),
                ),
              ],
            ),
          ],
        ),
        body: Consumer<StudyTimerService>(
          builder: (context, timer, child) {
            return Column(
              children: [
                // Subject selector
                _buildSubjectSelector(timer),

                const SizedBox(height: 32),

                // Timer display
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mode indicator
                        Text(
                          timer.isBreak ? 'Break Time' : 'Study Session',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),

                        // Circular progress
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 280,
                                height: 280,
                                child: CircularProgressIndicator(
                                  value: timer.progress,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    timer.formattedRemaining,
                                    style: const TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Remaining',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Session counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Session ${timer.completedSessions + 1} • ${timer.completedSessions} completed',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controls
                _buildControls(timer),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(StudyTimerService timer) {
    return Consumer<SubjectService>(
      builder: (context, subjectService, child) {
        final subjects = subjectService.subjects;
        final currentSubject = subjects
            .where((s) => s.id == timer.subjectId)
            .firstOrNull;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.subject,
                color: currentSubject != null
                    ? Color(currentSubject.displayColor)
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: timer.subjectId == 0 ? null : timer.subjectId,
                  hint: const Text('Select Subject'),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.name),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) timer.setSubject(id);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(StudyTimerService timer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reset
          IconButton(
            onPressed: timer.isRunning ? null : timer.reset,
            icon: const Icon(Icons.refresh),
            iconSize: 32,
            tooltip: 'Reset',
          ),

          // Skip
          IconButton(
            onPressed: timer.isRunning ? timer.skip : null,
            icon: const Icon(Icons.skip_next),
            iconSize: 32,
            tooltip: 'Skip',
          ),

          // Play/Pause
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: timer.isRunning ? timer.pause : timer.start,
              icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
              iconSize: 48,
              color: Theme.of(context).colorScheme.onPrimary,
              tooltip: timer.isRunning ? 'Pause' : 'Start',
            ),
          ),
        ],
      ),
    );
  }
}
