import 'package:flutter/material.dart';

import 'api_client.dart';

/// "Was this result right?" with optional, anonymous sharing of the message
/// to help train PhishTriage's own scam detector.
class FeedbackCard extends StatefulWidget {
  final String scanId;
  final String message;
  final bool flagged; // engine said Medium/High
  const FeedbackCard({super.key, required this.scanId, required this.message, required this.flagged});

  @override
  State<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<FeedbackCard> {
  bool _share = false;
  bool _sending = false;
  String? _done;
  String? _error;

  Future<void> _send(String verdict) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final data = await ApiClient.post(
        '/feedback',
        body: {
          'scan_id': widget.scanId,
          'verdict': verdict,
          'share_message': _share,
          if (_share) 'message': widget.message,
        },
      );
      setState(() => _done = '${(data as Map)['message'] ?? 'Thank you!'}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A Material (not a decorated Container) so the checkbox's tap ripple stays visible.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      child: Material(
        color: const Color(0xFFF1F7F4),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _done != null
              ? Row(
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFF008751)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_done!)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Was this result right?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OutlinedButton(
                          onPressed: _sending ? null : () => _send('correct'),
                          child: const Text('Yes, correct'),
                        ),
                        OutlinedButton(
                          onPressed: _sending ? null : () => _send(widget.flagged ? 'safe' : 'scam'),
                          child: Text(widget.flagged ? 'No, it is safe' : 'No, it is a scam'),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _share,
                      onChanged: _sending ? null : (v) => setState(() => _share = v ?? false),
                      title: const Text('Share this message anonymously to help train PhishTriage'),
                      subtitle: const Text(
                        'Phone numbers, account numbers, codes and emails are removed. A moderator reviews it. Optional.',
                      ),
                    ),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFD62828))),
                  ],
                ),
        ),
      ),
    );
  }
}
