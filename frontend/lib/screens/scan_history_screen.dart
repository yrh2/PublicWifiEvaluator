import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_bottom_navigation.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan History')),
        body: const Center(child: Text('Please log in to view scan history')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Scan History',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('scan_history')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(20) // Limit to prevent excessive reads
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Firestore error: ${snapshot.error}');
            // Show mock data when Firebase is not available
            return _buildMockHistoryView();
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No previous scans',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return _buildHistoryList(docs);
        },
      ),
      bottomNavigationBar: const CommonBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildHistoryList(List<QueryDocumentSnapshot> docs) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previous scans',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final scan = ScanHistoryItem.fromFirestore(data);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryCard(scan),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockHistoryView() {
    // Show some mock data when Firebase is not available
    final mockScans = [
      ScanHistoryItem(
        date: '22/8/2025',
        time: '13:54',
        networkName: 'shafiq_5GHz',
        threatLevel: 'Low',
        threatScore: 5,
        scanResults: {},
        timestamp: DateTime.now(),
      ),
      ScanHistoryItem(
        date: '21/8/2025',
        time: '10:54',
        networkName: 'CoffeeShop',
        threatLevel: 'Med',
        threatScore: 45,
        scanResults: {},
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previous scans',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: mockScans.length,
              itemBuilder: (context, index) {
                final scan = mockScans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryCard(scan),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem scan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${scan.date}, ${scan.time}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scan.networkName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getThreatLevelColor(scan.threatLevel),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              scan.threatLevel.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getThreatLevelColor(String threatLevel) {
    switch (threatLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
      case 'med':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class ScanHistoryItem {
  final String date;
  final String time;
  final String networkName;
  final String threatLevel;
  final int threatScore;
  final Map<String, dynamic> scanResults;
  final DateTime timestamp;

  ScanHistoryItem({
    required this.date,
    required this.time,
    required this.networkName,
    required this.threatLevel,
    required this.threatScore,
    required this.scanResults,
    required this.timestamp,
  });

  factory ScanHistoryItem.fromFirestore(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();

    return ScanHistoryItem(
      date: data['date'] ?? _formatDate(dateTime),
      time: data['time'] ?? _formatTime(dateTime),
      networkName: data['networkName'] ?? '',
      threatLevel: data['threatLevel'] ?? '',
      threatScore: data['threatScore'] ?? 0,
      scanResults: data['scanResults'] ?? {},
      timestamp: dateTime,
    );
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'time': time,
      'networkName': networkName,
      'threatLevel': threatLevel,
      'threatScore': threatScore,
      'scanResults': scanResults,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': '', // Will be set when saving
    };
  }
}
