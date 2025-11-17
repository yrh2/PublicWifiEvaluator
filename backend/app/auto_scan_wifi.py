import subprocess
import re
import platform
import json
import os

def get_wifi_info():
    try:
        system = platform.system()
        
        if system == "Darwin":  # macOS
            return get_wifi_info_macos()
        elif system == "Windows":
            return get_wifi_info_windows()
        elif system == "Linux":
            return get_wifi_info_linux()
        else:
            return {"error": f"Unsupported operating system: {system}"}
    
    except Exception as e:
        return {"error": str(e)}

def get_wifi_info_macos():
    try:
        airport_path = "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
        wifi_info = {}

        def find_wifi_device():
            try:
                out = subprocess.check_output("networksetup -listallhardwareports", shell=True, text=True)
                dev = None
                lines = out.splitlines()
                for i, line in enumerate(lines):
                    if "Hardware Port: Wi-Fi" in line or "Hardware Port: AirPort" in line:
                        for j in range(i, min(i + 5, len(lines))):
                            if lines[j].strip().startswith("Device:"):
                                dev = lines[j].split(":", 1)[1].strip()
                                return dev
            except Exception:
                pass
            # Common default
            return "en0"

        device = find_wifi_device()

        # Preferred method: airport -I (if available)
        try:
            if os.path.exists(airport_path):
                result = subprocess.check_output(f"{airport_path} -I", shell=True, text=True)
                for line in result.split('\n'):
                    if ':' in line:
                        key, value = line.strip().split(':', 1)
                        key = key.strip(); value = value.strip()
                        if key == 'SSID':
                            wifi_info['SSID'] = value
                        elif key == 'BSSID':
                            wifi_info['BSSID'] = value
                        elif key == 'agrCtlRSSI':
                            try:
                                rssi = int(value)
                                if rssi >= -50:
                                    signal_percent = 100
                                elif rssi <= -100:
                                    signal_percent = 0
                                else:
                                    signal_percent = 2 * (rssi + 100)
                                wifi_info['Signal'] = f"{signal_percent}%"
                            except Exception:
                                pass
                        elif key == 'channel':
                            wifi_info['Channel'] = value
                        elif key == 'CC':
                            wifi_info['Country Code'] = value
        except Exception:
            # ignore and fallback below
            pass

        # Fallback: networksetup for SSID
        if 'SSID' not in wifi_info:
            try:
                out = subprocess.check_output(f"networksetup -getairportnetwork {device}", shell=True, text=True)
                m = re.search(r"Current Wi-Fi Network: (.*)", out)
                if m:
                    ssid_value = m.group(1).strip()
                    # Check if actually connected (not "You are not associated with an AirPort network")
                    if ssid_value and "not associated" not in ssid_value.lower():
                        wifi_info['SSID'] = ssid_value
            except Exception:
                pass

        # Try alternative method if still no SSID
        if 'SSID' not in wifi_info:
            try:
                # Use system_profiler as another fallback
                out = subprocess.check_output("system_profiler SPAirPortDataType", shell=True, text=True)
                # Look for current network info
                lines = out.split('\n')
                for i, line in enumerate(lines):
                    if 'Current Network Information:' in line:
                        # The SSID is usually on the next line after "Current Network Information:"
                        if i + 1 < len(lines):
                            next_line = lines[i + 1].strip()
                            # Extract SSID name from line like "            Amoii_5GHz:"
                            ssid_match = re.search(r'^\s*([^:]+):', next_line)
                            if ssid_match:
                                ssid_candidate = ssid_match.group(1).strip()
                                # Avoid false matches like "Network Type: Infrastructure"
                                if ssid_candidate and not any(keyword in ssid_candidate.lower() for keyword in ['phy mode', 'channel', 'country', 'network type', 'security', 'signal']):
                                    wifi_info['SSID'] = ssid_candidate
                                    
                                    # Try to extract additional info from following lines
                                    for j in range(i + 2, min(i + 15, len(lines))):
                                        line_content = lines[j].strip()
                                        if 'PHY Mode:' in line_content:
                                            wifi_info['Radio Type'] = line_content.split(':', 1)[1].strip()
                                        elif 'Channel:' in line_content:
                                            wifi_info['Channel'] = line_content.split(':', 1)[1].strip()
                                        elif 'Security:' in line_content:
                                            wifi_info['Authentication'] = line_content.split(':', 1)[1].strip()
                                        elif 'Signal / Noise:' in line_content:
                                            # Extract signal strength from "-50 dBm / -93 dBm"
                                            signal_match = re.search(r'(-?\d+)\s*dBm', line_content)
                                            if signal_match:
                                                dbm = int(signal_match.group(1))
                                                # Convert dBm to percentage
                                                if dbm >= -30:
                                                    signal_percent = 100
                                                elif dbm <= -90:
                                                    signal_percent = 0
                                                else:
                                                    signal_percent = max(0, min(100, 2 * (dbm + 100)))
                                                wifi_info['Signal'] = f"{signal_percent}%"
                                    break
            except Exception:
                pass

        # Populate defaults
        wifi_info.setdefault('Signal', 'Unknown')
        wifi_info.setdefault('Channel', 'Unknown')
        wifi_info.setdefault('Authentication', 'Unknown')
        wifi_info.setdefault('Radio Type', 'Unknown')

        if 'SSID' in wifi_info and wifi_info['SSID']:
            return wifi_info
        else:
            return {"error": "Wi-Fi not connected or SSID not found."}

    except subprocess.CalledProcessError as e:
        return {"error": f"Command failed: {e}"}
    except Exception as e:
        return {"error": f"Error getting WiFi info: {e}"}

def get_wifi_info_windows():
    try:
        result = subprocess.check_output("netsh wlan show interfaces", shell=True, text=True, encoding='utf-8')

        # Parse the relevant fields
        ssid = re.search(r"^\s*SSID\s*:\s(.+)", result, re.MULTILINE)
        bssid = re.search(r"^\s*AP BSSID\s*:\s(.+)", result, re.MULTILINE)
        signal = re.search(r"^\s*Signal\s*:\s(.+)", result, re.MULTILINE)
        channel = re.search(r"^\s*Channel\s*:\s(.+)", result, re.MULTILINE)
        auth = re.search(r"^\s*Authentication\s*:\s(.+)", result, re.MULTILINE)
        radio = re.search(r"^\s*Radio type\s*:\s(.+)", result, re.MULTILINE)

        # Return parsed info
        if ssid and bssid:
            return {
                "SSID": ssid.group(1).strip(),
                "BSSID": bssid.group(1).strip(),
                "Signal": signal.group(1).strip() if signal else "N/A",
                "Channel": channel.group(1).strip() if channel else "N/A",
                "Authentication": auth.group(1).strip() if auth else "N/A",
                "Radio Type": radio.group(1).strip() if radio else "N/A"
            }
        else:
            return {"error": "Wi-Fi not connected or missing required details."}

    except subprocess.CalledProcessError as e:
        return {"error": f"Subprocess failed: {e}"}
    except Exception as e:
        return {"error": str(e)}

def get_wifi_info_linux():
    try:
        # Try iwconfig first
        result = subprocess.check_output("iwconfig", shell=True, text=True, stderr=subprocess.DEVNULL)
        
        # Parse iwconfig output
        wifi_info = {}
        lines = result.split('\n')
        for line in lines:
            if 'ESSID:' in line:
                essid_match = re.search(r'ESSID:"([^"]+)"', line)
                if essid_match:
                    wifi_info['SSID'] = essid_match.group(1)
            elif 'Access Point:' in line:
                bssid_match = re.search(r'Access Point: ([A-Fa-f0-9:]{17})', line)
                if bssid_match:
                    wifi_info['BSSID'] = bssid_match.group(1)
            elif 'Signal level=' in line:
                signal_match = re.search(r'Signal level=(-?\d+)', line)
                if signal_match:
                    # Convert to percentage
                    signal_dbm = int(signal_match.group(1))
                    if signal_dbm >= -50:
                        signal_percent = 100
                    elif signal_dbm <= -100:
                        signal_percent = 0
                    else:
                        signal_percent = 2 * (signal_dbm + 100)
                    wifi_info['Signal'] = f"{signal_percent}%"
        
        # Add default values for missing info
        wifi_info.setdefault('Channel', 'Unknown')
        wifi_info.setdefault('Authentication', 'Unknown')
        wifi_info.setdefault('Radio Type', 'Unknown')
        
        if 'SSID' in wifi_info:
            return wifi_info
        else:
            return {"error": "Wi-Fi not connected or SSID not found."}
            
    except subprocess.CalledProcessError:
        return {"error": "iwconfig command failed or not available"}
    except Exception as e:
        return {"error": str(e)}

# Test this directly
if __name__ == "__main__":
    wifi_info = get_wifi_info()
    print("\n📡 Current Wi-Fi Info:")
    print(json.dumps(wifi_info, indent=2))


