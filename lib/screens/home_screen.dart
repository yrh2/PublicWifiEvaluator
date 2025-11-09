import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/wifi_service_new.dart';
import '../widgets/common_bottom_navigation.dart';
import 'scan_results_screen.dart';
import 'recommendations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // WiFi Status
  String _wifiStatus = "Not Scanned";
  WiFiInfo? _wifiInfo;
  Color _statusColor = Colors.grey;

  // Threat Score
  ThreatScore? _threatScore;

  // Scanning state
  bool _isScanning = false;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadWiFiInfo();
  }

  Future<void> _loadWiFiInfo() async {
    try {
      final wifiInfo = await WiFiService.getCurrentWiFiInfo();
      setState(() {
        _wifiInfo = wifiInfo;
        _wifiStatus = "Connected";
        _statusColor = Colors.blue;
      });
    } catch (e) {
      print('Error loading WiFi info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                await authService.signOut();
                print('✅ Logout successful - Firebase will handle navigation');

                // Close loading dialog
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                print('❌ Logout error: $e');
                // Close loading dialog
                if (mounted) {
                  Navigator.of(context).pop();
                }
                // Show error message
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Wi-Fi Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wi-Fi Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // WiFi Icon
                      Container(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // WiFi signal arcs
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _statusColor,
                                  width: 3,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(35),
                                  topRight: Radius.circular(35),
                                ),
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _statusColor,
                                  width: 3,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                ),
                              ),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _statusColor,
                                  width: 3,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                              ),
                            ),
                            // Center dot
                            Positioned(
                              bottom: 5,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _wifiStatus,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _statusColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SSID: ${_wifiInfo?.ssid ?? "Unknown"}'),
                                  Text(
                                    'Signal: ${_wifiInfo?.signal ?? "Unknown"}',
                                  ),
                                  Text(
                                    'Security: ${_wifiInfo?.authentication ?? "Unknown"}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Threat Score Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Threat Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Large Score Number
                      Text(
                        _threatScore?.score.toString() ?? "--",
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          _threatScore?.threatLevel ?? "Unknown",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getThreatColor(_threatScore?.threatLevel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Scan Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _performScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isScanning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Scanning...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Scan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(currentIndex: 0),
    );
  }

  Future<void> _performScan() async {
    setState(() {
      _isScanning = true;
      _wifiStatus = "Scanning...";
      _statusColor = Colors.orange;
    });

    try {
      // Perform network scan
      final scanResult = await WiFiService.scanNetwork();

      // Calculate threat score based on scan results
      final threatScoreData = {
        'arp_spoofing': _getThreatStatus(scanResult['arp_spoofing']),
        'dns_spoofing': _getThreatStatus(scanResult['dns_spoofing']),
        'rogue_ap': _getThreatStatus(scanResult['rogue_ap']),
        'open_ports': scanResult['open_ports'] ?? {},
      };

      final threatScore = await WiFiService.calculateThreatScore(
        threatScoreData,
      );

      setState(() {
        // If backend returned wifi_info, update the displayed SSID
        if (scanResult['wifi_info'] is Map<String, dynamic>) {
          final info = WiFiInfo.fromJson(
            Map<String, dynamic>.from(scanResult['wifi_info']),
          );
          _wifiInfo = info;
        }

        _threatScore = threatScore;
        _isScanning = false;

        // Update WiFi status based on threat level
        if (threatScore.threatLevel.toLowerCase() == "low") {
          _wifiStatus = "Wi-Fi is Safe";
          _statusColor = Colors.green;
        } else if (threatScore.threatLevel.toLowerCase() == "medium") {
          _wifiStatus = "Wi-Fi has Risks";
          _statusColor = Colors.orange;
        } else {
          _wifiStatus = "Wi-Fi is Dangerous";
          _statusColor = Colors.red;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'WiFi scan completed! Threat Level: ${threatScore.threatLevel}',
          ),
          backgroundColor: _getThreatColor(threatScore.threatLevel),
        ),
      );

      // Save scan to Firebase
      await _saveScanToHistory(scanResult, threatScore);

      // Navigate to scan results screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultsScreen(
              scanResults: scanResult,
              threatLevel: threatScore.threatLevel,
              threatScore: threatScore.score,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _wifiStatus = "Scan Failed";
        _statusColor = Colors.red;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getThreatColor(String? threatLevel) {
    switch (threatLevel?.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getThreatStatus(dynamic value) {
    // Handle both old boolean format and new object format
    if (value is bool) {
      return value ? 'detected' : 'not_detected';
    }
    if (value is Map<String, dynamic>) {
      final status = value['status']?.toString().toLowerCase() ?? '';
      if (status == 'threat' || status == 'detected' || status == 'warning') {
        return 'detected';
      }
    }
    if (value is String) {
      if (value.toLowerCase() == 'detected' ||
          value.toLowerCase() == 'threat') {
        return 'detected';
      }
    }
    return 'not_detected';
  }

  Future<void> _saveScanToHistory(
    Map<String, dynamic> scanResult,
    ThreatScore threatScore,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not logged in, skipping scan history save');
        return;
      }

      final now = DateTime.now();
      final networkName = _wifiInfo?.ssid ?? 'Unknown Network';

      await _firestore.collection('scan_history').add({
        'userId': user.uid,
        'networkName': networkName,
        'threatLevel': threatScore.threatLevel,
        'threatScore': threatScore.score,
        'date': '${now.day}/${now.month}/${now.year}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'timestamp': Timestamp.fromDate(now),
        'scanResults': scanResult,
      });
      print('Scan saved to history successfully');
    } catch (e) {
      print('Error saving scan to history: $e');
      // Continue without saving - don't break the app flow
    }
  }
}
