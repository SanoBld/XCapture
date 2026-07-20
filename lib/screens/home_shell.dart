import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/capture.dart';
import '../core/localization/l10n_provider.dart';
import 'capture_gallery_page.dart';
import 'settings_page.dart';

// Root shell holding the 3 main tabs: Screenshots, Clips, Settings
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    CaptureGalleryPage(type: CaptureType.screenshot),
    CaptureGalleryPage(type: CaptureType.clip),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<L10nProvider>();
    final titles = [l10n.t('screenshots'), l10n.t('clips'), l10n.t('settings')];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.image_outlined),
              selectedIcon: const Icon(Icons.image),
              label: titles[0]),
          NavigationDestination(
              icon: const Icon(Icons.videocam_outlined),
              selectedIcon: const Icon(Icons.videocam),
              label: titles[1]),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: titles[2]),
        ],
      ),
    );
  }
}
