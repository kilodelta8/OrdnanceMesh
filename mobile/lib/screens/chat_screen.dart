import 'dart:async';
import 'package:flutter/material.dart';
import '../services/relay_api.dart';

class ChatScreen extends StatefulWidget {
  final RelayApiClient api;
  const ChatScreen({super.key, required this.api});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _senderCtrl = TextEditingController(text: 'ALPHA1');
  List<ChatMessage> _messages = [];
  String _filter = 'ALL';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _senderCtrl.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final msgs = await widget.api.fetchMessages();
      if (mounted) setState(() => _messages = msgs.reversed.toList());
    } catch (_) {}
  }

  Future<void> _send([String? quickText]) async {
    final text = (quickText ?? _msgCtrl.text).trim();
    if (text.isEmpty) return;
    if (quickText == null) _msgCtrl.clear();
    try {
      await widget.api.sendMessage(sender: _senderCtrl.text.trim(), text: text);
      await _poll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _badgeColor(String net) {
    if (net == 'MT') return Colors.teal;
    if (net == 'MC') return Colors.amber.shade800;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter == 'ALL'
        ? _messages
        : _messages.where((m) => m.net == _filter).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              for (final f in const ['ALL', 'MT', 'MC', 'APP'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No bridged messages yet'))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final m = visible[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _badgeColor(m.net),
                          child: Text(
                            m.net,
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                        title: Text(m.text),
                        subtitle: Text('${m.sender}  •  ${m.ts}'),
                      ),
                    );
                  },
                ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              for (final q in const ['ROGER', 'MOVING', 'SET', 'CHECK IN'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(label: Text(q), onPressed: () => _send(q)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Message Meshtastic + MeshCore...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
            ],
          ),
        ),
      ],
    );
  }
}