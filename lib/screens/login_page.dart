import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

// Prompts user for their OpenXBL API key (free, from xbl.io)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _errorText;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    final ok = await context.read<AuthProvider>().login(_controller.text.trim());
    setState(() => _loading = false);
    if (!ok && mounted) {
      setState(() => _errorText = 'Invalid API key');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                  Text('XCapture', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Enter your free OpenXBL API key to view your captures.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'API key',
                      errorText: _errorText,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator())
                        : const Text('Connect'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://xbl.io')),
                    child: const Text('Get a free key on xbl.io'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
