import 'package:flutter/material.dart';
import 'empty_state.dart';

/// A reusable platform-unsupported message widget
class PlatformUnsupportedMessage extends StatelessWidget {
  final String feature;
  final String alternative;

  const PlatformUnsupportedMessage({
    required this.feature,
    required this.alternative,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(feature),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          icon: Icons.desktop_access_disabled,
          title: '$feature Not Available',
          subtitle: 'This feature is currently only available on mobile devices (Android & iOS).\n\n$alternative',
        ),
      ),
    );
  }
}
