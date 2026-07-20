import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../core/localization/l10n_provider.dart';

// App settings: theme, language, accent, grid density, account, about
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _accentOptions = [
    Color(0xFF107C10), // Xbox green
    Color(0xFF6750A4), // Purple
    Color(0xFF1E88E5), // Blue
    Color(0xFFE53935), // Red
    Color(0xFFFB8C00), // Orange
    Color(0xFF00897B), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = context.watch<L10nProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(l10n.t('appearance')),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.t('theme')),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.t('system'))),
                    DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.t('light'))),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.t('dark'))),
                  ],
                  onChanged: (v) => v != null ? settings.setThemeMode(v) : null,
                ),
              ),
              ListTile(
                title: Text(l10n.t('language')),
                trailing: DropdownButton<String>(
                  value: settings.languageCode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    await settings.setLanguageCode(v);
                    if (context.mounted) await context.read<L10nProvider>().load(v);
                  },
                ),
              ),
              SwitchListTile(
                title: Text(l10n.t('dynamic_color')),
                subtitle: Text(l10n.t('dynamic_color_sub')),
                value: settings.useDynamicColor,
                onChanged: settings.setDynamicColor,
              ),
              if (!settings.useDynamicColor)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.t('accent_color'))),
                      for (final color in _accentOptions)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: () => settings.setAccentColor(color),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: color,
                              child: settings.accentColor.toARGB32() == color.toARGB32()
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ListTile(
                title: Text(l10n.t('startup_tab')),
                trailing: DropdownButton<int>(
                  value: settings.startupTab,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 0, child: Text(l10n.t('screenshots'))),
                    DropdownMenuItem(value: 1, child: Text(l10n.t('clips'))),
                    DropdownMenuItem(value: 2, child: Text(l10n.t('settings'))),
                  ],
                  onChanged: (v) => v != null ? settings.setStartupTab(v) : null,
                ),
              ),
              ListTile(
                title: Text(l10n.t('tile_info')),
                trailing: DropdownButton<TileInfo>(
                  value: settings.tileInfo,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: TileInfo.none, child: Text(l10n.t('info_none'))),
                    DropdownMenuItem(value: TileInfo.title, child: Text(l10n.t('info_title'))),
                    DropdownMenuItem(
                        value: TileInfo.titleAndDate, child: Text(l10n.t('info_title_date'))),
                  ],
                  onChanged: (v) => v != null ? settings.setTileInfo(v) : null,
                ),
              ),
              ListTile(
                title: Text(l10n.t('grid_columns')),
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
        _SectionTitle(l10n.t('account')),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: Text(l10n.t('disconnect')),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(l10n.t('about')),
        Card(
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              return ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('XCapture'),
                subtitle: Text('${l10n.t('version')} $version · OpenXBL'),
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
