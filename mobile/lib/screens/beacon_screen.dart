import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/relay_api.dart';

class BeaconScreen extends StatefulWidget {
  final RelayApiClient api;
  const BeaconScreen({super.key, required this.api});

  @override
  State<BeaconScreen> createState() => _BeaconScreenState();
}

class _BeaconScreenState extends State<BeaconScreen> {
  final _callsignCtrl = TextEditingController(text: 'ALPHA1');
  final _pinCtrl = TextEditingController(text: 'RALLY1');
  bool _sending = false;
  String _lastResult = 'Ready';

  @override
  void dispose() {
    _callsignCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<Position> _getFix() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _send(String type) async {
    setState(() {
      _sending = true;
      _lastResult = 'Acquiring GPS fix...';
    });
    try {
      final pos = await _getFix();
      final label = type == 'PLI' ? _callsignCtrl.text.trim() : _pinCtrl.text.trim();
      final msg = await widget.api.sendBeacon(
        type: type,
        callsign: label,
        lat: pos.latitude,
        lon: pos.longitude,
        alt: pos.altitude,
      );
      if (!mounted) return;
      setState(() => _lastResult =
          '$msg\n(${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})');
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastResult = 'Error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _callsignCtrl,
          decoration: const InputDecoration(
            labelText: 'Operator Callsign (PLI)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: FilledButton.icon(
            onPressed: _sending ? null : () => _send('PLI'),
            icon: const Icon(Icons.my_location),
            label: const Text('SEND MY PLI TO ATAK', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _pinCtrl,
          decoration: const InputDecoration(
            labelText: 'Waypoint / Pin Label',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: OutlinedButton.icon(
            onPressed: _sending ? null : () => _send('PIN'),
            icon: const Icon(Icons.push_pin),
            label: const Text('DROP TACTICAL PIN', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_lastResult),
          ),
        ),
      ],
    );
  }
}