import 'dart:convert';
import 'package:http/http.dart' as http;

class WiFiService {
  static const String baseUrl = 'http://127.0.0.1:5001'; // Backend URL

  // Get current WiFi information
  static Future<WiFiInfo> getCurrentWiFiInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scan/wifi'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WiFiInfo.fromJson(data);
      } else {
        throw Exception('Failed to get WiFi info: ${response.statusCode}');
      }
    } catch (e) {
      print('WiFi info error: $e');
      // Return mock data if backend is not available
      return WiFiInfo.mockData();
    }
  }

  // Scan all security aspects of the network
  static Future<FullScanResult> scanNetwork() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scan/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FullScanResult.fromJson(data);
      } else {
        throw Exception('Failed to scan network: ${response.statusCode}');
      }
    } catch (e) {
      print('WiFi scan error: $e');
      // Return mock data if backend is not available
      return FullScanResult.mockData();
    }
  }

  // Calculate threat score based on scan results (if needed separately)
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
        Uri.parse('$baseUrl/wifi/info'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          print('WiFi info error from backend: ${data['error']}');
          return WiFiInfo.currentNetworkMock();
        }
        return WiFiInfo.fromJson(data);
      } else {
        throw Exception('Failed to get WiFi info: ${response.statusCode}');
      }
    } catch (e) {
      print('WiFi info error: $e');
      // Return a more realistic mock while backend is not available
      return WiFiInfo.currentNetworkMock();
    }
  }

  final WiFiInfo wifiInfo;
  final Map<String, dynamic> arpSpoofing;
  final Map<String, dynamic> dnsSpoofing;
  final Map<String, dynamic> rogueAp;
  final Map<String, dynamic> openPorts;
  final ThreatScore threatScore;

  FullScanResult({
    required this.wifiInfo,
    required this.arpSpoofing,
    required this.dnsSpoofing,
    required this.rogueAp,
    required this.openPorts,
    required this.threatScore,
  });

  factory FullScanResult.fromJson(Map<String, dynamic> json) {
    return FullScanResult(
      wifiInfo: WiFiInfo.fromJson(json['wifi_info'] ?? {}),
      arpSpoofing: Map<String, dynamic>.from(json['arp_spoofing'] ?? {}),
      dnsSpoofing: Map<String, dynamic>.from(json['dns_spoofing'] ?? {}),
      rogueAp: Map<String, dynamic>.from(json['rogue_ap'] ?? {}),
      openPorts: Map<String, dynamic>.from(json['open_ports'] ?? {}),
      threatScore: ThreatScore.fromJson(json['threat_score'] ?? {}),
    );
  }

  factory FullScanResult.mockData() {
    return FullScanResult(
      wifiInfo: WiFiInfo.mockData(),
      arpSpoofing: {'status': 'safe', 'detected': false},
      dnsSpoofing: {'status': 'safe', 'detected': false},
      rogueAp: {'status': 'safe', 'detected': false},
      openPorts: {
        'ports': [80, 443],
        'status': 'normal',
      },
      threatScore: ThreatScore.mockData(),
    );
  }
}

class WiFiScanResult {
  final List<int> openPorts;
  final bool arpSpoofing;
  final bool dnsSpoofing;
  final bool rogueAp;
  final String threatScore;
  final String recommendation;

  WiFiScanResult({
    required this.openPorts,
    required this.arpSpoofing,
    required this.dnsSpoofing,
    required this.rogueAp,
    required this.threatScore,
    required this.recommendation,
  });

  factory WiFiScanResult.fromJson(Map<String, dynamic> json) {
    return WiFiScanResult(
      openPorts: List<int>.from(json['open_ports'] ?? []),
      arpSpoofing: json['arp_spoofing'] ?? false,
      dnsSpoofing: json['dns_spoofing'] ?? false,
      rogueAp: json['rogue_ap'] ?? false,
      threatScore: json['threat_score'] ?? 'Low',
      recommendation: json['recommendation'] ?? 'Wi-Fi appears safe to use.',
    );
  }

  factory WiFiScanResult.mockData() {
    return WiFiScanResult(
      openPorts: [80, 443],
      arpSpoofing: false,
      dnsSpoofing: false,
      rogueAp: false,
      threatScore: 'Low',
      recommendation: 'Wi-Fi appears safe to use.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open_ports': openPorts,
      'arp_spoofing': arpSpoofing ? 'detected' : 'not_detected',
      'dns_spoofing': dnsSpoofing ? 'detected' : 'not_detected',
      'rogue_ap': rogueAp ? 'detected' : 'not_detected',
    };
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
      recommendation: json['recommendation'] ?? 'Wi-Fi appears safe to use.',
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
    // For now, let's use a more generic name
    return WiFiInfo(
      ssid: 'Current Network',
      bssid: 'Connected',
      signal: '85%',
      channel: 'Auto',
      authentication: 'WPA2/WPA3',
      radioType: '802.11n/ac',
    );
  }
}
