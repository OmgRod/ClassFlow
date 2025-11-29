# Reusable Widget Components

This document describes the reusable widgets created to optimize code and reduce duplication across the app.

## Available Widgets

### 1. EmptyState

A centered widget showing an icon, title, optional subtitle, and optional action button.

**Usage:**

```dart
EmptyState(
  icon: Icons.subject_outlined,
  title: 'No subjects yet',
  subtitle: 'Tap + to add your first subject',
  action: ElevatedButton.icon(
    onPressed: () => doSomething(),
    icon: const Icon(Icons.add),
    label: const Text('Add Subject'),
  ),
)
```

### 2. InfoCard

A Card widget with consistent padding that can be tapped.

**Usage:**

```dart
InfoCard(
  padding: const EdgeInsets.all(16),
  onTap: () => handleTap(),
  child: Column(
    children: [Text('Content')],
  ),
)
```

### 3. IconTextRow

A row displaying an icon and text, commonly used for detail displays.

**Usage:**

```dart
IconTextRow(
  icon: Icons.calendar_today,
  text: 'Monday',
  iconColor: Colors.blue,
)
```

### 4. ColorAvatar

A circular or rounded container with colored background, showing text or icon.

**Usage:**

```dart
ColorAvatar(
  color: Colors.blue,
  text: 'M',
  size: 60,
  fontSize: 28,
  borderRadius: 12,
  borderWidth: 2,
)
```

### 5. ActionButtonsRow

A row of action buttons with consistent spacing.

**Usage:**

```dart
ActionButtonsRow(
  alignment: MainAxisAlignment.spaceEvenly,
  buttons: [
    ActionButtonData(
      icon: Icons.edit,
      label: 'Edit',
      onPressed: () => edit(),
      isPrimary: true,
    ),
    ActionButtonData(
      icon: Icons.delete,
      label: 'Delete',
      onPressed: () => delete(),
    ),
  ],
)
```

### 6. PlatformUnsupportedMessage

A full-screen message for features not available on current platform.

**Usage:**

```dart
PlatformUnsupportedMessage(
  feature: 'Scanner',
  alternative: 'Use the Books tab to browse manually.',
)
```

### 7. StatusBadge

A colored badge showing status with optional dropdown indicator.

**Usage:**

```dart
StatusBadge(
  label: 'Available',
  color: Colors.green,
  showDropdown: true,
  onTap: () => changeStatus(),
)
```

## Import

To use these widgets, import:

```dart
import '../../widgets/widgets.dart';
```
