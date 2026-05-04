import os
import sys
import re
import yaml
import subprocess
from datetime import datetime
from openai import OpenAI

REPORTS_DIR = "/reports"
CONFIG_PATH = "/config/checks.yaml"

# Mapping of data keys to human-readable check labels
CHECK_LABELS = {
    'zpool_status': 'ZFS Pool Status (zpool status)',
    'zpool_list': 'ZFS Pool List (zpool list)',
    'smart': 'Disk SMART Health',
    'journal': 'Journal Errors (last 7 days, priority err..emerg)',
    'oom_events': 'OOM Events (dmesg + journalctl)',
    'dmesg_anomalies': 'Dmesg Anomalies (err/warn level)',
    'kubernetes_health': 'Kubernetes Cluster Health',
    'system_updates': 'System Updates (apt list --upgradable)',
    'service_status': 'Service Status (systemctl is-active/is-enabled)',
    'failed_units': 'Failed Systemd Units (systemctl --failed)',
    'system_health': 'System Health (disk/memory/load/uptime)',
    'inode_usage': 'Inode Usage (df -i)',
    'host_logs': 'Host Log Analysis (/var/log)',
}

# Define the section order and which data keys belong to each section.
# The AI analysis report will use these exact section headers.
SECTIONS = [
    ("System Health", ["system_health"]),
    ("System Updates", ["system_updates"]),
    ("Service Status", ["service_status"]),
    ("Failed Systemd Units", ["failed_units"]),
    ("Inode Usage", ["inode_usage"]),
    ("ZFS Pool Health", ["zpool_status", "zpool_list"]),
    ("Disk SMART Health", ["smart"]),
    ("Journal Errors", ["journal"]),
    ("OOM Events", ["oom_events"]),
    ("Dmesg Anomalies", ["dmesg_anomalies"]),
    ("Host Log Analysis", ["host_logs"]),
    ("Kubernetes Health", ["kubernetes_health"]),
]

def run_host_command(cmd):
    """Runs a command on the K8s node via nsenter"""
    try:
        full_cmd = f"nsenter -t 1 -m -u -i -n {cmd}"
        result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, timeout=60)
        return result.stdout.strip() if result.returncode == 0 else f"Error: {result.stderr}"
    except Exception as e:
        return f"Exception: {str(e)}"

def run_local_command(cmd, timeout=30):
    """Run a command locally in the container."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip() if result.returncode == 0 else f"Error: {result.stderr}"
    except Exception as e:
        return f"Exception: {str(e)}"


def analyze_host_logs():
    """Analyze host log files from /host/logs for past 7 days."""
    import os
    from datetime import datetime, timedelta

    log_path = "/host/logs"
    if not os.path.exists(log_path):
        return "Host logs directory not mounted."

    # Find log files modified in last 7 days
    # Use find command to list files (including compressed)
    cmd = f"find {log_path} -type f \\( -name '*.log' -o -name '*.log.*' -o -name '*log' \\) -mtime -7"
    result = run_local_command(cmd, timeout=30)
    if result.startswith("Error:") or result.startswith("Exception:"):
        return f"Error finding log files: {result}"
    files = [f.strip() for f in result.splitlines() if f.strip()]

    if not files:
        return "No recent log files found."

    summary = []
    total_lines = 0
    total_errors = 0
    total_warnings = 0
    all_error_messages = []

    # Limit to 20 files to avoid overload
    for file_path in files[:20]:
        # Determine decompression command
        if file_path.endswith('.gz'):
            cat_cmd = f"zcat {file_path}"
        elif file_path.endswith('.xz'):
            cat_cmd = f"xzcat {file_path}"
        elif file_path.endswith('.bz2'):
            cat_cmd = f"bzcat {file_path}"
        else:
            cat_cmd = f"cat {file_path}"

        # Count lines
        line_out = run_local_command(f"{cat_cmd} | wc -l", timeout=15)
        line_count = int(line_out.strip() if line_out.strip().isdigit() else 0)
        total_lines += line_count

        # Count errors (case-insensitive)
        error_out = run_local_command(f"{cat_cmd} | grep -i -c 'error\\|fail\\|crit\\|alert\\|emerg'", timeout=15)
        error_count = int(error_out.strip() if error_out.strip().isdigit() else 0)
        total_errors += error_count

        # Count warnings
        warn_out = run_local_command(f"{cat_cmd} | grep -i -c 'warn'", timeout=15)
        warning_count = int(warn_out.strip() if warn_out.strip().isdigit() else 0)
        total_warnings += warning_count

        # Extract unique error messages (first 100)
        if error_count > 0:
            # Get lines containing error/fail etc., strip timestamps, get top 5
            # Use awk to remove leading timestamp (pattern: month day time)
            unique_errors = run_local_command(
                f"{cat_cmd} | grep -i 'error\\|fail\\|crit\\|alert\\|emerg' | head -100 | "
                "awk '{{$1=$2=$3=\"\"; print $0}}' | sed 's/^   //' | sort | uniq -c | sort -nr | head -5",
                timeout=20
            )
            if unique_errors and not unique_errors.startswith("Error:") and not unique_errors.startswith("Exception:"):
                all_error_messages.append(f"=== {os.path.basename(file_path)} ===\n{unique_errors}")

        summary.append(f"{os.path.basename(file_path)}: lines={line_count}, errors={error_count}, warnings={warning_count}")

    # Overall top error messages across all files (combined)
    # Could combine but heavy; skip for now.

    result = f"Analyzed {len(files)} recent log files (showing first {min(len(files), 20)}).\n"
    result += f"Total lines: {total_lines}, errors: {total_errors}, warnings: {total_warnings}\n\n"

    # List of files analyzed
    analyzed_files = files[:20]
    result += f"Files analyzed ({len(analyzed_files)}):\n"
    for i, file_path in enumerate(analyzed_files, 1):
        # Show relative path from /host/logs
        rel_path = os.path.relpath(file_path, log_path)
        result += f"  {i}. {rel_path}\n"
    result += "\n"

    result += "Per file summary:\n" + "\n".join(summary) + "\n\n"
    if all_error_messages:
        result += "Top error messages per file:\n" + "\n".join(all_error_messages)
    return result


def gather_data(input_config):
    data = {}
    if input_config['checks'].get('zfs_health'):
        print("Gathering ZFS data...")
        data['zpool_status'] = run_host_command("zpool status")
        data['zpool_list'] = run_host_command("zpool list")

    if input_config['checks'].get('smart_attributes'):
        print("Gathering SMART data...")
        # Discover disks
        disks_out = run_host_command("lsblk -nd -o NAME")
        disks = [d for d in disks_out.splitlines() if d.startswith("sd") or d.startswith("nvme")]
        smart_data = []
        for disk in disks:
            # Get SMART health status
            health = run_host_command(f"smartctl -H /dev/{disk} | grep 'SMART overall-health'")
            smart_data.append(f"/dev/{disk}: {health}")
        data['smart'] = "\n".join(smart_data)

    if input_config['checks'].get('journal_errors'):
        print("Gathering journal errors...")
        data['journal'] = run_host_command("journalctl --since '7 days ago' -p err..emerg --no-pager | tail -n 100")

    if input_config['checks'].get('oom_events'):
        print("Checking OOM events...")
        dmesg_oom = run_host_command("dmesg -T 2>/dev/null | grep -i 'oom\\|out of memory\\|killed process' | tail -20")
        journal_oom = run_host_command("journalctl --since '7 days ago' --no-pager 2>/dev/null | grep -i 'oom\\|out of memory\\|killed process' | tail -20")
        data['oom_events'] = f"=== DMESG OOM ===\n{dmesg_oom or 'None found'}\n\n=== JOURNAL OOM ===\n{journal_oom or 'None found'}"

    if input_config['checks'].get('dmesg_anomalies'):
        print("Checking dmesg anomalies...")
        data['dmesg_anomalies'] = run_host_command("dmesg -T --level=err,warn 2>/dev/null | tail -50")

    if input_config['checks'].get('kubernetes_node_health'):
        print("Checking Kubernetes node health...")
        try:
            from kubernetes import client, config as kube_config
            # Load in-cluster configuration
            kube_config.load_incluster_config()
            v1 = client.CoreV1Api()

            # Node health
            nodes = v1.list_node()
            node_info = []
            for node in nodes.items:
                conditions = {cond.type: cond.status for cond in node.status.conditions}
                node_info.append(f"Node: {node.metadata.name}")
                node_info.append(f"  Status: {conditions.get('Ready', 'Unknown')}")
                node_info.append(f"  Kubernetes Version: {node.status.node_info.kubelet_version}")
                node_info.append(f"  OS: {node.status.node_info.os_image}")
                node_info.append(f"  Container Runtime: {node.status.node_info.container_runtime_version}")
                # Check for memory pressure, disk pressure, PID pressure
                for cond_type in ['MemoryPressure', 'DiskPressure', 'PIDPressure']:
                    if cond_type in conditions:
                        node_info.append(f"  {cond_type}: {conditions[cond_type]}")
                node_info.append("")

            # Pod health - count by status
            pods = v1.list_pod_for_all_namespaces()
            pod_status = {}
            for pod in pods.items:
                status = pod.status.phase
                pod_status[status] = pod_status.get(status, 0) + 1

            pod_summary = []
            for status, count in sorted(pod_status.items()):
                pod_summary.append(f"{status}: {count}")

            # Recent events (last hour)
            from datetime import datetime, timedelta
            now = datetime.utcnow()
            one_hour_ago = now - timedelta(hours=1)
            events = v1.list_event_for_all_namespaces()
            recent_events = []
            for event in events.items:
                event_time = event.last_timestamp or event.event_time
                if event_time and event_time.replace(tzinfo=None) > one_hour_ago.replace(tzinfo=None):
                    if event.type in ['Warning', 'Error']:
                        recent_events.append(f"{event.type}: {event.reason} - {event.message} (namespace: {event.metadata.namespace})")

            # Namespace status
            namespaces = v1.list_namespace()
            namespace_status = []
            for ns in namespaces.items:
                namespace_status.append(f"{ns.metadata.name}: {ns.status.phase}")

            # Certificate expiry (cert-manager)
            cert_expiry_data = "cert-manager Certificate check not enabled"
            if input_config['checks'].get('certificate_expiry'):
                try:
                    custom_api = client.CustomObjectsApi()
                    certs = custom_api.list_cluster_custom_object(
                        group="cert-manager.io", version="v1", plural="certificates"
                    )
                    cert_info = []
                    now = datetime.utcnow()
                    for c in certs.get('items', []):
                        name = c['metadata']['name']
                        ns_name = c['metadata']['namespace']
                        not_after = c.get('status', {}).get('notAfter', 'Unknown')
                        if not_after != 'Unknown':
                            expiry = datetime.fromisoformat(not_after.replace('Z', '+00:00')).replace(tzinfo=None)
                            days_left = (expiry - now).days
                        else:
                            days_left = 'N/A'
                        conditions = c.get('status', {}).get('conditions', [])
                        ready_cond = next((cond for cond in conditions if cond.get('type') == 'Ready'), {})
                        ready_status = ready_cond.get('status', 'Unknown')
                        cert_info.append(f"{ns_name}/{name}: expires={not_after} ({days_left}d remaining), ready={ready_status}")
                    cert_expiry_data = "\n".join(cert_info) if cert_info else "No certificates found"
                except Exception as e:
                    cert_expiry_data = f"Error querying certificates: {str(e)}"

            # Node resource pressure (metrics-server)
            node_metrics_data = "Node metrics check not enabled"
            if input_config['checks'].get('node_resource_pressure'):
                try:
                    custom_api = client.CustomObjectsApi()
                    metrics = custom_api.list_cluster_custom_object(
                        group="metrics.k8s.io", version="v1beta1", plural="nodes"
                    )
                    metrics_info = []
                    for node_metric in metrics.get('items', []):
                        node_name = node_metric['metadata']['name']
                        cpu_raw = node_metric['usage']['cpu']
                        mem_raw = node_metric['usage']['memory']
                        if cpu_raw.endswith('n'):
                            cpu_cores = int(cpu_raw.rstrip('n')) / 1_000_000_000
                        elif cpu_raw.endswith('u'):
                            cpu_cores = int(cpu_raw.rstrip('u')) / 1_000_000
                        elif cpu_raw.endswith('m'):
                            cpu_cores = int(cpu_raw.rstrip('m')) / 1_000
                        else:
                            cpu_cores = 0
                        if mem_raw.endswith('Ki'):
                            mem_gb = int(mem_raw.rstrip('Ki')) / (1024 * 1024)
                        elif mem_raw.endswith('Mi'):
                            mem_gb = int(mem_raw.rstrip('Mi')) / 1024
                        elif mem_raw.endswith('Gi'):
                            mem_gb = int(mem_raw.rstrip('Gi'))
                        else:
                            mem_gb = 0
                        metrics_info.append(f"{node_name}: CPU={cpu_cores:.2f} cores, Memory={mem_gb:.2f} Gi")
                    node_metrics_data = "\n".join(metrics_info) if metrics_info else "No metrics available"
                except Exception as e:
                    node_metrics_data = f"Error fetching node metrics: {str(e)}"

            data['kubernetes_health'] = f"=== NODES ===\n{''.join(node_info)}\n=== POD STATUS ===\n{', '.join(pod_summary)}\n\n=== RECENT EVENTS (last hour) ===\n{chr(10).join(recent_events) if recent_events else 'No recent warning/error events'}\n\n=== NAMESPACES ===\n{chr(10).join(namespace_status)}\n\n=== CERTIFICATE EXPIRY ===\n{cert_expiry_data}\n\n=== NODE METRICS ===\n{node_metrics_data}"

        except Exception as e:
            data['kubernetes_health'] = f"Error querying Kubernetes API: {str(e)}"

    if input_config['checks'].get('system_updates'):
        print("Checking system updates...")
        # Check apt lists age (read-only)
        import os
        import datetime
        apt_lists_age = "N/A"
        apt_lists_path = "/host/apt/lists"
        if os.path.exists(apt_lists_path):
            try:
                mtime = os.path.getmtime(apt_lists_path)
                age_days = (datetime.datetime.now().timestamp() - mtime) / 86400
                apt_lists_age = f"{age_days:.1f} days"
            except Exception as e:
                apt_lists_age = f"Error: {str(e)}"
        # Check upgradable packages (read-only command)
        apt_upgradable = run_host_command("apt list --upgradable 2>/dev/null | head -30")
        security_updates = run_host_command("apt list --upgradable 2>/dev/null | grep -i security | wc -l")
        total_upgradable = run_host_command("apt list --upgradable 2>/dev/null | wc -l")
        # Check if reboot required
        reboot_required = run_host_command("test -f /var/run/reboot-required && echo 'Yes' || echo 'No'")
        data['system_updates'] = f"APT lists last updated: {apt_lists_age}\nReboot required: {reboot_required}\n\nUpgradable Packages ({total_upgradable.strip()} total, {security_updates.strip()} security):\n{apt_upgradable}"

    if input_config['checks'].get('service_status'):
        print("Checking service status...")
        # Check critical services
        services = ["ssh", "cron", "systemd-timesyncd", "samba", "containerd", "kubelet", "docker", "kube-proxy", "ntp", "ufw"]
        service_status = []
        for svc in services:
            status = run_host_command(f"systemctl is-active {svc} 2>/dev/null || echo 'inactive'")
            enabled = run_host_command(f"systemctl is-enabled {svc} 2>/dev/null || echo 'unknown'")
            service_status.append(f"{svc}: active={status.strip()}, enabled={enabled.strip()}")
        data['service_status'] = "\n".join(service_status)

    if input_config['checks'].get('failed_units'):
        print("Checking failed systemd units...")
        data['failed_units'] = run_host_command("systemctl --failed --no-pager --no-legend 2>/dev/null || echo 'All units healthy'")

    if input_config['checks'].get('system_health'):
        print("Checking system health...")
        # Disk usage
        disk_usage = run_host_command("df -h / /home /var /mnt 2>/dev/null | grep -v '^Filesystem' | head -20")
        # Memory usage
        memory = run_host_command("free -h | head -2")
        # Load average
        load = run_host_command("cat /proc/loadavg")
        # Uptime
        uptime = run_host_command("uptime -p")
        data['system_health'] = f"Uptime: {uptime}\nLoad: {load}\nMemory:\n{memory}\nDisk usage:\n{disk_usage}"

    if input_config['checks'].get('inode_usage'):
        print("Checking inode usage...")
        data['inode_usage'] = run_host_command("df -i / /home /var /mnt /mnt/hdd /mnt/ssd 2>/dev/null | grep -v '^Filesystem' | head -20")

    if input_config['checks'].get('host_log_analysis'):
        print("Analyzing host logs...")
        data['host_logs'] = analyze_host_logs()

    return data

def insert_raw_data_into_report(report, data):
    """Insert raw command output expandable sections into the AI report per section."""
    import re

    # Build a mapping from section title -> list of data keys
    section_data_map = {title: keys for title, keys in SECTIONS}

    # Split the report at ## headers (keep the delimiter on each part)
    # The first segment is everything before the first ## (summary table area)
    parts = re.split(r'\n(?=## )', report)

    new_parts = []
    for part in parts:
        new_parts.append(part)

        # Extract the section title from the first line of this part
        first_line = part.strip().split('\n')[0] if part.strip() else ''
        if first_line.startswith('## '):
            section_title = first_line[3:].strip()
            data_keys = section_data_map.get(section_title)
            if data_keys:
                raw_blocks = []
                for key in data_keys:
                    val = data.get(key)
                    if val:
                        label = CHECK_LABELS.get(key, key.replace('_', ' ').title())
                        raw_blocks.append(
                            f"<details>\n<summary>{label}</summary>\n\n"
                            f"```\n{val}\n```\n\n"
                            f"</details>\n"
                        )
                if raw_blocks:
                    new_parts.append("\n" + "\n".join(raw_blocks) + "\n")

    # Also append any leftover data keys that didn't match a section
    matched_keys = set()
    for title, keys in section_data_map.items():
        matched_keys.update(keys)
    unmatched = {k: v for k, v in data.items() if k not in matched_keys and v}
    if unmatched:
        raw_blocks = []
        for key, val in unmatched.items():
            label = CHECK_LABELS.get(key, key.replace('_', ' ').title())
            raw_blocks.append(
                f"<details>\n<summary>{label}</summary>\n\n"
                f"```\n{val}\n```\n\n"
                f"</details>\n"
            )
        new_parts.append("\n## Additional Raw Data\n\n" + "\n".join(raw_blocks))

    return "\n".join(new_parts)


def run_nmap_scan(target, scan_args, timeout=900):
    """Run an nmap scan against a target and return the output."""
    try:
        cmd = f"nmap {scan_args} {target} 2>&1"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        output = result.stdout or ""
        if result.stderr:
            output += f"\n--- STDERR ---\n{result.stderr}"
        return output if output.strip() else f"Error: no output from nmap (exit code {result.returncode})"
    except subprocess.TimeoutExpired:
        return "Error: Scan timed out after {} seconds. Try a quicker scan type.".format(timeout)
    except FileNotFoundError:
        return "Error: nmap not found. Ensure it is installed in the container."
    except Exception as e:
        return f"Exception: {str(e)}"


def discover_external_ips():
    """Discover external IPv4 and IPv6 addresses.

    Tries external echo services first, then falls back to querying the
    local Kubernetes node and host interfaces for IPv6 addresses.
    """
    import urllib.request
    import ipaddress
    import os

    result = {"ipv4": None, "ipv6": None, "error": None}

    # --- IPv4 via external echo services ---
    for svc in ["https://api.ipify.org", "https://checkip.amazonaws.com", "https://ipv4.icanhazip.com"]:
        try:
            req = urllib.request.Request(svc, headers={"User-Agent": "curl/8.0"})
            resp = urllib.request.urlopen(req, timeout=10)
            ip = resp.read().decode("utf-8").strip()
            if ip:
                result["ipv4"] = ip
                break
        except Exception:
            continue

    # --- IPv6: try echo services, then K8s node, then host interfaces ---
    for svc in ["https://api6.ipify.org", "https://v6.ident.me", "https://ipv6.icanhazip.com"]:
        try:
            req = urllib.request.Request(svc, headers={"User-Agent": "curl/8.0"})
            resp = urllib.request.urlopen(req, timeout=10)
            ip = resp.read().decode("utf-8").strip()
            if ip:
                result["ipv6"] = ip
                break
        except Exception:
            continue

    if not result["ipv6"]:
        # Try the Kubernetes API for the node's IPv6 addresses
        try:
            from kubernetes import client, config as kube_config
            kube_config.load_incluster_config()
            v1 = client.CoreV1Api()
            node_name = os.environ.get("KUBERNETES_NODE_NAME")
            if node_name:
                node = v1.read_node(node_name)
            else:
                # Fall back to listing nodes
                nodes = v1.list_node().items
                if nodes:
                    node = nodes[0]
                else:
                    node = None

            if node and node.status.addresses:
                for addr in node.status.addresses:
                    try:
                        parsed = ipaddress.ip_address(addr.address)
                        if isinstance(parsed, ipaddress.IPv6Address):
                            if not parsed.is_link_local and not parsed.is_loopback:
                                result["ipv6"] = str(parsed)
                                result["_source"] = "k8s-node"
                                break
                    except ValueError:
                        continue
        except Exception:
            pass

    if not result["ipv6"]:
        # Check host interfaces via nsenter for any IPv6 (including link-local)
        try:
            nsenter_result = subprocess.run(
                "nsenter -t 1 -n -- cat /proc/net/if_inet6 2>/dev/null",
                shell=True, capture_output=True, text=True, timeout=10
            )
            addrs = [a.strip() for a in nsenter_result.stdout.splitlines() if a.strip()]
            global_addrs = []
            link_local_addrs = []
            for line in addrs:
                parts = line.split()
                if len(parts) < 6:
                    continue
                raw_hex = parts[0]
                iface = parts[5]
                # Reconstruct IPv6 from hex (8 groups of 4 hex digits)
                addr_str = ":".join(raw_hex[i:i+4] for i in range(0, 32, 4))
                try:
                    parsed = ipaddress.IPv6Address(addr_str)
                except Exception:
                    continue
                if parsed.is_global:
                    global_addrs.append((str(parsed), iface))
                elif parsed.is_link_local:
                    link_local_addrs.append((str(parsed), iface))

            if global_addrs:
                result["ipv6"] = global_addrs[0][0]
                result["_source"] = f"host-interface ({global_addrs[0][1]})"

            if not global_addrs and link_local_addrs:
                result["_link_local"] = link_local_addrs[0][0]
        except Exception:
            pass

    if not result["ipv4"] and not result["ipv6"]:
        result["error"] = "Could not discover external IPs from any source."
    elif not result["ipv4"]:
        result["error"] = "Could not discover external IPv4 address."
    elif not result["ipv6"]:
        link_local = result.get("_link_local", "")
        base_msg = ("No global IPv6 address found on this node. The node has link-local IPv6 "
                     "only — your public IPv6 is likely on your router/firewall, not the K8s node.")
        if link_local:
            base_msg += f" (link-local: {link_local})"
        base_msg += " Enter your IPv6 address manually."
        result["error"] = base_msg

    return result


def analyze_pentest_results(scan_data, api_key):
    """Send pentest scan results to AI for security analysis."""
    try:
        import httpx
        http_client = httpx.Client()
        client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com", http_client=http_client)
    except Exception:
        client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com")

    prompt = (
        "You are a professional security analyst. Review the following nmap pentest scan data "
        "and provide a concise, actionable markdown report. Structure it as:\n\n"
        "1. **Executive Summary** — what was scanned and the overall risk level\n"
        "2. **Open Ports & Services** — which ports are open, what services are running, and their risk\n"
        "3. **Potential Vulnerabilities** — any obvious issues (outdated versions, unnecessary services, weak configs)\n"
        "4. **Recommendations** — prioritized actions to improve security\n\n"
        "Be specific and reference actual ports and services found. If no issues are found, say so.\n\n"
        f"Scan data:\n```\n{scan_data[:15000]}\n```"
    )

    try:
        response = client.chat.completions.create(
            model="deepseek-v4-flash",
            messages=[
                {"role": "system", "content": "You are a cybersecurity analyst. Be concise and technical."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2000
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"Error generating security analysis: {str(e)}"


# --- Advanced pentest: NSE categories, risk scoring, multi-phase scanning ---

NSE_CATEGORIES = {
    "web": {
        "label": "Web Services (headers, methods, dir enum)",
        "ports": [80, 443, 8080, 8443, 3000, 5000, 9090, 9443],
        "scripts": "http-headers,http-security-headers,http-methods,http-enum,http-webdav-scan,http-title",
    },
    "ssl": {
        "label": "SSL/TLS (ciphers, certs, heartbleed)",
        "ports": [443, 8443, 9443, 465, 993, 995, 636],
        "scripts": "ssl-enum-ciphers,ssl-cert,ssl-heartbleed,tls-nextprotoneg",
    },
    "ssh": {
        "label": "SSH (algorithms, host keys)",
        "ports": [22],
        "scripts": "ssh2-enum-algos,ssh-hostkey,ssh-auth-methods",
    },
    "smb": {
        "label": "SMB/Windows (shares, OS discovery)",
        "ports": [139, 445],
        "scripts": "smb-enum-shares,smb-os-discovery,smb-protocols",
    },
    "dns": {
        "label": "DNS (zone transfer, recursion)",
        "ports": [53],
        "scripts": "dns-zone-transfer,dns-recursion,dns-nsid",
    },
    "mysql": {
        "label": "MySQL/MariaDB (info, weak auth)",
        "ports": [3306],
        "scripts": "mysql-info,mysql-empty-password",
    },
    "ftp": {
        "label": "FTP (anonymous login, bounce)",
        "ports": [21],
        "scripts": "ftp-anon,ftp-bounce,ftp-syst,ftp-vsftpd-backdoor",
    },
    "rdp": {
        "label": "RDP (encryption, NTLM info)",
        "ports": [3389],
        "scripts": "rdp-enum-encryption,rdp-ntlm-info",
    },
}


def get_nmap_args(scan_type, family="ipv4"):
    """Get nmap arguments for a given scan type and address family."""
    base = {"quick": "-sS -F -T4 --max-retries 1 --reason",
            "thorough": "-sS -sV -O --top-ports 1000 -T4 --max-retries 2 --reason",
            "extensive": "-sS -sV -O --top-ports 10000 -T5 --max-retries 1 --min-rate 500 --reason",
            "full": "-sS -sV -O -p- -T4 --max-retries 2 --reason"}.get(
        scan_type, "-sS -sV --top-ports 1000 -T4 --reason")
    if family == "ipv6":
        return f"-6 {base}"
    return base


def parse_open_ports(nmap_output):
    """Parse nmap output to extract open ports with service info."""
    ports = []
    pattern = r'^(\d+)/(tcp|udp)\s+open\s+(\S+)\s*(.*)'
    for line in nmap_output.splitlines():
        m = re.match(pattern, line)
        if m:
            ports.append({
                "port": int(m.group(1)),
                "protocol": m.group(2),
                "service": m.group(3),
                "version": m.group(4).strip(),
            })
    return ports


def calculate_risk_score(ports, nse_output=""):
    """Calculate a security risk score from 0-100 based on open ports and findings."""
    import math
    score = 0

    PORT_RISK = {
        21: 15, 23: 20, 25: 8, 53: 5, 111: 4, 135: 10, 139: 8, 445: 10,
        1433: 10, 1521: 10, 2049: 8, 3306: 10, 3389: 15, 5432: 10,
        5900: 15, 5901: 15, 5985: 8, 5986: 8, 6379: 12, 9200: 10,
        11211: 15, 27017: 12, 27018: 10,
    }

    for p in ports:
        score += PORT_RISK.get(p["port"], 1)

    if ports:
        score += int(math.log2(len(ports) + 1) * 5)

    if nse_output:
        if re.search(r'(?i)weak|WEAK|RC4|DES\b|3DES|MD5|EXPORT|NULL\s+cipher', nse_output):
            score += 10
        if re.search(r'(?i)vulnerable|VULNERABLE|heartbleed|shellshock|eternalblue', nse_output):
            score += 15
        if re.search(r'(?i)anonymous.*logged|Anonymous.*yes', nse_output):
            score += 10
        if re.search(r'(?i)Zone transfer|AXFR', nse_output):
            score += 10
        if re.search(r'(?i)empty.*password|no password', nse_output):
            score += 15

    return min(score, 100)


def get_risk_level(score):
    """Return (label, emoji) for a risk score."""
    if score < 20:
        return "Very Low", "🟢"
    elif score < 40:
        return "Low", "🔵"
    elif score < 60:
        return "Moderate", "🟡"
    elif score < 80:
        return "High", "🟠"
    return "Critical", "🔴"


def run_advanced_pentest(target, scan_type, deep_analysis=False, nse_categories=None, family="ipv4"):
    """Run a multi-phase pentest scan.

    Phase 1 — Port discovery using the selected scan profile.
    Phase 2 — Targeted NSE deep-dive on discovered services (if enabled).
    Phase 3 — Risk scoring and findings summary.

    Returns (combined_report, phase1_output, ports_list, risk_score, nse_output).
    """
    target = target.strip()

    # Phase 1: Port scan
    scan_args = get_nmap_args(scan_type, family)
    phase1_output = run_nmap_scan(target, scan_args, timeout=900)

    if phase1_output.startswith("Error:"):
        return phase1_output, phase1_output, [], 0, ""

    ports = parse_open_ports(phase1_output)

    # Phase 2: NSE deep analysis
    nse_output = ""
    if deep_analysis and nse_categories and ports:
        scripts_to_run = []
        ports_to_scan = set()
        for cat in nse_categories:
            cat_info = NSE_CATEGORIES.get(cat)
            if not cat_info:
                continue
            cat_ports = [p["port"] for p in ports if p["port"] in cat_info["ports"]]
            if cat_ports:
                scripts_to_run.append(cat_info["scripts"])
                ports_to_scan.update(cat_ports)

        if scripts_to_run and ports_to_scan:
            script_arg = ",".join(scripts_to_run)
            port_list = ",".join(str(p) for p in sorted(ports_to_scan))
            try:
                nse_result = subprocess.run(
                    f"nmap -sV --script={script_arg} -p{port_list} {target} 2>&1",
                    shell=True, capture_output=True, text=True, timeout=600
                )
                nse_output = nse_result.stdout or ""
                if nse_result.stderr:
                    nse_output += f"\n--- STDERR ---\n{nse_result.stderr}"
            except subprocess.TimeoutExpired:
                nse_output = "NSE deep scan timed out after 600 seconds."
            except Exception as e:
                nse_output = f"NSE deep scan error: {e}"

    # Phase 3: Risk scoring
    risk_score = calculate_risk_score(ports, nse_output)
    level_label, level_icon = get_risk_level(risk_score)

    # Build combined report
    combined = f"TARGET: {target}\nRISK SCORE: {risk_score}/100 ({level_icon} {level_label})\n\n"
    combined += f"{'='*60}\nPHASE 1: PORT DISCOVERY ({scan_type.upper()})\n{'='*60}\n\n{phase1_output}\n\n"

    if nse_output:
        combined += f"{'='*60}\nPHASE 2: SERVICE DEEP ANALYSIS\n{'='*60}\n\n{nse_output}\n\n"

    if ports:
        combined += f"{'='*60}\nFINDINGS SUMMARY\n{'='*60}\n\n"
        combined += f"Total open ports: {len(ports)}\n\n"
        HIGH_RISK_PORTS = {21: "FTP (cleartext auth)", 23: "Telnet (cleartext)", 3389: "RDP",
                           5900: "VNC", 5901: "VNC", 6379: "Redis (no auth)",
                           11211: "Memcached (amplification risk)", 27017: "MongoDB (no auth)"}
        MEDIUM_RISK_PORTS = {22: "SSH", 25: "SMTP", 53: "DNS", 139: "NetBIOS", 445: "SMB",
                             1433: "MSSQL", 1521: "Oracle DB", 3306: "MySQL",
                             5432: "PostgreSQL", 8080: "HTTP-alt", 8443: "HTTPS-alt"}
        high_found = [p for p in ports if p["port"] in HIGH_RISK_PORTS]
        med_found = [p for p in ports if p["port"] in MEDIUM_RISK_PORTS]
        if high_found:
            combined += f"🔴 HIGH RISK ({len(high_found)}):\n"
            for p in high_found:
                combined += (f"  - Port {p['port']}/{p['protocol']}: {p['service']} "
                             f"{p['version']} [{HIGH_RISK_PORTS[p['port']]}]\n")
            combined += "\n"
        if med_found:
            combined += f"🟠 MEDIUM RISK ({len(med_found)}):\n"
            for p in med_found:
                combined += (f"  - Port {p['port']}/{p['protocol']}: {p['service']} "
                             f"{p['version']} [{MEDIUM_RISK_PORTS[p['port']]}]\n")
            combined += "\n"
        safe_ports = [p for p in ports if p["port"] not in HIGH_RISK_PORTS
                      and p["port"] not in MEDIUM_RISK_PORTS]
        if safe_ports:
            combined += f"✅ LOW RISK ({len(safe_ports)}): standard service ports\n"

    return combined, phase1_output, ports, risk_score, nse_output


def analyze_pentest_results(scan_data, api_key, risk_score=None):
    """Send pentest scan results to AI for comprehensive security analysis."""
    try:
        import httpx
        http_client = httpx.Client()
        client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com", http_client=http_client)
    except Exception:
        client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com")

    risk_context = ""
    if risk_score is not None:
        risk_context = f"\nThe automated risk score for this target is {risk_score}/100."

    prompt = (
        "You are a professional penetration tester and security analyst. "
        "Review the following pentest scan data and provide a comprehensive, "
        "actionable markdown report. Structure it as:\n\n"
        "1. **Executive Summary** — what was scanned, the overall risk posture, and key findings\n"
        "2. **Attack Surface Analysis** — breakdown of exposed services, their purpose, and risk\n"
        "3. **Vulnerability Assessment** — specific vulnerabilities or misconfigurations found "
        "(weak ciphers, outdated versions, unnecessary services, default credentials, etc.)\n"
        "4. **CVE Correlation** — map detected service versions to known CVEs where possible\n"
        "5. **Remediation Plan** — prioritized, actionable steps to improve security posture\n\n"
        "Be specific and reference actual ports, services, and versions found."
        f"{risk_context}"
        " If no significant issues are found, state that clearly.\n\n"
        f"Scan data:\n```\n{scan_data[:20000]}\n```"
    )

    try:
        response = client.chat.completions.create(
            model="deepseek-v4-flash",
            messages=[
                {"role": "system", "content": "You are a senior penetration tester providing concise, actionable security assessments. Use professional cybersecurity terminology."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=3000
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"Error generating security analysis: {str(e)}"


def main():
    print("Starting System Audit...")
    if not os.path.exists(REPORTS_DIR):
        os.makedirs(REPORTS_DIR, exist_ok=True)

    with open(CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)

    # Load user config from writable location if exists
    user_config_path = "/reports/user_config.yaml"
    user_config = {}
    if os.path.exists(user_config_path):
        try:
            with open(user_config_path, "r") as f:
                user_config = yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Error loading user config: {e}")

    # Merge configs: user config overrides default
    if 'checks' in user_config:
        config['checks'] = {**config['checks'], **user_config['checks']}

    data = gather_data(config)

    api_key = os.environ.get("ANTHROPIC_AUTH_TOKEN")
    if not api_key:
        print("Error: ANTHROPIC_AUTH_TOKEN not found in environment")
        sys.exit(1)

    # Work around for 'proxies' keyword argument issue with OpenAI client
    try:
        import httpx
        # Try creating httpx client without proxies argument
        http_client = httpx.Client()
        client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com", http_client=http_client)
    except Exception as e:
        print(f"Failed to create custom HTTP client: {e}, falling back to default")
        client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com")

    prompt = "You are a professional Linux/Homelab system auditor. Review the following system data and provide a concise, professional markdown report. At the start of the report, include a summary table that quickly identifies urgent issues requiring attention. The table should have columns: Check Category, Status (OK/Warning/Error), Urgency (High/Medium/Low), Brief Description. Then provide detailed sections summarizing the health, highlighting any warnings or errors, and recommending actions if necessary.\n\n"
    
    suppressions_file = os.path.join(REPORTS_DIR, "suppressions.txt")
    suppressions_text = ""
    if os.path.exists(suppressions_file):
        with open(suppressions_file, "r") as f:
            suppressions_text = f.read().strip()

    section_headers = "\n".join(f"- {s[0]}" for s in SECTIONS)
    system_content = (
        "You are a homelab system auditor. Always start your report with a summary table "
        "that quickly identifies urgent issues. The table should have columns: Check Category, "
        "Status (OK/Warning/Error), Urgency (High/Medium/Low), Brief Description.\n\n"
        "After the summary table, provide detailed sections with analysis, interpretation, "
        "and recommendations. Structure your detailed analysis using exactly these section "
        f"headers (in order):\n{section_headers}\n\n"
        "Raw command outputs will be shown as expandable sections alongside each analysis "
        "section — do NOT reproduce them verbatim. Focus on what the data means, what is "
        "concerning, and what actions to take. Output only professional markdown."
    )
    if suppressions_text:
        system_content += f"\n\nCRITICAL: The following known issues/warnings are explicitly suppressed. You MUST NOT include them in the summary table or any part of the report. Ignore them completely:\n{suppressions_text}"

    for key, val in data.items():
        prompt += f"### {key.upper()}\n```\n{val}\n```\n\n"

    print("Sending data to DeepSeek API...")
    try:
        response = client.chat.completions.create(
            model=config.get("ai_model", "deepseek-v4-flash"),
            messages=[
                {"role": "system", "content": system_content},
                {"role": "user", "content": prompt}
            ],
            max_tokens=4000
        )
        report = response.choices[0].message.content
    except Exception as e:
        print(f"Failed to generate report: {e}")
        report = f"# Error generating report\n\n```\n{str(e)}\n```"

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    report_file = os.path.join(REPORTS_DIR, f"audit_{timestamp}.md")

    # Insert raw data expandable sections per-section in the AI report
    report = insert_raw_data_into_report(report, data)

    with open(report_file, "w") as f:
        f.write(f"# System Audit Report - {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
        f.write(report)

    print(f"Report saved to {report_file}")

if __name__ == "__main__":
    main()