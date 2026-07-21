import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../core/localization/l10n_provider.dart';
import '../services/openxbl_service.dart';
import '../widgets/styled_dropdown.dart';

// App settings: theme, language, accent, startup tab, account, about
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('settings'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(l10n.t('appearance')),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.t('theme')),
                  trailing: StyledDropdown<ThemeMode>(
                    value: settings.themeMode,
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
                  trailing: StyledDropdown<String>(
                    value: settings.languageCode,
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
                ListTile(
                  title: Text(l10n.t('startup_tab')),
                  trailing: StyledDropdown<int>(
                    value: settings.startupTab,
                    items: [
                      DropdownMenuItem(value: 0, child: Text(l10n.t('screenshots'))),
                      DropdownMenuItem(value: 1, child: Text(l10n.t('clips'))),
                      DropdownMenuItem(value: 2, child: Text(l10n.t('settings'))),
                    ],
                    onChanged: (v) => v != null ? settings.setStartupTab(v) : null,
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: settings.accentColor.toARGB32() == color.toARGB32() ? 32 : 28,
                                height: settings.accentColor.toARGB32() == color.toARGB32() ? 32 : 28,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                child: settings.accentColor.toARGB32() == color.toARGB32()
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ),
                      ],
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
          const SizedBox(height: 24),
          _SectionTitle('Debug'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.image_search_rounded),
                  title: const Text('JSON captures'),
                  onTap: () => _showRawJson(context, isClip: false),
                ),
                ListTile(
                  leading: const Icon(Icons.video_settings_rounded),
                  title: const Text('JSON clips'),
                  onTap: () => _showRawJson(context, isClip: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRawJson(BuildContext context, {required bool isClip}) async {
    final service = context.read<AuthProvider>().service;
    if (service == null) return;
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(content: SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))),
    );
    String text;
    try {
      isClip ? await service.fetchClips() : await service.fetchScreenshots();
      text = OpenXblService.lastRawResponse;
    } catch (e) {
      text = 'Error: $e';
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isClip ? 'JSON clips' : 'JSON captures'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(child: SelectableText(text, style: const TextStyle(fontSize: 11))),
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            child: const Text('Copier'),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer')),
        ],
      ),
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
