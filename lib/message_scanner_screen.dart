import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class MessageScannerScreen extends StatefulWidget {
  const MessageScannerScreen({super.key});

  @override
  State<MessageScannerScreen> createState() => _MessageScannerScreenState();
}

class _MessageScannerScreenState extends State<MessageScannerScreen> {
  final TextEditingController _messageController = TextEditingController();

  String riskLevel = "";
  String scamType = "";
  String result = "";
  String advice = "";
  bool isLoading = false;
  bool usedAiScan = false;

  final String baseUrl = "https://phishtriage-scanner.onrender.com";

  Future<void> scanMessage() async {
    await _sendScanRequest("/analyze-message", false);
  }

  Future<void> advancedScan() async {
    await _sendScanRequest("/advanced-ai-scan", true);
  }

  Future<void> _sendScanRequest(String endpoint, bool aiScan) async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      setState(() {
        riskLevel = "No Message";
        scamType = "";
        result = "Please paste a suspicious message or link to scan.";
        advice = "Paste a message to scan.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      usedAiScan = aiScan;
      riskLevel = "";
      scamType = "";
      result = "";
      advice = "";
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text}),
      );

      final data = jsonDecode(response.body);
      final List reasons = data["reasons"] ?? [];

      setState(() {
        riskLevel = data["risk"] ?? "Unknown Risk";
        scamType = data["scam_type"] ?? (aiScan ? "AI Analysis" : "Basic Scan");
        result = reasons.isEmpty
            ? "No major scam indicators found."
            : reasons.map((e) => "• $e").join("\n");
        advice = data["advice"] ?? "Stay cautious.";
      });
    } catch (e) {
      setState(() {
        riskLevel = "Connection Error";
        scamType = "Backend Error";
        result = "Could not connect to scanner backend.";
        advice = "Make sure your backend is running and your IP address is correct.";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Color riskColor() {
    if (riskLevel == "High Risk") return Colors.red;
    if (riskLevel == "Medium Risk") return Colors.orange;
    if (riskLevel == "Low Risk") return const Color(0xFF008751);
    return Colors.grey;
  }

  IconData riskIcon() {
    if (riskLevel == "High Risk") return Icons.dangerous;
    if (riskLevel == "Medium Risk") return Icons.warning_amber_rounded;
    if (riskLevel == "Low Risk") return Icons.check_circle;
    return Icons.info;
  }

  String generateReportSummary() {
    return '''
PhishTriage Scan Report

Scan Type: ${usedAiScan ? "Advanced AI Scan" : "Basic Scan"}
Risk Level: $riskLevel
Scam Type: ${scamType.isEmpty ? "Not specified" : scamType}

Message:
${_messageController.text.trim()}

Detected Issues:
$result

Recommended Action:
$advice

Prepared by PhishTriage.
''';
  }

  Future<void> contactAwal(String report) async {
    final phone = "2347038336596";
    final message =
        Uri.encodeComponent("Hello, I need help with this:\n\n$report");
    final url = Uri.parse("whatsapp://send?phone=$phone&text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final webUrl = Uri.parse("https://wa.me/$phone?text=$message");
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void showReportDialog(String report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Generated Report"),
        content: SingleChildScrollView(child: Text(report)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report copied")),
              );
            },
            child: const Text("Copy"),
          ),
          TextButton(
            onPressed: () {
              Share.share(report);
            },
            child: const Text("Share"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showResult = riskLevel.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text("Scan Message")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Message Intelligence",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Paste any suspicious SMS, WhatsApp message, email text, or link. Use Basic Scan for quick checks or Advanced AI Scan for deeper analysis.",
                    style: TextStyle(
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _messageController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: "Paste suspicious message here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste,
                      color: Color(0xFF008751)),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      _messageController.text = data.text!;
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: isLoading ? null : scanMessage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFF008751),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text("Basic Scan"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: isLoading ? null : advancedScan,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Advanced AI Scan"),
            ),

            const SizedBox(height: 24),

            if (showResult)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: riskColor(), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(riskIcon(), color: riskColor(), size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                riskLevel,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor(),
                                ),
                              ),
                              Text(
                                usedAiScan
                                    ? "Advanced AI Analysis"
                                    : "Basic Risk Analysis",
                                style:
                                    const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (scamType.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Scam Type: $scamType",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: riskColor(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    const Text(
                      "Why it was flagged",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      result,
                      style: const TextStyle(height: 1.5),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "What to do next",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      advice,
                      style: const TextStyle(height: 1.4),
                    ),

                    const SizedBox(height: 18),

                    ElevatedButton(
                      onPressed: () {
                        final report = generateReportSummary();
                        showReportDialog(report);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("📄 Generate Report"),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: () {
                        final report = generateReportSummary();
                        Share.share(report);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Share Result"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4965),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () {
                        final report = generateReportSummary();
                        contactAwal(report);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008751),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("📲 Get Help via WhatsApp"),
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