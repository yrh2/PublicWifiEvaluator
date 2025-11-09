from flask import Blueprint, jsonify, request
from .scanner import scan_network
from .threat_level_ai import calculate_threat_score
from .auto_scan_wifi import get_wifi_info

main = Blueprint('main', __name__)

@main.route('/')
def index():
    return jsonify({"message": "Public Wi-Fi Evaluator Backend Running"})

@main.route('/wifi/info', methods=['GET'])
def wifi_info():
    result = get_wifi_info()
    return jsonify(result)

@main.route('/scan', methods=['GET'])
def scan():
    result = scan_network()
    return jsonify(result)

@main.route('/scan/threat_score', methods=['POST'])
def get_threat_score():
    data = request.get_json()
    result = calculate_threat_score(data)
    return jsonify(result)
