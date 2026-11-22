import 'dart:convert';
import 'package:http/http.dart' as http;

class RelayStatus {
  final String timestampUtc;
  final double cpuTempC;
  final String throttledHex;
  final String wanState;
  final bool bridgeActive;
  final bool cotBridgeActive;
  final bool meshtasticUsb;
  final bool meshcoreUsb;

  RelayStatus({
    required this.timestampUtc,
    required this.cpuTempC,
    required this.throttledHex,
    required this.wanState,
    required this.bridgeActive,
    required this.cotBridgeActive,
    required this.meshtasticUsb,
    required this.meshcoreUsb,
  });

  factory RelayStatus.fromJson(Map<String, dynamic> j) => RelayStatus(
        timestampUtc: (j['timestamp_utc'] ?? '').toString(),
        cpuTempC: (j['cpu_temp_c'] as num?)?.toDouble() ?? -1.0,
        throttledHex: (j['throttled_hex'] ?? 'unknown').toString(),
        wanState: (j['wan_state'] ?? 'UNKNOWN').toString(),
        bridgeActive: j['bridge_active'] == true,
        cotBridgeActive: j['cot_bridge_active'] == true,
        meshtasticUsb: j['meshtastic_usb'] == true,
        meshcoreUsb: j['meshcore_usb'] == true,
      );
}

class ChatMessage {
  final int id;
  final String ts;
  final String net;
  final String sender;
  final String text;

  ChatMessage({
    required this.id,
    required this.ts,
    required this.net,
    required this.sender,
    required this.text,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] as num?)?.toInt() ?? 0,
        ts: (j['ts'] ?? '').toString(),
        net: (j['net'] ?? 'APP').toString(),
        sender: (j['sender'] ?? 'OPS').toString(),
        text: (j['text'] ?? '').toString(),
      );
}

class RelayApiClient {
  String baseUrl;
  RelayApiClient({this.baseUrl = 'http://10.88.0.1:8081'});

  Future<RelayStatus> fetchStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/v1/status'))
        .timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return RelayStatus.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> fetchMessages() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/v1/messages'))
        .timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final list = (jsonDecode(res.body)['messages'] as List<dynamic>? ?? []);
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage({required String sender, required String text}) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/v1/messages'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'sender': sender, 'text': text}),
        )
        .timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) throw Exception('Send failed (${res.statusCode})');
  }

  Future<String> sendBeacon({
    required String type,
    required String callsign,
    required double lat,
    required double lon,
    double alt = 0.0,
    String? cotType,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/v1/beacon'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'type': type,
            'callsign': callsign,
            'lat': lat,
            'lon': lon,
            'alt': alt,
            if (cotType != null && cotType.isNotEmpty) 'cot_type': cotType,
          }),
        )
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception('Beacon failed (${res.statusCode})');
    return '$type "$callsign" injected into OpenTAKServer';
  }
}