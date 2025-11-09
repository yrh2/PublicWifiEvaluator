from scapy.all import sniff, DNS, DNSQR, DNSRR
from collections import defaultdict

# History of domain-IP mapping
dns_history = defaultdict(set)
spoof_alerts = []  # List to store alerts for Flask/terminal

def process_packet(packet):
    if packet.haslayer(DNS) and packet[DNS].qr == 1:  # DNS response
        domain = packet[DNSQR].qname.decode('utf-8').strip(".")
        ip = packet[DNSRR].rdata

        if isinstance(ip, bytes):
            ip = ip.decode('utf-8')

        if domain not in dns_history:
            dns_history[domain].add(ip)
            print(f"🌐 New domain: {domain} → {ip}")
        elif ip not in dns_history[domain]:
            print(f"\n🚨 DNS Spoofing Alert!")
            print(f"❗ Domain: {domain}")
            print(f"🧠 Previous IPs: {dns_history[domain]}")
            print(f"⚠️ New unexpected IP: {ip}\n")

            spoof_alerts.append({
                "domain": domain,
                "old_ips": list(dns_history[domain]),
                "new_ip": ip,
                "message": "Suspicious DNS response detected. May indicate an attack."
            })
            dns_history[domain].add(ip)

def start_dns_monitor(timeout=10):
    global spoof_alerts
    spoof_alerts = []  # Reset before sniffing

    print("🌐 Monitoring DNS responses... (Sniffing for", timeout, "seconds)")
    try:
        sniff(filter="udp port 53", prn=process_packet, timeout=timeout, store=0)
    except Exception as e:
        # Permissions/libpcap issues commonly surface here on macOS without sudo
        return {
            "status": "unknown",
            "message": f"DNS sniffing unavailable: {e}",
            "recommendation": "Run with appropriate permissions or disable DNS scan in dev"
        }

    if spoof_alerts:
        return {
            "status": "warning",
            "threat": "Possible DNS Spoofing Detected",
            "details": spoof_alerts,
            "recommendation": "Avoid entering sensitive information while using this Wi-Fi."
        }
    else:
        return {
            "status": "safe",
            "message": "No DNS spoofing detected.",
            "recommendation": "Wi-Fi appears safe for now."
        }

# === If run directly from terminal ===
if __name__ == "__main__":
    result = start_dns_monitor(timeout=10)
    print("\n=== Detection Summary ===")
    print(result)
