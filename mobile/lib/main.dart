import 'package:flutter/material.dart';
import 'services/relay_api.dart';
import 'screens/chat_screen.dart';
import 'screens/telemetry_screen.dart';
import 'screens/beacon_screen.dart';
import 'screens/portal_screen.dart';

void main() => runApp(const OrdnanceMeshApp());

class OrdnanceMeshApp extends StatefulWidget {
  const OrdnanceMeshApp({super.key});

  @override
  State<OrdnanceMeshApp> createState() => _OrdnanceMeshAppState();
}

class _OrdnanceMeshAppState extends State<OrdnanceMeshApp> {
  final _api = RelayApiClient();
  late final List<Widget> _screens;
  int _tab = 0;
  bool _nightVision = false;

  @override
  void initState() {
    super.initState();
    _screens = [
      ChatScreen(api: _api),
      TelemetryScreen(api: _api),
      BeaconScreen(api: _api),
      PortalScreen(api: _api),
    ];
  }

  ThemeData _buildTheme() {
    if (_nightVision) {
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB71C1C),
          secondary: Color(0xFFD32F2F),
          surface: Color(0xFF160404),
          onSurface: Color(0xFFFF6659),
        ),
      );
    }
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E5A4C),
        brightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrdnanceMesh',
      theme: _buildTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OrdnanceMesh'),
          actions: [
            IconButton(
              tooltip: 'Toggle Red-Light Night Mode',
              icon: Icon(_nightVision ? Icons.nights_stay : Icons.visibility),
              onPressed: () => setState(() => _nightVision = !_nightVision),
            ),
          ],
        ),
        body: IndexedStack(index: _tab, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.forum), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.sensors), label: 'Relay'),
            NavigationDestination(icon: Icon(Icons.my_location), label: 'Beacons'),
            NavigationDestination(icon: Icon(Icons.hub), label: 'Portal'),
          ],
        ),
      ),
    );
  }
}