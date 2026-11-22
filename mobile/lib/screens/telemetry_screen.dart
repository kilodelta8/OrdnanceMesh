import 'dart:async';
import 'package:flutter/material.dart';
import '../services/relay_api.dart';

class TelemetryScreen extends StatefulWidget {
  final RelayApiClient api;
  const TelemetryScreen({super.key, required this.api});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  RelayStatus? _status;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final s = await widget.api.fetchStatus();
      if (!mounted) return;
      setState(() {
        _status = s;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Widget _tile(String label, String value, bool ok) {
    return Card(
      child: ListTile(
        leading: Icon(ok ? Icons.check_circle : Icons.error,
            color: ok ? Colors.greenAccent : Colors.redAccent),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _status == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text('OrdnanceBox unreachable at ${widget.api.baseUrl}\n$_error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final s = _status;
    if (s == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _tile('RPi 5 CPU Temp', '${s.cpuTempC} °C', s.cpuTempC > 0 && s.cpuTempC < 75),
          _tile('Throttle / Voltage', s.throttledHex, s.throttledHex == '0x0'),
          _tile('Starlink Mini WAN', s.wanState, s.wanState == 'ONLINE'),
          _tile('Dual-Mesh Bridge (AMMB)', s.bridgeActive ? 'ACTIVE' : 'DOWN', s.bridgeActive),
          _tile('MeshCore-to-CoT Bridge', s.cotBridgeActive ? 'ACTIVE' : 'DOWN', s.cotBridgeActive),
          _tile('Meshtastic USB Radio', s.meshtasticUsb ? 'LINKED' : 'MISSING', s.meshtasticUsb),
          _tile('MeshCore USB Radio', s.meshcoreUsb ? 'LINKED' : 'MISSING', s.meshcoreUsb),
        ],
      ),
    );
  }
}