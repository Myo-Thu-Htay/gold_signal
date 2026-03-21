import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/core/constants/app_strings.dart';
import '../provider/setting_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingAsync = ref.watch(settingsProvider);

    return settingAsync.when(data: (setting) {
      final notifier = ref.read(settingsProvider.notifier);
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.text('settings', setting.languageCode)),
          centerTitle: true,
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: Text(AppStrings.text('darkMode', setting.languageCode)),
              value: setting.isDarkMode,
              onChanged: (value) => notifier.toggleDarkMode(value),
            ),
            ListTile(
              title: Text(AppStrings.text('language', setting.languageCode)),
              trailing: DropdownButton<String>(
                value: setting.languageCode,
                style: TextStyle(color: Colors.grey[400]),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'my', child: Text('Myanmar')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    notifier.changeLanguage(value);
                  }
                },
              ),
            ),
            SwitchListTile(
              title:
                  Text(AppStrings.text('notifications', setting.languageCode)),
              value: setting.notificationsEnabled,
              onChanged: (value) => {
                notifier.toggleNotifications(context, value),
              },
            ),
          ],
        ),
      );
    }, error: (error, stackTrace) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text('Error loading settings: $error'),
        ),
      );
    }, loading: () {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    });
  }
}
