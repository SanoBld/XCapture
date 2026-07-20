import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

// App settings: theme, grid density, account, about
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Appearance'),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (v) => v != null ? settings.setThemeMode(v) : null,
                ),
              ),
              SwitchListTile(
                title: const Text('Dynamic color (Material You)'),
                subtitle: const Text('Use system wallpaper colors when available'),
                value: settings.useDynamicColor,
                onChanged: settings.setDynamicColor,
              ),
              ListTile(
                title: const Text('Grid columns'),
                trailing: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                    ButtonSegment(value: 4, label: Text('4')),
                  ],
                  selected: {settings.gridColumns},
                  onSelectionChanged: (s) => settings.setGridColumns(s.first),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Account'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Disconnect Xbox account'),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('About'),
        Card(
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              return ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('XCapture'),
                subtitle: Text('Version $version · powered by OpenXBL'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
