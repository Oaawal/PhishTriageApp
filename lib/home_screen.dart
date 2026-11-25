import 'package:flutter/material.dart';
import 'package:phishtriage_app/lookup_screen.dart';
import 'package:phishtriage_app/report_screen.dart';
import 'package:phishtriage_app/message_scanner_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'account_check_screen.dart';
import 'config.dart';
import 'recent_numbers.dart';
import 'api_client.dart';
import 'call_protection_screen.dart';
import 'native_bridge.dart';
import 'official_directory_screen.dart';
import 'recovery_screen.dart';
import 'scam_warnings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _recentNumbers = [];
  Map? _topWarning;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadWarning();
    // Open a message shared to PhishTriage, or a call-warning notification that was tapped.
    WidgetsBinding.instance.addPostFrameCallback((_) => NativeBridge.consumeLaunchActions());
  }

  Future<void> _loadWarning() async {
    try {
      final data = await ApiClient.get('/scam-alerts') as Map;
      final alerts = (data['alerts'] as List?) ?? [];
      if (mounted && alerts.isNotEmpty) setState(() => _topWarning = alerts.first as Map);
    } on ApiException {
      // no banner when offline
    }
  }

  Future<void> _loadRecent() async {
    final recent = await RecentNumbers.getRecent();
    setState(() {
      _recentNumbers = recent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// HEADER
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008751),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PhishTriage",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF008751),
                          ),
                        ),
                        Text(
                          "Nigeria's Scam Shield",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// HERO CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF008751),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Protect yourself from scams",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Check numbers, scan messages, report scams, and view high-risk alerts.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (_topWarning != null) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const ScamWarningsScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: severityColor(_topWarning!['severity'] as String?).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Icon(Icons.campaign, color: severityColor(_topWarning!['severity'] as String?)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Scam alert: ${_topWarning!['title']}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              /// QUICK ACTIONS
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              /// CHECK NUMBER
              _ActionCard(
                icon: Icons.search,
                title: "Check a Number",
                subtitle: "Look up Nigerian numbers for scam reports",
                color: const Color(0xFF008751),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LookupScreen(),
                    ),
                  ).then((_) => _loadRecent());
                },
              ),

              const SizedBox(height: 14),

              /// CHECK ACCOUNT
              _ActionCard(
                icon: Icons.account_balance,
                title: "Check a Bank Account",
                subtitle: "See if an account was reported before you pay",
                color: const Color(0xFF6A4C93),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountCheckScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// SCAN MESSAGE
              _ActionCard(
                icon: Icons.security,
                title: "Scan Message",
                subtitle: "Analyze SMS, WhatsApp messages, and links",
                color: const Color(0xFF1B4965),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MessageScannerScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// REPORT SCAM
              _ActionCard(
                icon: Icons.report,
                title: "Report a Scam",
                subtitle: "Submit suspicious numbers to protect others",
                color: const Color(0xFFD62828),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// CALL PROTECTION
              _ActionCard(
                icon: Icons.phone_locked,
                title: "Call Protection",
                subtitle: "Get warned while a reported number is calling",
                color: const Color(0xFF2A9D8F),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CallProtectionScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// OFFICIAL CONTACTS
              _ActionCard(
                icon: Icons.verified,
                title: "Is This Really My Bank?",
                subtitle: "Official numbers, SMS names and websites",
                color: const Color(0xFF3A86FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OfficialDirectoryScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// SCAM WARNINGS + HIGH-RISK NUMBERS
              _ActionCard(
                icon: Icons.warning_amber_rounded,
                title: "Scam Warnings",
                subtitle: "Scams going round now and high-risk numbers",
                color: const Color(0xFFE97C00),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScamWarningsScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              /// RECOVERY
              _ActionCard(
                icon: Icons.support,
                title: "I've Been Scammed",
                subtitle: "Step-by-step help and a complaint letter for your bank",
                color: const Color(0xFFD62828),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecoveryScreen(),
                    ),
                  );
                },
              ),

              /// WHATSAPP BOT
              if (AppConfig.botWhatsApp.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ActionCard(
                  icon: Icons.chat,
                  title: "Check on WhatsApp",
                  subtitle: "Forward suspicious messages to our WhatsApp bot",
                  color: const Color(0xFF25D366),
                  onTap: () {
                    launchUrl(
                      Uri.parse('https://wa.me/${AppConfig.botWhatsApp}?text=hi'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],

              const SizedBox(height: 28),

              /// SAFETY TIPS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates,
                            color: Color(0xFF008751)),
                        SizedBox(width: 8),
                        Text(
                          "Safety Tips",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text("• Never share your OTP, PIN, or password"),
                    Text("• Do not click unknown or suspicious links"),
                    Text("• Verify messages from banks directly"),
                    Text("• Report suspicious numbers immediately"),
                    Text("• Before paying a vendor, check the account here first"),
                    Text("• Tip: share any suspicious message to PhishTriage to check it"),
                  ],
                ),
              ),

              /// RECENTLY CHECKED
              if (_recentNumbers.isNotEmpty) ...[
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recently Checked",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await RecentNumbers.clearRecent();
                        _loadRecent();
                      },
                      child: const Text(
                        "Clear",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_recentNumbers.map(
                  (number) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LookupScreen(
                            prefilledNumber: number,
                          ),
                        ),
                      ).then((_) => _loadRecent());
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history,
                              color: Color(0xFF008751), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            number,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                )),
              ],

              const SizedBox(height: 28),

              /// FOOTER
              Center(
                child: Text(
                  "Powered by Awal Global Consults",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}