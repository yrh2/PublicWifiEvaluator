import re


def _is_detected(value) -> bool:
    """Normalize various shapes for detection flags.
    Accepts strings like 'detected'/'warning'/'threat', or dicts with status.
    """
    if isinstance(value, dict):
        status = (value.get("status") or "").lower()
        return status in {"detected", "warning", "threat"}
    if isinstance(value, str):
        return value.lower() in {"detected", "warning", "threat"}
    return False


def _extract_open_ports(value):
    """Return a list of integer port numbers from different shapes.
    Supports:
    - list[int|str]
    - dict with key 'ports' list
    - dict with 'raw' nmap output (best-effort parse)
    """
    ports = []
    if value is None:
        return ports
    # If already a list
    if isinstance(value, list):
        for p in value:
            try:
                ports.append(int(p))
            except Exception:
                continue
        return ports
    # If dict with 'ports'
    if isinstance(value, dict):
        if isinstance(value.get("ports"), list):
            for p in value["ports"]:
                try:
                    ports.append(int(p))
                except Exception:
                    continue
            return ports
        # If dict with raw nmap text -> parse lines like '80/tcp open http'
        raw = value.get("raw") or value.get("output") or ""
        if isinstance(raw, str) and raw:
            for line in raw.splitlines():
                m = re.match(r"^(\d+)/(tcp|udp)\s+open\b", line.strip())
                if m:
                    try:
                        ports.append(int(m.group(1)))
                    except Exception:
                        pass
    return ports


def calculate_threat_score(scan_results):
    score = 0
    reasons = []

    # ARP Spoofing
    if _is_detected(scan_results.get("arp_spoofing")):
        score += 40
        reasons.append("ARP spoofing activity detected.")

    # DNS Spoofing
    if _is_detected(scan_results.get("dns_spoofing")):
        score += 30
        reasons.append("DNS spoofing activity detected.")

    # Open ports
    open_ports = _extract_open_ports(scan_results.get("open_ports"))

    high_risk = {21, 23}         # FTP & Telnet → sangat bahaya
    medium_risk = {80, 443, 1025}  # HTTP, HTTPS, RPC → boleh jadi risiko
    # selain tu kira as "other"
    high_ports = sorted({p for p in open_ports if p in high_risk})
    medium_ports = sorted({p for p in open_ports if p in medium_risk})
    other_ports = sorted({p for p in open_ports if p not in high_risk and p not in medium_risk})

    if high_ports:
        score += 20 * len(high_ports)
        reasons.append(f"High-risk open ports: {', '.join(str(p) for p in high_ports)}")
    if medium_ports:
        score += 10 * len(medium_ports)
        reasons.append(f"Medium-risk open ports: {', '.join(str(p) for p in medium_ports)}")
    if other_ports:
        score += 5 * len(other_ports)
        reasons.append(f"Other open ports: {', '.join(str(p) for p in other_ports)}")
    # Rogue AP
    if _is_detected(scan_results.get("rogue_ap")):
        score += 30
        reasons.append("Possible rogue access point detected.")

    # Final Score Evaluation
    if score >= 70:
        level = "High"
        recommendation = "Avoid using this Wi-Fi for any sensitive activity."
    elif score >= 40:
        level = "Medium"
        recommendation = "Caution advised. Avoid entering passwords or personal info."
    else:
        level = "Low"
        recommendation = "Wi-Fi appears safe to use."

    return {
        "score": score,
        "threat_level": level,
        "reasons": reasons,
        "recommendation": recommendation,
    }