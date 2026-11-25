import 'package:flutter/material.dart';

import 'blocklist_service.dart';
import 'lookup_screen.dart';
import 'native_bridge.dart';
import 'report_screen.dart';

/// Warns while a reported number is calling (Android 10+), optional blocking,
/// the offline number list, and recent unknown callers to report in one tap.
class CallProtectionScreen extends StatefulWidget {
  const CallProtectionScreen({super.key});

  @override
  State<CallProtectionScreen> createState() => _CallProtectionScreenState();
}

class _CallProtectionScreenState extends State<CallProtectionScreen> with WidgetsBindingObserver {
  Map<String, dynamic> _status = {};
  List<Map<String, dynamic>> _recent = [];
  DateTime? _listUpdated;
  int _listCount = 0;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(); // e.g. after the permission dialog
  }

  Future<void> _load() async {
    final status = await NativeBridge.callProtectionStatus();
    final recent = await NativeBridge.recentCalls();
    final updated = await BlocklistService.lastUpdated();
    final count = await BlocklistService.count();
    if (!mounted) return;
    setState(() {
      _status = status;
      _recent = recent;
      _listUpdated = updated;
      _listCount = count;
      _loading = false;
    });
  }

  Future<void> _turnOn() async {
    await NativeBridge.requestNotificationPermission();
    final ok = await NativeBridge.requestCallScreening();
    await BlocklistService.refresh(force: true);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Call protection is on.' : 'Call protection was not turned on.'),
    ));
  }

  Future<void> _refreshList() async {
    setState(() => _refreshing = true);
    final n = await BlocklistService.refresh(force: true);
    await _load();
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(n == null ? 'Could not update the list. Check your connection.' : 'List updated: $n numbers.'),
    ));
  }

  String _ago(int millis) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(millis));
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  Widget _unsupported() {
    return ListView(padding: const EdgeInsets.all(20), children: const [
      Icon(Icons.phone_disabled, size: 56, color: Colors.grey),
      SizedBox(height: 12),
      Text(
        'Call protection needs an Android phone running Android 10 or newer.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(height: 8),
      Text(
        'On iPhone this is coming soon. Meanwhile, use "Check a Number" before you call back unknown numbers.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final on = _status['roleHeld'] == true;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Call Protection')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _status['supported'] != true
              ? _unsupported()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: on ? const Color(0xFF008751) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(on ? Icons.verified_user : Icons.shield_outlined,
                                  color: on ? Colors.white : const Color(0xFF008751), size: 32),
                              const SizedBox(width: 10),
                              Text(on ? 'Call protection is ON' : 'Call protection is OFF',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: on ? Colors.white : const Color(0xFF1A1A1A))),
                            ]),
                            const SizedBox(height: 10),
                            Text(
                              'When a number reported by other users calls you, PhishTriage shows a warning '
                              'while it rings. Your contacts and call log are never read or uploaded. The check '
                              'happens on your phone using the downloaded list.',
                              style: TextStyle(color: on ? Colors.white70 : Colors.grey[700], height: 1.4),
                            ),
                            if (!on) ...[
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _turnOn,
                                icon: const Icon(Icons.shield),
                                label: const Text('Turn on call protection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF008751),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Android will ask you to set PhishTriage as your "caller ID & spam app".',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (on && _status['notificationsAllowed'] != true)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications_off, color: Color(0xFFE97C00)),
                            title: const Text('Allow notifications'),
                            subtitle: const Text('Warnings appear as notifications while the phone rings.'),
                            onTap: () async {
                              await NativeBridge.requestNotificationPermission();
                              await _load();
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Card(
                        child: SwitchListTile(
                          value: _status['blockHighRisk'] == true,
                          onChanged: on
                              ? (v) async {
                                  await NativeBridge.setBlockHighRisk(v);
                                  await _load();
                                }
                              : null,
                          title: const Text('Block high-risk callers'),
                          subtitle: const Text('Numbers reported 3 or more times are rejected automatically. '
                              'You still get a notification.'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.download_for_offline),
                          title: Text('Offline list: $_listCount reported numbers'),
                          subtitle: Text(_listUpdated == null
                              ? 'Not downloaded yet'
                              : 'Updated ${_ago(_listUpdated!.millisecondsSinceEpoch)}. Refreshes every 6 hours.'),
                          trailing: _refreshing
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshList),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        const Expanded(
                          child: Text('Recent unknown callers',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                        if (_recent.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await NativeBridge.clearRecentCalls();
                              await _load();
                            },
                            child: const Text('Clear'),
                          ),
                      ]),
                      const Text('Was one of these a scam? Report it in one tap to protect others.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      if (_recent.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No unknown callers yet.', style: TextStyle(color: Colors.grey)),
                        ),
                      ..._recent.map((c) {
                        final number = '${c['number']}';
                        final risk = c['risk'];
                        final official = c['official'];
                        final subtitle = [
                          _ago(c['time'] as int),
                          if (c['blocked'] == true) 'blocked',
                          if (risk != null) '$risk risk · ${c['label']}',
                          if (official != null) 'official: $official',
                        ].join(' · ');
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              c['blocked'] == true
                                  ? Icons.block
                                  : risk != null
                                      ? Icons.warning_amber_rounded
                                      : Icons.call_received,
                              color: risk != null ? const Color(0xFFD62828) : Colors.grey,
                            ),
                            title: Text(number),
                            subtitle: Text(subtitle),
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => LookupScreen(prefilledNumber: number))),
                            trailing: TextButton(
                              child: const Text('Report'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ReportScreen(prefilledNumber: number, prefilledChannel: 'call')),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
