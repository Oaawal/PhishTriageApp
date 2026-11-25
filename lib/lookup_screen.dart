import 'package:flutter/material.dart';
import 'api_client.dart';
import 'blocklist_service.dart';
import 'dispute_screen.dart';
import 'report_screen.dart';
import 'recent_numbers.dart';

class LookupScreen extends StatefulWidget {
  final String? prefilledNumber;
  const LookupScreen({super.key, this.prefilledNumber});

  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> {
  final TextEditingController _numberController = TextEditingController();

  Map<String, dynamic>? result;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledNumber != null) {
      _numberController.text = widget.prefilledNumber!;
    }
  }

  Future<void> lookupNumber() async {
    final number = _numberController.text.trim();

    if (number.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a phone number';
        result = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      result = null;
    });

    try {
      final data = await ApiClient.get('/lookup', query: {'number': number});
      setState(() {
        result = Map<String, dynamic>.from(data as Map);
      });
      await RecentNumbers.addNumber(number);
    } on ApiException catch (e) {
      // No connection: fall back to the offline list downloaded for call protection.
      final offline = await BlocklistService.lookupOffline(number);
      final official = await BlocklistService.officialOffline(number);
      setState(() {
        if (offline != null || official != null) {
          result = {
            'found': offline != null,
            'number': BlocklistService.normalize(number) ?? number,
            'risk_level': offline?['r'] ?? 'Low',
            'confidence': '-',
            'report_count_total': offline?['c'] ?? 0,
            'report_count_7d': '-',
            'trend': 'stable',
            'current_label': offline?['l'] ?? 'Unknown',
            'official': official != null ? [{'org_name': official}] : [],
            'status_note': 'Offline result from your saved list. Connect to the internet for the latest reports.',
          };
        } else {
          errorMessage = e.message;
        }
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return const Color(0xFFD62828);
      case 'medium':
        return const Color(0xFFE97C00);
      default:
        return const Color(0xFF008751);
    }
  }

  Widget _officialBanner() {
    final official = (result?['official'] as List?) ?? const [];
    if (official.isEmpty) return const SizedBox.shrink();
    final orgs = official.map((o) => (o as Map)['org_name']).toSet().join(', ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF008751).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.verified, color: Color(0xFF008751)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Official number of $orgs. Callers can fake this number, so never share your OTP, PIN or password.',
            style: const TextStyle(height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget buildResultCard() {
    if (result == null) return const SizedBox.shrink();
    return Column(children: [_officialBanner(), _buildResultCardInner()]);
  }

  Widget _buildResultCardInner() {

    if (result!['found'] != true) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF008751), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result!['status_note'] ?? 'No scam reports found for this number',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportScreen(
                        prefilledNumber: _numberController.text.trim(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.report, color: Color(0xFFD62828)),
                label: const Text(
                  'Report This Number',
                  style: TextStyle(color: Color(0xFFD62828)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD62828)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final risk = result!['risk_level'] ?? 'Low';
    final color = riskColor(risk);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  risk.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Risk Level',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ResultRow(
                  label: 'Number',
                  value: result!['number'] ?? '',
                  icon: Icons.phone,
                ),
                const Divider(height: 24),
                _ResultRow(
                  label: 'Confidence',
                  value: '${result!['confidence']}%',
                  icon: Icons.bar_chart,
                ),
                const Divider(height: 24),
                _ResultRow(
                  label: 'Total Reports',
                  value: '${result!['report_count_total']}',
                  icon: Icons.report,
                ),
                const Divider(height: 24),
                _ResultRow(
                  label: 'Reports (7 days)',
                  value: '${result!['report_count_7d']}',
                  icon: Icons.calendar_today,
                ),
                const Divider(height: 24),
                _ResultRow(
                  label: 'Trend',
                  value: result!['trend'] ?? 'stable',
                  icon: Icons.trending_up,
                  valueColor: result!['trend'] == 'rising'
                      ? const Color(0xFFD62828)
                      : const Color(0xFF008751),
                ),
                const Divider(height: 24),
                _ResultRow(
                  label: 'Label',
                  value: result!['current_label'] ?? 'Unknown',
                  icon: Icons.label,
                ),
                if (result!['status_note'] != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    result!['status_note'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportScreen(
                            prefilledNumber: _numberController.text.trim(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.report, color: Color(0xFFD62828)),
                    label: const Text(
                      'Report This Number',
                      style: TextStyle(color: Color(0xFFD62828)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD62828)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DisputeScreen(
                          targetType: 'number',
                          target: result!['number'] ?? _numberController.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: const Text('This is my number: request a review'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text(
          'Check a Number',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a Nigerian phone number to check if it has been reported for scam activity.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. 08012345678',
                prefixIcon: const Icon(Icons.phone),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : lookupNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008751),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Check Number',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            buildResultCard(),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}