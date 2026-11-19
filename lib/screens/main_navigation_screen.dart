import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/downloader_provider.dart';
import 'downloads_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final historyCount = context.watch<DownloaderProvider>().history.length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          DownloadsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: historyCount > 0
                ? Badge.count(
                    count: historyCount,
                    child: const Icon(Icons.download_done_rounded),
                  )
                : const Icon(Icons.download_done_rounded),
            selectedIcon: historyCount > 0
                ? Badge.count(
                    count: historyCount,
                    child: const Icon(Icons.download_done_rounded),
                  )
                : const Icon(Icons.download_done_rounded),
            label: 'Downloads',
          ),
        ],
      ),
    );
  }
}
