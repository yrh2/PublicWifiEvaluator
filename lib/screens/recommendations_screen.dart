import 'package:flutter/material.dart';
import '../widgets/common_bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _recommendations = _getGeneralRecommendations();
          _isLoading = false;
        });
        return;
      }

      // Get recent scan results from Firebase
      final querySnapshot = await _firestore
          .collection('scan_history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      print('🔍 Found ${querySnapshot.docs.length} scan history documents');

      List<Map<String, dynamic>> recommendations = [];

      // Get recommendations for recent scans
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        print('📄 Scan data: ${data.keys}');
        print('📊 Has scanResults: ${data['scanResults'] != null}');

        if (data['scanResults'] != null) {
          print('🔧 Calling backend API for threat analysis...');
          try {
            // Convert FullScanResult back to backend format
            final scanData = data['scanResults'];
            Map<String, dynamic> backendFormat = {};

            // Handle the format conversion
            if (scanData is Map<String, dynamic>) {
              // If it's already the right format (from older scans)
              if (scanData.containsKey('arp_spoofing')) {
                backendFormat = scanData;
              } else {
                // Convert FullScanResult format to backend format
                backendFormat = {
                  'arp_spoofing': _convertToBackendStatus(
                    scanData['arpSpoofing'],
                  ),
                  'dns_spoofing': _convertToBackendStatus(
                    scanData['dnsSpoofing'],
                  ),
                  'rogue_ap': _convertToBackendStatus(scanData['rogueAp']),
                  'open_ports': scanData['openPorts'] ?? {},
                };
              }
            }

            print('📤 Sending to backend: $backendFormat');

            // Call backend API to get threat score and recommendation
            final response = await http.post(
              Uri.parse('http://10.0.2.2:5001/scan/threat_score'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(backendFormat),
            );

            print('🌐 Backend response status: ${response.statusCode}');

            if (response.statusCode == 200) {
              final threatData = jsonDecode(response.body);
              print('✅ Got threat data: $threatData');
              recommendations.add({
                'networkName': data['networkName'] ?? 'Unknown Network',
                'timestamp': data['timestamp'],
                'threatLevel': threatData['threat_level'],
                'score': threatData['score'],
                'recommendation': threatData['recommendation'],
                'reasons': threatData['reasons'] ?? [],
              });
            } else {
              print('❌ Backend API error: ${response.statusCode}');
            }
          } catch (e) {
            print('💥 Error getting recommendation for scan: $e');
          }
        }
      }

      print('📋 Total personalized recommendations: ${recommendations.length}');

      // Add general recommendations if no specific scan data
      if (recommendations.isEmpty) {
        recommendations = _getGeneralRecommendations();
      }

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations: $e';
        _isLoading = false;
      });
    }
  }

  String _convertToBackendStatus(dynamic data) {
    if (data == null) return 'not_detected';

    if (data is Map<String, dynamic>) {
      final status = data['status']?.toString().toLowerCase();
      final detected = data['detected'];

      if (status == 'detected' || status == 'warning' || status == 'threat') {
        return 'detected';
      } else if (detected == true) {
        return 'detected';
      } else {
        return 'not_detected';
      }
    } else if (data is bool) {
      return data ? 'detected' : 'not_detected';
    } else if (data is String) {
      return data.toLowerCase() == 'detected' ? 'detected' : 'not_detected';
    }

    return 'not_detected';
  }

  List<Map<String, dynamic>> _getGeneralRecommendations() {
    return [
      {
        'networkName': 'General Security',
        'threatLevel': 'Info',
        'recommendation': 'Always use a VPN on public Wi-Fi networks',
        'reasons': ['Best practice for public networks'],
        'isGeneral': true,
      },
      {
        'networkName': 'General Security',
        'threatLevel': 'Info',
        'recommendation': 'Avoid accessing sensitive accounts on public Wi-Fi',
        'reasons': ['Protect banking and email accounts'],
        'isGeneral': true,
      },
      {
        'networkName': 'General Security',
        'threatLevel': 'Info',
        'recommendation': 'Verify network names with venue staff',
        'reasons': ['Prevent connecting to rogue access points'],
        'isGeneral': true,
      },
      {
        'networkName': 'General Security',
        'threatLevel': 'Info',
        'recommendation': 'Enable automatic software updates',
        'reasons': ['Keep security patches current'],
        'isGeneral': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Recommendations',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadRecommendations,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final rec = _recommendations[index];
                    return RecommendationCard(
                      networkName: rec['networkName'],
                      threatLevel: rec['threatLevel'],
                      recommendation: rec['recommendation'],
                      reasons: List<String>.from(rec['reasons'] ?? []),
                      timestamp: rec['timestamp'],
                      isGeneral: rec['isGeneral'] ?? false,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(currentIndex: 4),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final String networkName;
  final String threatLevel;
  final String recommendation;
  final List<String> reasons;
  final dynamic timestamp;
  final bool isGeneral;

  const RecommendationCard({
    super.key,
    required this.networkName,
    required this.threatLevel,
    required this.recommendation,
    required this.reasons,
    this.timestamp,
    this.isGeneral = false,
  });

  Color _getThreatColor() {
    switch (threatLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getThreatIcon() {
    switch (threatLevel.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getThreatIcon(), color: _getThreatColor(), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        networkName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!isGeneral && timestamp != null)
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getThreatColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    threatLevel,
                    style: TextStyle(
                      color: _getThreatColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(recommendation, style: const TextStyle(fontSize: 14)),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (timestamp is DateTime) {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
      } else if (timestamp is String) {
        final dateTime = DateTime.tryParse(timestamp);
        if (dateTime != null) {
          return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }
      }
      return 'Recent';
    } catch (e) {
      return 'Recent';
    }
  }
}
