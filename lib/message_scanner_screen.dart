import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'account_check_screen.dart';
import 'api_client.dart';
import 'config.dart';
import 'lookup_screen.dart';
import 'recovery_screen.dart';

class MessageScannerScreen extends StatefulWidget {
  final String? prefilledMessage;
  const MessageScannerScreen({super.key, this.prefilledMessage});

  @override
  State<MessageScannerScreen> createState() => _MessageScannerScreenState();
}

class _MessageScannerScreenState extends State<MessageScannerScreen> {
  final TextEditingController _messageController = TextEditingController();

  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledMessage != null) {
      _messageController.text = widget.prefilledMessage!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Paste a suspicious message or link to scan.';
        _result = null;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await ApiClient.post('/analyze', body: {
        'message': text,
        'channel': 'app',
      });
      setState(() => _result = Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _risk => (_result?['risk'] ?? '') as String;

  Color _riskColor() {
    switch (_risk) {
      case 'High':
        return const Color(0xFFD62828);
      case 'Medium':
        return const Color(0xFFE97C00);
      case 'Low':
        return const Color(0xFF008751);
      default:
        return Colors.grey;
    }
  }

  IconData _riskIcon() {
    switch (_risk) {
      case 'High':
        return Icons.dangerous;
      case 'Medium':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle;
    }
  }

  List<String> _list(String key) =>
      ((_result?[key] as List?) ?? const []).map((e) => e.toString()).toList();

  List<String> _indicator(String key) =>
      (((_result?['indicators'] as Map?)?[key] as List?) ?? const []).map((e) => e.toString()).toList();

  /// Report text uses the server's sanitised message, so one-time codes are masked.
  String _reportText() {
    final reasons = _list('reasons').map((r) => '• $r').join('\n');
    final advice = _list('advice').map((a) => '• $a').join('\n');
    final urls = _indicator('urls');
    return '''
PhishTriage Scan Report

Risk: $_risk (${_result?['score']}/100)
Type: ${_result?['category']}

Message:
${_result?['sanitized_message'] ?? ''}

Why it was flagged:
$reasons
${urls.isNotEmpty ? '\nLinks (made safe, do not open):\n${urls.join('\n')}\n' : ''}
What to do:
$advice

Checked with PhishTriage.''';
  }

  Future<void> _contactHelp() async {
    final message = Uri.encodeComponent('Hello, I need help with this:\n\n${_reportText()}');
    final phone = AppConfig.helpWhatsApp;
    final app = Uri.parse('whatsapp://send?phone=$phone&text=$message');
    if (await canLaunchUrl(app)) {
      await launchUrl(app, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse('https://wa.me/$phone?text=$message'), mode: LaunchMode.externalApplication);
    }
  }

  void _showReport() {
    final report = _reportText();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan report'),
        content: SingleChildScrollView(child: SelectableText(report)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied')));
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Share.share(report), child: const Text('Share')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _button(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _section(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $i', style: const TextStyle(height: 1.4)),
            )),
      ],
    );
  }

  Widget _resultCard() {
    final color = _riskColor();
    final accounts = _indicator('accounts');
    final phones = _indicator('phones');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_riskIcon(), color: color, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_risk Risk',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                    Text('Score ${_result?['score']}/100',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_result?['category']}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
          _section(_risk == 'Low' ? 'Result' : 'Why it was flagged', _list('reasons')),
          _section('What to do next', _list('advice')),
          if (accounts.isNotEmpty || phones.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Check these before you pay or call',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                ...accounts.map((a) => ActionChip(
                      avatar: const Icon(Icons.account_balance, size: 18),
                      label: Text(a),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AccountCheckScreen(prefilledAccount: a))),
                    )),
                ...phones.map((p) => ActionChip(
                      avatar: const Icon(Icons.phone, size: 18),
                      label: Text(p),
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => LookupScreen(prefilledNumber: p))),
                    )),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _button('Share result', Icons.share, const Color(0xFF1B4965), () => Share.share(_reportText())),
          _button('View / copy report', Icons.description, Colors.black, _showReport),
          if (_risk != 'Low')
            _button('Already paid or shared details?', Icons.support, const Color(0xFFD62828), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryScreen()));
            }),
          _button('Get help from AWAL on WhatsApp', Icons.chat, const Color(0xFF008751), _contactHelp),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Scan Message')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Is this message a scam?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Paste any SMS, WhatsApp message, email or link. Works with English and Pidgin. '
                    'We do not store the message text.',
                    style: TextStyle(color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: 'Paste suspicious message here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste, color: Color(0xFF008751)),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) _messageController.text = data!.text!;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _scan,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFF008751),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Scan message', style: TextStyle(fontSize: 16)),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('First scan of the day can take up to a minute while the server wakes up.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
              ),
            const SizedBox(height: 24),
            if (_result != null) _resultCard(),
          ],
        ),
      ),
    );
  }
}
