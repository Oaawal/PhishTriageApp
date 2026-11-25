import 'package:flutter/material.dart';

import 'api_client.dart';
import 'dispute_screen.dart';

/// "Is it safe to pay into this account?"
class AccountCheckScreen extends StatefulWidget {
  final String? prefilledAccount;
  const AccountCheckScreen({super.key, this.prefilledAccount});

  @override
  State<AccountCheckScreen> createState() => _AccountCheckScreenState();
}

const List<String> kBanks = [
  'Unknown',
  'Access Bank',
  'Ecobank',
  'FCMB',
  'Fidelity Bank',
  'First Bank',
  'GTBank',
  'Kuda',
  'Moniepoint',
  'OPay',
  'PalmPay',
  'Polaris Bank',
  'Stanbic IBTC',
  'Sterling Bank',
  'UBA',
  'Union Bank',
  'Wema Bank',
  'Zenith Bank',
  'Other',
];

const Map<String, String> kReasonLabels = {
  'online shopping': 'Online shopping / fake vendor',
  'wrong transfer': 'Fake "wrong transfer" refund',
  'family impersonation': 'Pretended to be family / new number',
  'investment scam': 'Investment / Ponzi',
  'job scam': 'Job / recruitment fee',
  'loan scam': 'Loan fee scam',
  'impersonation': 'Impersonated a company or agency',
  'romance scam': 'Romance scam',
  'other': 'Other',
};

const Map<String, String> kChannelLabels = {
  'whatsapp': 'WhatsApp',
  'instagram': 'Instagram',
  'facebook': 'Facebook',
  'tiktok': 'TikTok',
  'x': 'X (Twitter)',
  'sms': 'SMS',
  'call': 'Phone call',
  'telegram': 'Telegram',
  'website': 'Website',
  'email': 'Email',
  'other': 'Other',
};

class _AccountCheckScreenState extends State<AccountCheckScreen> {
  final _accountController = TextEditingController();
  String _bank = 'Unknown';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAccount != null) {
      _accountController.text = widget.prefilledAccount!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  String get _digits => _accountController.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _check() async {
    if (_digits.length != 10) {
      setState(() => _error = 'Enter the 10-digit account number.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await ApiClient.get('/accounts/lookup', query: {
        'account_number': _digits,
        if (_bank != 'Unknown') 'bank': _bank,
      });
      setState(() => _result = Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _color(String risk) => risk == 'High'
      ? const Color(0xFFD62828)
      : risk == 'Medium'
          ? const Color(0xFFE97C00)
          : const Color(0xFF008751);

  Widget _resultCard() {
    final r = _result!;
    final matches = ((r['matches'] as List?) ?? []).cast<Map>();
    final risk = (r['risk_level'] ?? 'Low') as String;
    final color = _color(risk);
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
          Row(children: [
            Icon(r['found'] == true ? Icons.warning_amber_rounded : Icons.verified_user, color: color, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                r['found'] == true ? '$risk risk' : 'No approved reports',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text('${r['status_note'] ?? ''}', style: const TextStyle(height: 1.4)),
          ...matches.map((m) => Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color('${m['risk_level']}').withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m['account_number']} · ${m['bank']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (m['account_name'] != null) Text('Name on reports: ${m['account_name']}'),
                    Text('Type: ${m['label']} · ${m['report_count_total']} approved report(s)'),
                    if (m['under_review'] == true)
                      const Text('Owner has disputed this listing. Under review.',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Text('${r['tip'] ?? ''}', style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.report),
                label: const Text('Report account'),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _AccountReportSheet(accountNumber: _digits, bank: _bank),
                ),
              ),
            ),
            if (r['found'] == true) ...[
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  child: const Text('This is my account'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DisputeScreen(
                        targetType: 'account',
                        target: _digits,
                        bank: matches.isNotEmpty ? '${matches.first['bank']}' : _bank,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Check a Bank Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Before you pay a vendor, agent or "customer care", check if others have reported the account.',
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Account number',
                hintText: '0123456789',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _bank,
              decoration: InputDecoration(
                labelText: 'Bank (optional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: kBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _bank = v ?? 'Unknown'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _check,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: const Color(0xFF008751),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Check account', style: TextStyle(fontSize: 16)),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
              ),
            const SizedBox(height: 20),
            if (_result != null) _resultCard(),
          ],
        ),
      ),
    );
  }
}

class _AccountReportSheet extends StatefulWidget {
  final String accountNumber;
  final String bank;
  const _AccountReportSheet({required this.accountNumber, required this.bank});

  @override
  State<_AccountReportSheet> createState() => _AccountReportSheetState();
}

class _AccountReportSheetState extends State<_AccountReportSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  late String _bank = widget.bank;
  String _reason = 'online shopping';
  String _channel = 'whatsapp';
  bool _share = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final data = await ApiClient.post('/accounts/report', body: {
        'account_number': widget.accountNumber,
        'bank': _bank,
        'account_name': _name.text.trim().isEmpty ? null : _name.text.trim(),
        'reason': _reason,
        'channel': _channel,
        'amount_lost': double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        'message': _message.text.trim().isEmpty ? null : _message.text.trim(),
        'share_for_training': _share && _message.text.trim().isNotEmpty,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${(data as Map)['message']}')));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Report account ${widget.accountNumber}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Only report accounts you were asked to pay into as part of a scam. '
                'False reports harm innocent people.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _bank,
              decoration: _dec('Bank'),
              items: kBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _bank = v ?? 'Unknown'),
            ),
            const SizedBox(height: 10),
            TextField(controller: _name, decoration: _dec('Account name shown by your bank (optional)')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: _dec('What happened'),
              items: kReasonLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _reason = v ?? 'other'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _channel,
              decoration: _dec('Where did they contact you'),
              items: kChannelLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _channel = v ?? 'other'),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: _dec('Amount lost in naira (optional)')),
            const SizedBox(height: 10),
            TextField(controller: _message, maxLines: 3, decoration: _dec('Short description (optional)')),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _share,
              onChanged: (v) => setState(() => _share = v ?? false),
              title: const Text('Allow anonymous use of the description to improve scam detection'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
              ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFD62828),
                foregroundColor: Colors.white,
              ),
              child: Text(_sending ? 'Sending...' : 'Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
