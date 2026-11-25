import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'account_check_screen.dart';
import 'api_client.dart';
import 'report_screen.dart';

/// "I've been scammed, what now?"
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  List<Map> _situations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/recovery');
      setState(() => _situations = ((data as Map)['situations'] as List).cast<Map>());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text("I've Been Scammed")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD62828).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'If you sent money, call your bank NOW using the number on your card or in your bank app. '
              'The faster the bank flags the receiving account, the better the chance of stopping the money.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text('What happened?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
          ..._situations.map((s) => Card(
                child: ListTile(
                  title: Text('${s['title']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecoveryPlanScreen(situation: '${s['situation']}')),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class RecoveryPlanScreen extends StatefulWidget {
  final String situation;
  const RecoveryPlanScreen({super.key, required this.situation});

  @override
  State<RecoveryPlanScreen> createState() => _RecoveryPlanScreenState();
}

class _RecoveryPlanScreenState extends State<RecoveryPlanScreen> {
  Map? _plan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.get('/recovery/${widget.situation}');
      setState(() => _plan = data as Map);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('What to do now')),
      body: plan == null
          ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('${plan['title']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...((plan['steps'] as List).asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF008751),
                            child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${e.value}', style: const TextStyle(height: 1.4))),
                        ],
                      ),
                    ))),
                const SizedBox(height: 8),
                if (widget.situation == 'bank_transfer') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_document),
                    label: const Text('Write my complaint letter'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF1B4965),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentLetterScreen())),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.account_balance),
                    label: const Text("Report the scammer's account"),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountCheckScreen())),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text("Report the scammer's phone number"),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
                ),
                const SizedBox(height: 24),
                const Text('Where to report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...((plan['contacts'] as List).cast<Map>().map((c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(c['verified'] == true ? Icons.verified : Icons.info_outline,
                          color: c['verified'] == true ? const Color(0xFF008751) : Colors.grey),
                      title: Text('${c['name']}'),
                      subtitle: Text('${c['how']}'),
                    ))),
                const SizedBox(height: 12),
                Text('${plan['disclaimer']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
    );
  }
}

/// Generates a complaint letter to the victim's bank or the police. Nothing is stored on the server.
class IncidentLetterScreen extends StatefulWidget {
  const IncidentLetterScreen({super.key});

  @override
  State<IncidentLetterScreen> createState() => _IncidentLetterScreenState();
}

class _IncidentLetterScreenState extends State<IncidentLetterScreen> {
  final Map<String, TextEditingController> _c = {
    for (final k in [
      'victim_name',
      'victim_phone',
      'victim_address',
      'victim_bank',
      'victim_account',
      'incident_date',
      'incident_time',
      'amount',
      'scammer_account',
      'scammer_bank',
      'scammer_account_name',
      'scammer_phone',
      'transaction_ref',
      'description',
    ])
      k: TextEditingController()
  };
  String _recipient = 'bank';
  bool _sending = false;
  String? _error;

  static const _labels = {
    'victim_name': 'Your full name',
    'victim_phone': 'Your phone number',
    'victim_address': 'Your address',
    'victim_bank': 'Your bank',
    'victim_account': 'Your account number',
    'incident_date': 'Date of transfer (e.g. 12 March 2026)',
    'incident_time': 'Time of transfer',
    'amount': 'Amount (e.g. N50,000)',
    'scammer_account': "Scammer's account number",
    'scammer_bank': "Scammer's bank",
    'scammer_account_name': 'Account name shown on the transfer',
    'scammer_phone': "Scammer's phone number(s)",
    'transaction_ref': 'Transaction reference / session ID',
    'description': 'What happened (short)',
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{'recipient': _recipient};
      _c.forEach((k, v) {
        if (v.text.trim().isNotEmpty) body[k] = v.text.trim();
      });
      final data = await ApiClient.post('/recovery/letter', body: body) as Map;
      if (!mounted) return;
      final letter = '${data['letter']}';
      final footer = '\n\n---\nCreated ${data['created_at_utc']}\nFingerprint (SHA-256): ${data['sha256']}';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your letter'),
          content: SingleChildScrollView(child: SelectableText(letter)),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: letter));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Letter copied')));
              },
              child: const Text('Copy'),
            ),
            TextButton(onPressed: () => Share.share(letter + footer), child: const Text('Share')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint letter')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Fill in what you know. Anything you leave empty appears in [brackets] for you to fill in later. '
            'The letter is not saved on our server.',
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'bank', label: Text('To my bank')),
              ButtonSegment(value: 'police', label: Text('To the police')),
            ],
            selected: {_recipient},
            onSelectionChanged: (s) => setState(() => _recipient = s.first),
          ),
          const SizedBox(height: 12),
          ..._c.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: e.value,
                  maxLines: e.key == 'description' ? 4 : 1,
                  decoration: InputDecoration(labelText: _labels[e.key], border: const OutlineInputBorder()),
                ),
              )),
          if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _sending ? null : _generate,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFF008751),
              foregroundColor: Colors.white,
            ),
            child: Text(_sending ? 'Creating...' : 'Create letter'),
          ),
        ],
      ),
    );
  }
}
