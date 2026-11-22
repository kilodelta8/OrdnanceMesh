import 'package:flutter/material.dart';
import '../services/relay_api.dart';

class PortalScreen extends StatefulWidget {
  final RelayApiClient api;
  const PortalScreen({super.key, required this.api});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  void _setBase(String url) {
    setState(() => widget.api.baseUrl = url);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Relay set to $url')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('OrdnanceBox Connection Path', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'http://10.88.0.1:8081', label: Text('Wi-Fi AP (.0.1)')),
            ButtonSegment(value: 'http://10.88.1.1:8081', label: Text('Wired LAN (.1.1)')),
          ],
          selected: {widget.api.baseUrl},
          onSelectionChanged: (s) => _setBase(s.first),
        ),
        const SizedBox(height: 20),
        const Card(
          child: ListTile(
            leading: Icon(Icons.map),
            title: Text('OpenTAKServer WebUI'),
            subtitle: Text('https://10.88.0.1:8443  (CoT SSL :8089)'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.menu_book),
            title: Text('Project NOMAD Knowledge Portal'),
            subtitle: Text('http://10.88.0.1  (Offline Wikipedia, Maps & AI)'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.headset_mic),
            title: Text('Local Mumble VoIP Server'),
            subtitle: Text('10.88.0.1:64738  (LAN / IP MANET PTT)'),
          ),
        ),
      ],
    );
  }
}