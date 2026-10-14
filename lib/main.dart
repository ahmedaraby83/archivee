import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lock_screen.dart';
import 'services/auth_service.dart';

void main() => runApp(const ArchiveeApp());

class ArchiveeApp extends StatefulWidget {
  const ArchiveeApp({super.key});
  @override
  State<ArchiveeApp> createState() => _ArchiveeAppState();
}

class _ArchiveeAppState extends State<ArchiveeApp> {
  int _tab = 0;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    if (await AuthService.hasPin()) setState(() => _locked = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أرشيفي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey, brightness: Brightness.dark),
      home: _locked
        ? LockScreen(onUnlocked: () => setState(() => _locked = false))
        : Scaffold(
            body: [const HomeScreen(), const SettingsScreen()][_tab],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'الرئيسية'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'الإعدادات'),
              ],
            ),
          ),
    );
  }
}