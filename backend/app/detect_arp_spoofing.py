import subprocess
import platform
import re
from scapy.all import ARP, Ether, srp


def get_gateway_ip():
    """Detect default gateway IP across platforms without invoking wrong OS tools."""
    system = platform.system()
    try:
        if system == "Windows":
            # Prefer `ipconfig` parsing; some environments require checking the next line
            output = subprocess.check_output("ipconfig", shell=True, text=True)
            lines = output.splitlines()
            for i, line in enumerate(lines):
                if "Default Gateway" in line:
                    parts = line.split(":")
                    if len(parts) == 2 and parts[1].strip():
                        gw = parts[1].strip()
                        print(f"✅ Gateway IP detected: {gw}")
                        return gw
                    # Sometimes the value is on the next line
                    if i + 1 < len(lines):
                        nxt = lines[i + 1].strip()
                        if nxt:
                            print(f"✅ Gateway IP detected: {nxt}")
                            return nxt

        elif system == "Darwin":  # macOS
            output = subprocess.check_output("route -n get default | grep 'gateway'", shell=True, text=True)
            m = re.search(r"gateway:\s*([0-9\.]+)", output)
            if m:
                gw = m.group(1)
                print(f"✅ Gateway IP detected: {gw}")
                return gw

        else:  # Linux and others
            # Try `ip route` first
            try:
                output = subprocess.check_output("ip route show default", shell=True, text=True)
                m = re.search(r"default via ([0-9\.]+)", output)
                if m:
                    gw = m.group(1)
                    print(f"✅ Gateway IP detected: {gw}")
                    return gw
            except Exception:
                pass

            # Fallback to legacy `route -n`
            try:
                output = subprocess.check_output("route -n | grep '^0.0.0.0'", shell=True, text=True)
                m = re.search(r"^0\.0\.0\.0\s+([0-9\.]+)", output)
                if m:
                    gw = m.group(1)
                    print(f"✅ Gateway IP detected: {gw}")
                    return gw
            except Exception:
                pass

        print("❌ Could not find default gateway.")
        return None
    except Exception as e:
        print("❌ Error getting gateway IP:", e)
        return None

def get_mac(ip):
    arp_request = ARP(pdst=ip)
    broadcast = Ether(dst="ff:ff:ff:ff:ff:ff")
    packet = broadcast / arp_request
    try:
        answered = srp(packet, timeout=3, verbose=False)[0]
    except Exception as e:
        # Likely a permissions issue on macOS/Linux when not run as root
        print("⚠️ ARP request failed:", e)
        return None

    if answered:
        return answered[0][1].hwsrc
    return None

def detect_arp_spoofing():
    print("🔍 Starting ARP spoofing detection...\n")
    gateway_ip = get_gateway_ip()
    if not gateway_ip:
        msg = "Unable to detect gateway IP"
        print(f"❌ {msg}")
        return {"status": "unknown", "message": msg}

    original_mac = get_mac(gateway_ip)
    if not original_mac:
        msg = "Could not retrieve MAC address of gateway (permissions or connectivity)"
        print(f"❌ {msg}")
        return {"status": "unknown", "message": msg,
                "recommendation": "Try running with elevated privileges or check network connectivity."}

    current_mac = get_mac(gateway_ip)
    if not current_mac:
        msg = "No ARP reply from gateway"
        print(f"⚠️ {msg}")
        return {"status": "warning", "message": msg}
    elif current_mac != original_mac:
        print("🚨 ALERT! ARP spoofing detected!")
        print(f"Expected MAC: {original_mac}, but got: {current_mac}")
        return {
            "status": "threat",
            "message": "ARP spoofing detected!",
            "expected_mac": original_mac,
            "received_mac": current_mac,
            "recommendation": "Avoid entering sensitive information on this network."
        }
    else:
        print("✅ No spoofing detected. Gateway MAC is unchanged.")
        return {
            "status": "safe",
            "message": "No ARP spoofing detected.",
            "gateway_ip": gateway_ip,
            "gateway_mac": original_mac
        }

# Optional: run standalone if you want to test directly
if __name__ == "__main__":
    print(detect_arp_spoofing())
