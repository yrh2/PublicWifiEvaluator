import 'package:flutter/material.dart';
import '../widgets/common_bottom_navigation.dart';

class ScanResultsScreen extends StatelessWidget {
  final Map<String, dynamic> scanResults;
  final String threatLevel;
  final int threatScore;

  const ScanResultsScreen({
    super.key,
    required this.scanResults,
    required this.threatLevel,
    required this.threatScore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Scan Results',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ARP Spoofing
            _buildResultCard(
              title: 'ARP Spoofing',
              subtitle: _getArpStatus(),
              isDetected: _isArpDetected(),
            ),
            const SizedBox(height: 15),

            // DNS Spoofing
            _buildResultCard(
              title: 'DNS Spoofing',
              subtitle: _getDnsStatus(),
              isDetected: _isDnsDetected(),
            ),
            const SizedBox(height: 15),

            // Open Ports
            _buildResultCard(
              title: 'Open Ports',
              subtitle: _getOpenPortsStatus(),
              isDetected: _areOpenPortsDetected(),
            ),
            const SizedBox(height: 15),

            // Rogue AP
            _buildResultCard(
              title: 'Rogue AP',
              subtitle: _getRogueApStatus(),
              isDetected: _isRogueApDetected(),
            ),

            const Spacer(),

            // Bottom Navigation (same as home screen)
            
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String subtitle,
    required bool isDetected,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDetected ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDetected ? Icons.warning : Icons.check,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Methods to determine status
  bool _isArpDetected() {
    final arpData = scanResults['arp_spoofing'];
    if (arpData is Map) {
      return arpData['status'] == 'threat' || arpData['status'] == 'detected';
    }
    return arpData == true || arpData == 'detected';
  }

  String _getArpStatus() {
    return _isArpDetected() ? 'Detected' : 'Not Detected';
  }

  bool _isDnsDetected() {
    final dnsData = scanResults['dns_spoofing'];
    if (dnsData is Map) {
      return dnsData['status'] == 'threat' ||
          dnsData['status'] == 'detected' ||
          dnsData['status'] == 'warning';
    }
    return dnsData == true || dnsData == 'detected';
  }

  String _getDnsStatus() {
    return _isDnsDetected() ? 'Detected' : 'Not Detected';
  }

bool _areOpenPortsDetected() {
  final portsData = scanResults['open_ports'];

  if (portsData is Map) {
    final raw = portsData['raw'] ?? '';
    final regex = RegExp(r'(\d+)/tcp\s+open');
    return regex.hasMatch(raw); // true kalau ada at least satu open port
  }

  if (portsData is List) {
    return portsData.isNotEmpty;
  }

  return false;
}

String _getOpenPortsStatus() {
  final portsData = scanResults['open_ports'];

  if (portsData is Map) {
    final raw = portsData['raw'] ?? '';
    final regex = RegExp(r'(\d+)/tcp\s+open');
    final matches = regex.allMatches(raw);

    if (matches.isNotEmpty) {
      // Open ports
      final openPorts = matches.map((m) => m.group(1)).join(', ');
      return 'Detected ($openPorts)';
    }
  }

  if (portsData is List && portsData.isNotEmpty) {
    return 'Detected (${portsData.join(", ")})';
  }

  return 'Not Detected';
}


  bool _isRogueApDetected() {
    final rogueData = scanResults['rogue_ap'];
    if (rogueData is Map) {
      return rogueData['status'] == 'threat' ||
          rogueData['status'] == 'detected' ||
          rogueData['status'] == 'warning';
    }
    return rogueData == true || rogueData == 'detected';
  }

  String _getRogueApStatus() {
    return _isRogueApDetected() ? 'Detected' : 'Not Detected';
  }
}

