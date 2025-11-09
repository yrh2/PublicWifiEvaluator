import subprocess
import platform
import re
import shutil


def get_gateway_ip():
    """Best-effort gateway IP detection across platforms (Windows/macOS/Linux)."""
    system = platform.system()
    try:
        if system == "Windows":
            try:
                output = subprocess.check_output("ipconfig", shell=True, text=True)
                lines = output.splitlines()
                for i, line in enumerate(lines):
                    if "Default Gateway" in line:
                        parts = line.split(":")
                        if len(parts) == 2 and parts[1].strip():
                            return parts[1].strip()
                        elif i + 1 < len(lines):
                            nxt = lines[i + 1].strip()
                            if nxt:
                                return nxt
            except Exception:
                pass

        elif system == "Darwin":  # macOS
            try:
                output = subprocess.check_output("route -n get default | grep 'gateway'", shell=True, text=True)
                m = re.search(r"gateway:\s*([0-9\.]+)", output)
                if m:
                    return m.group(1)
            except Exception:
                pass

        else:  # Linux and others
            # Prefer `ip route`
            try:
                output = subprocess.check_output("ip route show default", shell=True, text=True)
                m = re.search(r"default via ([0-9\.]+)", output)
                if m:
                    return m.group(1)
            except Exception:
                pass
            # Fallback to `route -n`
            try:
                output = subprocess.check_output("route -n | grep '^0.0.0.0'", shell=True, text=True)
                m = re.search(r"^0\.0\.0\.0\s+([0-9\.]+)", output)
                if m:
                    return m.group(1)
            except Exception:
                pass

        print("❌ Could not find default gateway.")
        return None
    except Exception as e:
        print("❌ Error getting gateway IP:", e)
        return None


def scan_open_ports(ip):
    print(f"🔍 Scanning open ports for {ip}...")
    try:
        if platform.system() == "Windows":
            nmap_path = r"C:\Program Files (x86)\Nmap\nmap.exe"
        else:
            nmap_path = shutil.which("nmap") or "/opt/homebrew/bin/nmap"

        if not shutil.which("nmap") and not platform.system() == "Windows":
            return {"status": "error", "message": "nmap not installed"}

        cmd = [nmap_path, "-sT", "-F", ip]
        result = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)

        open_ports = re.findall(r"(\d+)/tcp\s+open", result)
        return {"status": "ok", "open_ports": open_ports, "raw": result}
    except subprocess.CalledProcessError as e:
        return {"status": "error", "message": e.output}
    except Exception as e:
        return {"status": "error", "message": str(e)}


if __name__ == "__main__":
    gateway_ip = get_gateway_ip()
    if gateway_ip:
        result = scan_open_ports(gateway_ip)
        print(result)
