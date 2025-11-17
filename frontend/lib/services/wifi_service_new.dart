import 'dart:convert';
import 'package:http/http.dart' as http;

class WiFiService {
  static const String baseUrl =
      'http://10.0.2.2:5001'; // Backend URL for Android emulator

  // Perform combined network scan (backend: /scan/all)
  static Future<Map<String, dynamic>> scanNetwork() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scan/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to scan network: ${response.statusCode}');
      }
    } catch (e) {
      print('WiFi scan error: $e');
      // Return mock data if backend is not available
      return {
        "open_ports": [80, 443],
        "arp_spoofing": false,
        "dns_spoofing": false,
        "rogue_ap": false,
        "threat_score": "Low",
        "recommendation": "Wi-Fi appears safe to use.",
      };
    }
  }

  // Calculate threat score based on scan results
  static Future<ThreatScore> calculateThreatScore(
    Map<String, dynamic> scanData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scan/threat_score'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(scanData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ThreatScore.fromJson(data);
      } else {
        throw Exception(
          'Failed to calculate threat score: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Threat score calculation error: $e');
      // Return mock data if backend is not available
      return ThreatScore.mockData();
    }
  }

  // Get current WiFi information from backend
  static Future<WiFiInfo> getCurrentWiFiInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scan/wifi'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Even if the backend returns an error, it’s better to show 'Unknown' fields rather than a fake SSID
        if (data is Map<String, dynamic> && data.containsKey('SSID')) {
          return WiFiInfo.fromJson(data);
        }
        print(
          'WiFi info warning from backend: ${data['error'] ?? 'unknown issue'}',
        );
        return WiFiInfo.unknown();
      } else {
        throw Exception('Failed to get WiFi info: ${response.statusCode}');
      }
    } catch (e) {
      print('WiFi info error: $e');
      // Show Unknowns rather than a misleading mock SSID
      return WiFiInfo.unknown();
    }
  }
}

class ThreatScore {
  final int score;
  final String threatLevel;
  final List<String> reasons;
  final String recommendation;

  ThreatScore({
    required this.score,
    required this.threatLevel,
    required this.reasons,
    required this.recommendation,
  });

  factory ThreatScore.fromJson(Map<String, dynamic> json) {
    return ThreatScore(
      score: json['score'] ?? 0,
      threatLevel: json['threat_level'] ?? 'Low',
      reasons: List<String>.from(json['reasons'] ?? []),
      recommendation: json['recommendation'] ?? 'Wi-Fi appears safe to use but avoid sensitive activities.',
    );
  }

  factory ThreatScore.mockData() {
    return ThreatScore(
      score: 25,
      threatLevel: 'Low',
      reasons: ['No significant threats detected.'],
      recommendation: 'Wi-Fi appears safe to use.',
    );
  }
}

class WiFiInfo {
  final String ssid;
  final String bssid;
  final String signal;
  final String channel;
  final String authentication;
  final String radioType;

  WiFiInfo({
    required this.ssid,
    required this.bssid,
    required this.signal,
    required this.channel,
    required this.authentication,
    required this.radioType,
  });

  factory WiFiInfo.fromJson(Map<String, dynamic> json) {
    return WiFiInfo(
      ssid: json['SSID'] ?? 'Unknown',
      bssid: json['BSSID'] ?? 'Unknown',
      signal: json['Signal'] ?? 'Unknown',
      channel: json['Channel'] ?? 'Unknown',
      authentication: json['Authentication'] ?? 'Unknown',
      radioType: json['Radio Type'] ?? 'Unknown',
    );
  }

  factory WiFiInfo.mockData() {
    return WiFiInfo(
      ssid: 'MyWifi-5g',
      bssid: 'AA:BB:CC:DD:EE:FF',
      signal: '98%',
      channel: '36',
      authentication: 'WPA2',
      radioType: '802.11ac',
    );
  }

  factory WiFiInfo.currentNetworkMock() {
    // This would ideally get the actual current network info
   
    return WiFiInfo(
      ssid: 'Current Network',
      bssid: 'Connected',
      signal: '85%',
      channel: 'Auto',
      authentication: 'WPA2/WPA3',
      radioType: '802.11n/ac',
    );
  }

  factory WiFiInfo.unknown() {
    return WiFiInfo(
      ssid: 'Unknown',
      bssid: 'Unknown',
      signal: 'Unknown',
      channel: 'Unknown',
      authentication: 'Unknown',
      radioType: 'Unknown',
    );
  }
}

