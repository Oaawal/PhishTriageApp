import 'package:flutter/material.dart';

import 'api_client.dart';

/// Right of reply: the owner of a listed number or account asks for a review.
class DisputeScreen extends StatefulWidget {
  final String targetType; // 'number' or 'account'
  final String target;
  final String? bank;
  const DisputeScreen({super.key, required this.targetType, required this.target, this.bank});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _contact = TextEditingController();
  final _explanation = TextEditingController();
  bool _sending = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _contact.dispose();
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contact.text.trim().length < 5 || _explanation.text.trim().length < 20) {
      setState(() => _error = 'Give a phone number or email, and at least 20 characters of explanation.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final data = await ApiClient.post('/disputes', body: {
        'target_type': widget.targetType,
        'target': widget.target,
        if (widget.bank != null) 'bank': widget.bank,
        'contact': _contact.text.trim(),
        'explanation': _explanation.text.trim(),
      });
      setState(() => _done = '${(data as Map)['message']}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final what = widget.targetType == 'number' ? 'phone number' : 'bank account';
    return Scaffold(
      appBar: AppBar(title: const Text('Request a review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _done != null
            ? Column(children: [
                const Icon(Icons.check_circle, color: Color(0xFF008751), size: 64),
                const SizedBox(height: 12),
                Text(_done!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Is ${widget.target} your $what?',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'If you believe it was reported by mistake, explain below. A moderator will review it, '
                    'may contact you for proof, and will clear the listing if the reports were wrong. '
                    'While the review is open, the listing shows "under review".',
                    style: TextStyle(color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contact,
                    decoration: const InputDecoration(
                        labelText: 'Your phone number or email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _explanation,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        labelText: 'Explanation (who you are, why the reports are wrong)',
                        border: OutlineInputBorder()),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF1B4965),
                        foregroundColor: Colors.white),
                    child: Text(_sending ? 'Sending...' : 'Send for review'),
                  ),
                ],
              ),
      ),
    );
  }
}
