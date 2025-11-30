import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

/// Screen for customizing app theme colors
class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() =>
      _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  void _showColorPicker({
    required String title,
    required Color currentColor,
    required Function(Color) onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Customization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Theme'),
                  content: const Text(
                    'Reset all theme colors to default values?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                final themeService = context.read<CustomThemeService>();
                final messenger = ScaffoldMessenger.of(context);
                await themeService.resetToDefaults();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Theme reset to defaults')),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<CustomThemeService>(
        builder: (context, themeService, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Custom Colors',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Customize your app\'s color scheme',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Primary Color
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: themeService.primaryColor,
                  ),
                  title: const Text('Primary Color'),
                  subtitle: const Text('Main accent color throughout the app'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showColorPicker(
                    title: 'Choose Primary Color',
                    currentColor: themeService.primaryColor,
                    onColorChanged: (color) =>
                        themeService.setPrimaryColor(color),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Color
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: themeService.secondaryColor,
                  ),
                  title: const Text('Secondary Color'),
                  subtitle: const Text('Supporting accent color'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showColorPicker(
                    title: 'Choose Secondary Color',
                    currentColor: themeService.secondaryColor,
                    onColorChanged: (color) =>
                        themeService.setSecondaryColor(color),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Theme Presets
              const Text(
                'Theme Presets',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ...CustomThemeService.presets.map((preset) {
                final isCurrentTheme =
                    preset.primary.toARGB32() ==
                        themeService.primaryColor.toARGB32() &&
                    preset.secondary.toARGB32() ==
                        themeService.secondaryColor.toARGB32();

                return Card(
                  color: isCurrentTheme
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: preset.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: preset.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                    title: Text(preset.name),
                    trailing: isCurrentTheme
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.arrow_forward),
                    onTap: () async {
                      final themeService = context.read<CustomThemeService>();
                      final messenger = ScaffoldMessenger.of(context);
                      await themeService.applyPreset(preset);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('${preset.name} theme applied')),
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Preview
              InfoCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.palette, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color Preview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Colors will be applied immediately. '
                            'Restart the app if you notice any issues.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
