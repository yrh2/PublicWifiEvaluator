from flask import Flask, jsonify, request
from flask_cors import CORS
import traceback
from werkzeug.exceptions import HTTPException

#Scanner functions
from app.auto_scan_wifi import get_wifi_info
from app.detect_arp_spoofing import detect_arp_spoofing
from app.detect_dns_spoofing import start_dns_monitor
from app.open_port_scanner import scan_open_ports, get_gateway_ip
from app.detect_rogue_ap import detect_rogue_aps
from app.threat_level_ai import calculate_threat_score


def create_app():
    app = Flask(__name__)
    CORS(app)

    #Global error handler
    @app.errorhandler(Exception)
    def handle_error(e):
        print("🔥 ERROR:", str(e))
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500
    
    @app.errorhandler(HTTPException)
    def handle_http_exception(e):
        response = e.get_response()
        response.data = jsonify({
            "error": e.description,
            "code": e.code,
            "name": e.name
        }).get_data()
        response.content_type = "application/json"
        return response

    #Debug request
    @app.before_request
    def log_request_info():
        print("👉 Headers:", dict(request.headers))
        print("👉 Body:", request.get_data())

    @app.route("/")
    def index():
        return jsonify({"message": "Backend is running!"})

    @app.route("/scan/wifi", methods=["GET"])
    def wifi_scan():
        return jsonify(get_wifi_info())

    @app.route("/scan/arp", methods=["GET"])
    def arp_scan():
        return jsonify(detect_arp_spoofing())

    @app.route("/scan/dns", methods=["GET"])
    def dns_scan():
        results = start_dns_monitor(timeout=2)
        return jsonify(results)
    

    @app.route("/scan/open_ports", methods=["GET"])
    def port_scan():
        ip = get_gateway_ip()
        if not ip:
            return jsonify({"error": "❌ Could not find default gateway IP"}), 500
        result = scan_open_ports(ip)
        return jsonify({"ip": ip, "scan_result": result})

    @app.route("/scan/rogue_ap", methods=["GET"])
    def rogue_ap_scan():
        return jsonify(detect_rogue_aps())

    @app.route("/scan/threat_score", methods=["POST"])
    def get_threat_score():
        data = request.get_json(silent=True) 
        if not data:
            return jsonify({"error": "No JSON body received"}), 400

        result = calculate_threat_score(data)
        return jsonify(result)

    # 🔥 Combined scan endpoint
    @app.route("/scan/all", methods=["GET"])
    def scan_all():
        """Run all scans but never fail the whole endpoint.
        Returns 200 with best-effort data and embeds any step errors.
        """
        result = {}

        # WiFi info (best-effort)
        try:
            result["wifi_info"] = get_wifi_info()
        except Exception as e:
            result["wifi_info"] = {"status": "error", "message": str(e)}

        # ARP spoofing
        try:
            result["arp_spoofing"] = detect_arp_spoofing()
        except Exception as e:
            result["arp_spoofing"] = {"status": "unknown", "message": str(e)}

        # DNS spoofing (sniff may require privileges); handled inside function too
        try:
            result["dns_spoofing"] = start_dns_monitor(timeout=2)
        except Exception as e:
            result["dns_spoofing"] = {"status": "unknown", "message": str(e)}

        # Rogue APs (best-effort)
        try:
            result["rogue_ap"] = detect_rogue_aps()
        except Exception as e:
            result["rogue_ap"] = {"status": "unknown", "message": str(e)}

        # Open ports (graceful if gateway/nmap is unavailable)
        try:
            ip = get_gateway_ip()
            if not ip:
                result["open_ports"] = {"status": "unknown", "message": "No gateway IP"}
            else:
                ports_scan = scan_open_ports(ip)
                result["open_ports"] = ports_scan if ports_scan is not None else {"status": "unknown", "message": "scan failed"}
        except Exception as e:
            result["open_ports"] = {"status": "unknown", "message": str(e)}

        # Threat score (optional, don't fail)
        try:
            # Provide a minimal, shape-agnostic payload
            threat_input = {
                "arp_spoofing": result.get("arp_spoofing"),
                "dns_spoofing": result.get("dns_spoofing"),
                "rogue_ap": result.get("rogue_ap"),
                # If ports are provided as list, use it; else empty list
                "open_ports": result.get("open_ports") if isinstance(result.get("open_ports"), list) else []
            }
            result["threat_score"] = calculate_threat_score(threat_input)
        except Exception as e:
            result["threat_score"] = {"status": "unknown", "message": str(e)}

        return jsonify(result), 200

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True, host="0.0.0.0", port=5000)
