import 'package:flutter/material.dart';

import 'alerts_screen.dart';
import 'api_client.dart';

/// Scams going round right now (written by moderators) and what scans show this week.
class ScamWarningsScreen extends StatefulWidget {
  const ScamWarningsScreen({super.key});

  @override
  State<ScamWarningsScreen> createState() => _ScamWarningsScreenState();
}

Color severityColor(String? s) => s == 'danger'
    ? const Color(0xFFD62828)
    : s == 'info'
        ? const Color(0xFF1B4965)
        : const Color(0xFFE97C00);

class _ScamWarningsScreenState extends State<ScamWarningsScreen> {
  List<Map> _alerts = [];
  List<Map> _trending = [];
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
      final data = await ApiClient.get('/scam-alerts') as Map;
      setState(() {
        _alerts = (data['alerts'] as List).cast<Map>();
        _trending = (data['trending'] as List).cast<Map>();
      });
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
      appBar: AppBar(title: const Text('Scam Warnings')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
            if (!_loading && _alerts.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No special warnings right now. Stay careful.', style: TextStyle(color: Colors.grey)),
              ),
            ..._alerts.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(left: BorderSide(color: severityColor(a['severity'] as String?), width: 5)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${a['title']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${a['body']}', style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 6),
                    Text('${a['created_at']}'.substring(0, 10), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                )),
            if (_trending.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Most common scams in scans this week',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._trending.map((t) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.trending_up, color: Color(0xFFD62828)),
                      title: Text('${t['category']}'),
                      subtitle: Text('${t['flagged_this_week']} flagged this week'
                          '${t['change_percent'] != null ? ' (${t['change_percent']}% vs last week)' : ''}'),
                    ),
                  )),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('See high-risk numbers'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
