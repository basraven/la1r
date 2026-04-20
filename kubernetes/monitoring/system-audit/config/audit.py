import os
import sys
import yaml
import subprocess
from datetime import datetime
from openai import OpenAI

REPORTS_DIR = "/reports"
CONFIG_PATH = "/config/checks.yaml"

def run_host_command(cmd):
    """Runs a command on the K8s node via nsenter"""
    try:
        full_cmd = f"nsenter -t 1 -m -u -i -n {cmd}"
        result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, timeout=60)
        return result.stdout.strip() if result.returncode == 0 else f"Error: {result.stderr}"
    except Exception as e:
        return f"Exception: {str(e)}"

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

            data['kubernetes_health'] = f"=== NODES ===\n{''.join(node_info)}\n=== POD STATUS ===\n{', '.join(pod_summary)}\n\n=== RECENT EVENTS (last hour) ===\n{chr(10).join(recent_events) if recent_events else 'No recent warning/error events'}\n\n=== NAMESPACES ===\n{chr(10).join(namespace_status)}"

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

    return data

def main():
    print("Starting System Audit...")
    if not os.path.exists(REPORTS_DIR):
        os.makedirs(REPORTS_DIR, exist_ok=True)

    with open(CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)

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

    system_content = "You are a homelab system auditor. Always start your report with a summary table that quickly identifies urgent issues. The table should have columns: Check Category, Status (OK/Warning/Error), Urgency (High/Medium/Low), Brief Description. Then provide detailed sections. Output only professional markdown."
    if suppressions_text:
        system_content += f"\n\nCRITICAL: The following known issues/warnings are explicitly suppressed. You MUST NOT include them in the summary table or any part of the report. Ignore them completely:\n{suppressions_text}"

    for key, val in data.items():
        prompt += f"### {key.upper()}\n```\n{val}\n```\n\n"

    print("Sending data to DeepSeek API...")
    try:
        response = client.chat.completions.create(
            model=config.get("ai_model", "deepseek-chat"),
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

    with open(report_file, "w") as f:
        f.write(f"# System Audit Report - {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
        f.write(report)

    print(f"Report saved to {report_file}")

if __name__ == "__main__":
    main()