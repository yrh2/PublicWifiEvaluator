def scan_network():
    return {
        "open_ports": [80, 443],
        "arp_spoofing": False,
        "dns_spoofing": True,
        "rogue_ap": False,
        "threat_score": "Medium",
        "recommendation": "Use VPN and avoid sensitive activities."
    }
