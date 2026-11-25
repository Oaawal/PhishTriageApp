import 'package:flutter/material.dart';
import 'api_client.dart';

class ReportScreen extends StatefulWidget {
  final String? prefilledNumber;
  const ReportScreen({super.key, this.prefilledNumber});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

@override
void initState() {
  super.initState();
  if (widget.prefilledNumber != null) {
    _numberController.text = widget.prefilledNumber!;
  }
}

  String selectedReason = 'otp scam';
  String selectedChannel = 'sms';
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  final List<String> reasons = [
    'otp scam',
    'bank scam',
    'loan scam',
    'impersonation',
    'investment scam',
    'romance scam',
    'job scam',
    'wrong transfer',
    'family impersonation',
    'online shopping',
    'other',
  ];

  final List<String> channels = [
    'sms',
    'call',
    'whatsapp',
    'telegram',
    'email',
    'instagram',
    'facebook',
    'tiktok',
    'x',
    'website',
    'other',
  ];

  Future<void> submitReport() async {
    final number = _numberController.text.trim();

    if (number.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a phone number';
        successMessage = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final message = _messageController.text.trim();
      final data = await ApiClient.post('/report', query: {
        'number': number,
        'reason': selectedReason,
        'channel': selectedChannel,
        if (message.isNotEmpty) 'message': message,
      });
      setState(() {
        successMessage = (data as Map)['message'] ?? 'Report submitted successfully';
        _numberController.clear();
        _messageController.clear();
        selectedReason = 'otp scam';
        selectedChannel = 'sms';
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text(
          'Report a Number',
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
              'Report a scam number to help protect other Nigerians.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Number field
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),

            // Scam type
            const Text(
              'Scam Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedReason = val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Channel
            const Text(
              'Reported Via',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedChannel,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
                items: channels
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedChannel = val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Message
            const Text(
              'Message Received (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Paste the scam message here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD62828),
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
                        'Submit Report',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFD62828), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Color(0xFFD62828)),
                      ),
                    ),
                  ],
                ),
              ),

            if (successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF008751), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        successMessage!,
                        style: const TextStyle(color: Color(0xFF008751)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}