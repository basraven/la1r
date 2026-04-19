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

def gather_data(config):
    data = {}
    if config['checks'].get('zfs_health'):
        print("Gathering ZFS data...")
        data['zpool_status'] = run_host_command("zpool status")
        data['zpool_list'] = run_host_command("zpool list")

    if config['checks'].get('smart_attributes'):
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

    if config['checks'].get('journal_errors'):
        print("Gathering journal errors...")
        data['journal'] = run_host_command("journalctl --since '7 days ago' -p err..emerg --no-pager | tail -n 100")

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

    client = OpenAI(api_key=api_key, base_url="https://api.deepseek.com")

    prompt = "You are a professional Linux/Homelab system auditor. Review the following system data and provide a concise, professional markdown report summarizing the health, highlighting any warnings or errors, and recommending actions if necessary.\n\n"
    for key, val in data.items():
        prompt += f"### {key.upper()}\n```\n{val}\n```\n\n"

    print("Sending data to DeepSeek API...")
    try:
        response = client.chat.completions.create(
            model=config.get("ai_model", "deepseek-chat"),
            messages=[
                {"role": "system", "content": "You are a homelab system auditor. Output only professional markdown."},
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