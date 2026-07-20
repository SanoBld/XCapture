import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../core/localization/l10n_provider.dart';

// Prompts user for their OpenXBL API key (free, from xbl.io)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _errorKey;

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _errorKey = null;
    });
    try {
      final ok = await context.read<AuthProvider>().login(_controller.text.trim());
      if (!ok && mounted) setState(() => _errorKey = 'invalid_key');
    } catch (_) {
      if (mounted) setState(() => _errorKey = 'connection_error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<L10nProvider>();
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DropdownButton<String>(
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
            ),
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.videogame_asset_rounded,
                            size: 64, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(l10n.t('app_name'), style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(l10n.t('login_subtitle')),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: l10n.t('api_key_label'),
                            errorText: _errorKey != null ? l10n.t(_errorKey!) : null,
                          ),
                          obscureText: true,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20, child: CircularProgressIndicator())
                              : Text(l10n.t('connect')),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => launchUrl(Uri.parse('https://xbl.io')),
                          child: Text(l10n.t('get_free_key')),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(l10n.t('how_to_get_key'),
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
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
