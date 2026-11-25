import 'package:flutter/material.dart';

import 'api_client.dart';

/// "Is this really my bank?" Verified official numbers, SMS sender names and websites.
class OfficialDirectoryScreen extends StatefulWidget {
  const OfficialDirectoryScreen({super.key});

  @override
  State<OfficialDirectoryScreen> createState() => _OfficialDirectoryScreenState();
}

class _OfficialDirectoryScreenState extends State<OfficialDirectoryScreen> {
  final _check = TextEditingController();
  final _search = TextEditingController();
  Map<String, dynamic>? _checkResult;
  List<Map> _orgs = [];
  String? _note;
  bool _checking = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void dispose() {
    _check.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory([String? q]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/directory', query: {if (q != null && q.isNotEmpty) 'q': q}) as Map;
      setState(() {
        _orgs = (data['organisations'] as List).cast<Map>();
        _note = '${data['note']}';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runCheck() async {
    final v = _check.text.trim();
    if (v.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _checking = true;
      _checkResult = null;
    });
    try {
      final data = await ApiClient.get('/directory/check', query: {'value': v});
      setState(() => _checkResult = Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'phone':
        return Icons.phone;
      case 'whatsapp':
        return Icons.chat;
      case 'sms_sender':
        return Icons.sms;
      case 'website':
        return Icons.language;
      case 'email':
        return Icons.email;
      case 'ussd':
        return Icons.dialpad;
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _checkResult;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Official Contacts')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Is this really my bank?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Check a phone number, SMS sender name (e.g. GTBank), website or email.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: _check,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runCheck(),
            decoration: InputDecoration(
              hintText: 'e.g. 0700..., GTBank, gtbank-secure.com',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _checking
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(icon: const Icon(Icons.search), onPressed: _runCheck),
            ),
          ),
          if (r != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (r['official'] == true ? const Color(0xFF008751) : const Color(0xFFE97C00))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(r['official'] == true ? Icons.verified : Icons.help_outline,
                      color: r['official'] == true ? const Color(0xFF008751) : const Color(0xFFE97C00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r['official'] == true ? 'Official' : 'Not in our verified list',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text('${r['verdict']}', style: const TextStyle(height: 1.4)),
                const SizedBox(height: 6),
                Text('${r['note']}', style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.4)),
              ]),
            ),
          const SizedBox(height: 24),
          const Text('Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            onChanged: (v) => _loadDirectory(v.trim()),
            decoration: InputDecoration(
              hintText: 'Search organisation',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
          if (!_loading && _orgs.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No verified contacts yet. Our team is adding them.', style: TextStyle(color: Colors.grey)),
            ),
          ..._orgs.map((o) => Card(
                child: ExpansionTile(
                  title: Text('${o['org_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${o['org_type']}'),
                  children: ((o['contacts'] as List).cast<Map>())
                      .map((c) => ListTile(
                            dense: true,
                            leading: Icon(_icon('${c['kind']}')),
                            title: SelectableText('${c['value']}'),
                            subtitle: c['notes'] != null ? Text('${c['notes']}') : null,
                          ))
                      .toList(),
                ),
              )),
          if (_note != null) ...[
            const SizedBox(height: 12),
            Text(_note!, style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
