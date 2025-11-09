import subprocess
import platform
import re
from collections import defaultdict


def _parse_windows_netsh(output: str):
    networks = defaultdict(set)
    current_ssid = None
    for line in output.splitlines():
        ssid_match = re.search(r"SSID\s+\d+\s+:\s+(.*)", line)
        bssid_match = re.search(r"BSSID\s+\d+\s+:\s+([0-9A-Fa-f:]{17})", line)
        if ssid_match:
            current_ssid = ssid_match.group(1).strip()
        elif bssid_match and current_ssid:
            networks[current_ssid].add(bssid_match.group(1).strip())
    return networks


def _parse_macos_airport(output: str):
    # airport -s prints table-like rows; columns typically: SSID BSSID RSSI CHANNEL HT CC SECURITY
    networks = defaultdict(set)
    lines = output.splitlines()
    # Skip header if present
    for line in lines[1:]:
        parts = line.split()
        if len(parts) >= 2:
            # SSID may contain spaces; BSSID has fixed format xx:xx:xx:xx:xx:xx
            # Find the part that looks like a BSSID
            bssid_idx = None


def _parse_macos_system_profiler(output: str):
    """Parse system_profiler SPAirPortDataType output for network information"""
    networks = defaultdict(set)
    lines = output.splitlines()
    current_ssid = None
    
    for line in lines:
        line = line.strip()
        # Look for network names (SSIDs)
        if line and not line.startswith(' ') and ':' not in line and line != 'Wi-Fi:':
            # This might be an SSID
            current_ssid = line.strip()
        elif 'MAC Address:' in line or 'BSSID:' in line:
            # Extract MAC/BSSID
            bssid_match = re.search(r'([0-9A-Fa-f:]{17})', line)
            if bssid_match and current_ssid:
                networks[current_ssid].add(bssid_match.group(1))
    
    return networks


def _parse_macos_airport(output: str):
    # airport -s prints table-like rows; columns typically: SSID BSSID RSSI CHANNEL HT CC SECURITY
    networks = defaultdict(set)
    lines = output.splitlines()
    # Skip header if present
    for line in lines[1:]:
        parts = line.split()
        if len(parts) >= 2:
            # SSID may contain spaces; BSSID has fixed format xx:xx:xx:xx:xx:xx
            # Find the part that looks like a BSSID
            bssid_idx = None
            for i, p in enumerate(parts):
                if re.fullmatch(r"[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}", p):
                    bssid_idx = i
                    break
            if bssid_idx is not None:
                bssid = parts[bssid_idx]
                ssid = " ".join(parts[:bssid_idx]).strip()
                if ssid:
                    networks[ssid].add(bssid)
    return networks


def _parse_linux_nmcli(output: str):
    # nmcli dev wifi list outputs columns with BSSID first typically
    networks = defaultdict(set)
    lines = output.splitlines()
    for line in lines[1:]:  # skip header
        m = re.match(r"([0-9A-Fa-f:]{17})\s+(\*?\s*)?(\S.+?)\s", line)
        if m:
            bssid = m.group(1)
            ssid = m.group(3).strip()
            networks[ssid].add(bssid)
    return networks


def detect_rogue_aps():
    system = platform.system()
    try:
        if system == "Windows":
            output = subprocess.check_output("netsh wlan show networks mode=bssid", shell=True, text=True, encoding='utf-8')
            networks = _parse_windows_netsh(output)
        elif system == "Darwin":  # macOS
            try:
                # Try system_profiler as alternative to deprecated airport command
                output = subprocess.check_output(
                    "system_profiler SPAirPortDataType",
                    shell=True, text=True, encoding='utf-8'
                )
                networks = _parse_macos_system_profiler(output)
            except Exception as fallback_error:
                # Fallback to airport if available
                try:
                    output = subprocess.check_output(
                        "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s",
                        shell=True, text=True, encoding='utf-8'
                    )
                    networks = _parse_macos_airport(output)
                except Exception:
                    return {"status": "unknown", "message": f"macOS Wi-Fi scanning unavailable: {fallback_error}"}
        else:  # Linux
            try:
                output = subprocess.check_output("nmcli dev wifi list", shell=True, text=True, encoding='utf-8')
                networks = _parse_linux_nmcli(output)
            except Exception:
                # Fallback to iwlist (may require sudo)
                try:
                    output = subprocess.check_output("iwlist scan", shell=True, text=True, encoding='utf-8')
                    networks = defaultdict(set)
                    current_ssid = None
                    for line in output.splitlines():
                        essid = re.search(r'ESSID:"([^"]+)"', line)
                        ap = re.search(r"Address: ([0-9A-Fa-f:]{17})", line)
                        if essid:
                            current_ssid = essid.group(1)
                        if ap and current_ssid:
                            networks[current_ssid].add(ap.group(1))
                except Exception as e:
                    return {"status": "unknown", "message": f"Wi-Fi scan unavailable: {e}"}

        # Analyze for multiple BSSIDs per SSID
        rogue_alerts = []
        for ssid, bssids in networks.items():
            if len(bssids) > 1:
                rogue_alerts.append({
                    "ssid": ssid,
                    "bssids": list(bssids),
                    "count": len(bssids),
                    "alert": "Suspicious: Multiple BSSIDs found for same SSID"
                })

        if rogue_alerts:
            return {"status": "warning", "message": "Possible Rogue APs detected!", "data": rogue_alerts}
        else:
            return {"status": "safe", "message": "No rogue access points detected."}

    except subprocess.CalledProcessError as e:
        return {"status": "unknown", "message": f"Failed to scan networks: {e}"}
