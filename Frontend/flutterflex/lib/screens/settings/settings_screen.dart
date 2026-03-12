import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _syncSettings(BuildContext context) async {
    final success = await context.read<AuthProvider>().syncPreferences();
    if (!context.mounted || success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<AuthProvider>().errorMessage ??
              'Einstellungen konnten nicht gespeichert werden.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appSettings = context.watch<AppSettingsProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        user.username.isEmpty
                            ? '?'
                            : user.username[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(user.email),
                          const SizedBox(height: 4),
                          Text(
                            'Mitglied seit ${DateFormat('MM.yyyy').format(user.createdAt)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Darstellung',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark Mode'),
                    subtitle: const Text(
                      'Premium-Look fuer Abendtraining und Fokus',
                    ),
                    value: appSettings.isDarkMode,
                    onChanged: (value) async {
                      await appSettings.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      await _syncSettings(context);
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Farbenblindmodus'),
                    subtitle: const Text(
                      'Nutze kontrastreichere, farbenblindheitsfreundliche Akzentfarben.',
                    ),
                    value: appSettings.isColorBlindMode,
                    onChanged: (value) {
                      appSettings.setColorBlindMode(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppThemeOption.values.map((themeOption) {
                      return ChoiceChip(
                        label: Text(_themeLabel(themeOption)),
                        selected: themeOption == appSettings.selectedTheme,
                        onSelected: (_) async {
                          await appSettings.setTheme(themeOption);
                          if (!context.mounted) {
                            return;
                          }
                          await _syncSettings(context);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Einheiten',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<WeightUnit>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                      ButtonSegment(value: WeightUnit.lbs, label: Text('lbs')),
                    ],
                    selected: {appSettings.selectedUnit},
                    onSelectionChanged: (selection) async {
                      await appSettings.setWeightUnit(selection.first);
                      if (!context.mounted) {
                        return;
                      }
                      await _syncSettings(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppThemeOption option) {
    return switch (option) {
      AppThemeOption.ocean => 'Ocean',
      AppThemeOption.forest => 'Forest',
      AppThemeOption.sunset => 'Sunset',
      AppThemeOption.ruby => 'Ruby',
      AppThemeOption.slate => 'Slate',
    };
  }
}
