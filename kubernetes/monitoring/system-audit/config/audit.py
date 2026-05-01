import os
import sys
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

    system_content = "You are a homelab system auditor. Always start your report with a summary table that quickly identifies urgent issues. The table should have columns: Check Category, Status (OK/Warning/Error), Urgency (High/Medium/Low), Brief Description. Then provide detailed sections with analysis, interpretation, and recommendations. The raw command outputs are shown separately above your analysis — do NOT reproduce them verbatim. Focus on what the data means, what is concerning, and what actions to take. Output only professional markdown."
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

    # Build expandable raw data sections
    raw_sections = []
    for key, val in data.items():
        label = CHECK_LABELS.get(key, key.replace('_', ' ').title())
        raw_sections.append(
            f"<details>\n<summary>{label}</summary>\n\n"
            f"```\n{val}\n```\n\n"
            f"</details>\n"
        )

    with open(report_file, "w") as f:
        f.write(f"# System Audit Report - {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
        f.write("## Raw Command Outputs\n\n")
        f.write("Expand each section below to see the exact commands run and their output. "
                "Use this to validate the AI analysis.\n\n")
        f.write("\n".join(raw_sections))
        f.write("\n\n---\n\n")
        f.write("## AI Analysis\n\n")
        f.write(report)

    print(f"Report saved to {report_file}")

if __name__ == "__main__":
    main()