import streamlit as st
import yaml
import os
import subprocess
import time
import re
from datetime import datetime

st.set_page_config(page_title="System Audit AI", layout="wide")

# Page navigation
PAGES = ["Dashboard", "Pentest", "Manage Suppressions"]
if "page" not in st.session_state:
    st.session_state.page = "Dashboard"

# Custom styling for expandable report sections
st.markdown("""
<style>
details {
    margin: 0.5em 0;
    padding: 0.5em 1em;
    background: #1e1e1e;
    border-radius: 8px;
    border: 1px solid #333;
}
details[open] {
    background: #252525;
}
details summary {
    cursor: pointer;
    font-weight: 600;
    color: #e0e0e0;
    padding: 0.25em 0;
}
details summary:hover {
    color: #ffffff;
}
details[open] summary {
    margin-bottom: 0.5em;
    border-bottom: 1px solid #333;
    padding-bottom: 0.5em;
}
details pre, details code {
    background: #1a1a1a;
    border-radius: 4px;
}
</style>
""", unsafe_allow_html=True)

REPORTS_DIR = "/reports"

# --- UI Sidebar ---
st.sidebar.title("System Audit AI")

# Sidebar navigation buttons
for p in PAGES:
    if st.sidebar.button(p, use_container_width=True, type="primary" if st.session_state.page == p else "secondary"):
        st.session_state.page = p
        st.rerun()

st.sidebar.markdown("---")

# Load default config from configMap
with open("/config/checks.yaml", "r") as f:
    default_config = yaml.safe_load(f)

# Load user config from writable location if exists
user_config_path = "/reports/user_config.yaml"
user_config = {}
if os.path.exists(user_config_path):
    try:
        with open(user_config_path, "r") as f:
            user_config = yaml.safe_load(f)
    except Exception as e:
        st.sidebar.warning(f"Error loading user config: {e}")

# Merge configs: user config overrides default
config = default_config.copy()
if 'checks' in user_config:
    config['checks'] = {**default_config['checks'], **user_config['checks']}

if st.session_state.page == "Dashboard":
    # Initialize session state for checkboxes if not present
    if 'checks_config' not in st.session_state:
        st.session_state.checks_config = config['checks'].copy()

    st.sidebar.markdown("### Configuration")

    # Select all / deselect all
    all_checks = list(st.session_state.checks_config.keys())
    all_enabled = all(st.session_state.checks_config.values())
    if st.sidebar.button("Deselect All" if all_enabled else "Select All"):
        new_value = not all_enabled
        for key in all_checks:
            st.session_state.checks_config[key] = new_value
        st.rerun()

    # Checks organised by category
    check_definitions = {
        "System": [
            ("system_health", "System Health"),
            ("system_updates", "System Updates"),
            ("service_status", "Service Status"),
            ("failed_units", "Failed Systemd Units"),
            ("inode_usage", "Inode Usage"),
        ],
        "Storage": [
            ("zfs_health", "ZFS Audit"),
            ("smart_attributes", "Disk SMART"),
        ],
        "Logs & Events": [
            ("journal_errors", "Journal Errors"),
            ("oom_events", "OOM Events"),
            ("dmesg_anomalies", "Dmesg Anomalies"),
            ("host_log_analysis", "Host Log Analysis"),
        ],
        "Kubernetes": [
            ("kubernetes_node_health", "Node Health"),
            ("node_resource_pressure", "Node Resource Pressure"),
            ("certificate_expiry", "Certificate Expiry"),
        ],
    }

    for category, checks in check_definitions.items():
        with st.sidebar.expander(category, expanded=True):
            for key, label in checks:
                st.session_state.checks_config[key] = st.checkbox(
                    label,
                    value=st.session_state.checks_config.get(key, True)
                )

    # Save configuration button
    st.sidebar.markdown("---")
    if st.sidebar.button("Save Configuration", type="primary"):
        # Write user config to writable location
        user_config = {'checks': st.session_state.checks_config}
        with open("/reports/user_config.yaml", "w") as f:
            yaml.dump(user_config, f, default_flow_style=False)
        st.sidebar.success("Configuration saved!")

    st.title("🛡️ System Audit AI Dashboard")

    col1, col2 = st.columns([1, 1])
    with col1:
        if st.button("Trigger Manual Audit"):
            with st.spinner("Running system audit..."):
                try:
                    # Trigger the audit.py script
                    result = subprocess.run(["/venv/bin/python", "/config/audit.py"], capture_output=True, text=True)
                    if result.returncode == 0:
                        st.success("Audit completed successfully!")
                    else:
                        st.error(f"Audit failed: {result.stderr}")
                except Exception as e:
                    st.error(f"Error running audit: {e}")
    with col2:
        if st.button("Manage Suppressions"):
            st.session_state.page = "Manage Suppressions"
            st.rerun()

    st.markdown("---")
    st.header("Previous Reports")

    if not os.path.exists(REPORTS_DIR):
        os.makedirs(REPORTS_DIR, exist_ok=True)

    reports = sorted([f for f in os.listdir(REPORTS_DIR) if (f.endswith(".md") or f.endswith(".html")) and f != "suppressions.txt"], reverse=True)

    if not reports:
        st.info("No reports found. Wait for the cron job or trigger one manually.")
    else:
        col_sel, col_del = st.columns([4, 1])
        with col_sel:
            selected_report = st.selectbox("Select a report to view", reports)
        
        if selected_report:
            with col_del:
                st.write("") # Alignment
                st.write("") # Alignment
                if st.button("🗑️ Delete"):
                    report_path = os.path.join(REPORTS_DIR, selected_report)
                    os.remove(report_path)
                    st.success(f"Deleted {selected_report}")
                    st.rerun()

            report_path = os.path.join(REPORTS_DIR, selected_report)
            if os.path.exists(report_path):
                with open(report_path, "r") as f:
                    content = f.read()
                st.markdown(content, unsafe_allow_html=True)

elif st.session_state.page == "Pentest":
    st.title("🔍 External Pentest")
    st.write("Run security scans against external (IPv4/IPv6) and internal targets. Results are displayed in real-time.")

    api_key = os.environ.get("ANTHROPIC_AUTH_TOKEN", "")

    # Session state for discovered IPs
    if "discovered_ipv4" not in st.session_state:
        st.session_state.discovered_ipv4 = ""
    if "discovered_ipv6" not in st.session_state:
        st.session_state.discovered_ipv6 = ""

    # Target configuration
    with st.expander("Target Configuration", expanded=True):
        col1, col2 = st.columns([3, 1])
        with col1:
            ext_ipv4 = st.text_input("External IPv4 Address", placeholder="e.g. 203.0.113.1", value=st.session_state.discovered_ipv4,
                                     help="Your public IPv4 address for external perimeter testing")
            ext_ipv6 = st.text_input("External IPv6 Address", placeholder="e.g. 2001:db8::1", value=st.session_state.discovered_ipv6,
                                     help="Your public IPv6 address for external perimeter testing")
        with col2:
            st.write("")  # spacing
            st.write("")
            if st.button("🌐 Discover My IPs", use_container_width=True):
                from audit import discover_external_ips
                with st.spinner("Discovering external IPs..."):
                    discovered = discover_external_ips()
                if discovered["ipv4"]:
                    st.session_state.discovered_ipv4 = discovered["ipv4"]
                if discovered["ipv6"]:
                    st.session_state.discovered_ipv6 = discovered["ipv6"]
                if discovered.get("error"):
                    st.warning(discovered["error"])
                elif discovered["ipv4"] and discovered["ipv6"]:
                    st.success(f"IPv4: {discovered['ipv4']}, IPv6: {discovered['ipv6']}")
                st.rerun()

        int_target = st.text_input("Internal Target", value="192.168.5.3",
                                    help="Internal host to scan (e.g. jay-c node at 192.168.5.3)")

    # Scan type
    scan_type = st.selectbox("Scan Depth", ["quick", "thorough", "extensive", "full"],
        format_func=lambda x: {"quick": "Quick (top 100 ports, no version detection)",
                               "thorough": "Thorough (top 1000 ports + version + OS detection)",
                               "extensive": "Extensive (top 10000 + aggressive timing)",
                               "full": "Full (all 65535 ports + version + OS detection, takes very long)"}.get(x, x),
        help="Quick runs in seconds. Full scans all 65535 ports but can take many minutes (especially through firewalls).")

    # Construct nmap arguments based on scan type and address family
    def get_nmap_args(stype, family):
        base = {"quick": "-sS -F -T4 --max-retries 1 --reason",
                "thorough": "-sS -sV -O --top-ports 1000 -T4 --max-retries 2 --reason",
                "extensive": "-sS -sV -O --top-ports 10000 -T5 --max-retries 1 --min-rate 500 --reason",
                "full": "-sS -sV -O -p- -T4 --max-retries 2 --reason"}.get(stype, "-sS -sV --top-ports 1000 -T4 --reason")
        if family == "ipv6":
            return f"-6 {base}"
        return base

    st.markdown("---")
    col1, col2, col3 = st.columns(3)
    with col1:
        scan_ipv4 = st.button("🚀 Scan External IPv4", disabled=not ext_ipv4, type="primary",
                              use_container_width=True)
    with col2:
        scan_ipv6 = st.button("🚀 Scan External IPv6", disabled=not ext_ipv6, type="primary",
                              use_container_width=True)
    with col3:
        scan_int = st.button("🚀 Scan Internal Target", type="primary",
                             use_container_width=True)

    st.markdown("---")

    if "pentest_results" not in st.session_state:
        st.session_state.pentest_results = {}

    # --- Background scan management ---
    def _start_scan(key, target, scan_args, timeout):
        """Launch nmap in background, store process ref in session state."""
        outfile = f"/tmp/scan_{key}.out"
        errfile = f"/tmp/scan_{key}.err"
        with open(outfile, "w") as out_f, open(errfile, "w") as err_f:
            proc = subprocess.Popen(
                f"nmap {scan_args} {target}", shell=True,
                stdout=out_f, stderr=err_f
            )
        st.session_state[f"_proc_{key}"] = proc
        st.session_state[f"_out_{key}"] = outfile
        st.session_state[f"_err_{key}"] = errfile
        st.session_state.pentest_results[key] = {
            "target": target, "type": "scanning...", "running": True,
            "result": None, "ts": None
        }

    def _poll_scan(key):
        """Check if background scan finished. Returns (done, output)."""
        proc = st.session_state.get(f"_proc_{key}")
        if proc is None:
            return True, "Error: scan was not started"
        if proc.poll() is None:
            return False, None
        # Process finished — read output
        outfile = st.session_state.get(f"_out_{key}", "")
        errfile = st.session_state.get(f"_err_{key}", "")
        output = ""
        if outfile and os.path.exists(outfile):
            with open(outfile) as f:
                output = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', f.read())
        error = ""
        if errfile and os.path.exists(errfile):
            with open(errfile) as f:
                error = f.read()
        for f in [outfile, errfile]:
            try:
                if f: os.remove(f)
            except OSError:
                pass
        for k in [f"_proc_{key}", f"_out_{key}", f"_err_{key}"]:
            st.session_state.pop(k, None)
        full = output
        if error:
            full += f"\n--- STDERR ---\n{error}"
        return True, full.strip() or "Error: scan produced no output"

    # Run scans — launch in background, don't block the WebSocket
    if scan_ipv4 and ext_ipv4:
        args = get_nmap_args(scan_type, "ipv4")
        _start_scan("ipv4", ext_ipv4, args, 0)
        st.rerun()

    if scan_ipv6 and ext_ipv6:
        args = get_nmap_args(scan_type, "ipv6")
        _start_scan("ipv6", ext_ipv6, args, 0)
        st.rerun()

    if scan_int and int_target:
        args = get_nmap_args(scan_type, "ipv4")
        _start_scan("internal", int_target, args, 0)
        st.rerun()

    # Poll running scans
    running_keys = [k for k, v in st.session_state.pentest_results.items()
                    if v.get("running")]
    for key in running_keys:
        done, output = _poll_scan(key)
        if done:
            st.session_state.pentest_results[key].update(
                result=output, running=False,
                ts=datetime.now().strftime("%H:%M:%S")
            )
            st.rerun()
        else:
            # Brief check-in to keep WebSocket alive, then rerun
            st.toast(f"⏳ Scanning {st.session_state.pentest_results[key]['target']}...", icon="🔍")

    # Display results
    result_labels = {"ipv4": "External IPv4", "ipv6": "External IPv6", "internal": "Internal Target"}

    if not st.session_state.pentest_results:
        st.info("No scans run yet. Configure targets above and click a scan button.")

    for key, data in st.session_state.pentest_results.items():
        target = data["target"]
        result = data["result"]
        running = data.get("running", False)
        ts = data.get("ts", "")
        label = result_labels.get(key, key)

        if running:
            with st.expander(f"⏳ {label} — {target}  (scanning...)", expanded=True):
                st.info("Scan in progress. Results will appear automatically when complete.")
        elif result is None:
            continue
        else:
            with st.expander(f"📋 {label} — {target}  ({ts})", expanded=True):
                if result.startswith("Error:"):
                    st.error(result)
                else:
                    st.text(result)

            if api_key and not result.startswith("Error:"):
                col_a1, col_a2 = st.columns([1, 3])
                with col_a1:
                    analyze_btn = st.button(f"🤖 Analyze Results", key=f"analyze_{key}")
                if analyze_btn:
                    from audit import analyze_pentest_results
                    with st.spinner("Running AI security analysis..."):
                        analysis = analyze_pentest_results(result, api_key)
                    st.markdown("### AI Security Analysis")
                    st.markdown(analysis)

    # Clear results button
    if st.session_state.pentest_results:
        if st.button("🗑️ Clear All Results"):
            st.session_state.pentest_results = {}
            st.rerun()

    # Auto-poll for running scans — keeps WebSocket alive while scanning
    if any(v.get("running") for v in st.session_state.pentest_results.values()):
        time.sleep(3)
        st.rerun()
elif st.session_state.page == "Manage Suppressions":
    st.title("🛑 Manage Suppressions")
    st.write("Configure the warnings and issues that the AI should ignore during the system audit.")
    
    suppressions_file = os.path.join(REPORTS_DIR, "suppressions.txt")

    if not os.path.exists(REPORTS_DIR):
        os.makedirs(REPORTS_DIR, exist_ok=True)

    if "suppressions" not in st.session_state:
        if os.path.exists(suppressions_file):
            with open(suppressions_file, "r") as f:
                st.session_state.suppressions = [line.strip() for line in f.readlines() if line.strip()]
        else:
            st.session_state.suppressions = []

    def save_suppressions():
        with open(suppressions_file, "w") as f:
            f.write("\n".join(st.session_state.suppressions))

    st.subheader("Add New Suppression")
    new_suppression = st.text_input("Add a warning or issue string to ignore:")
    if st.button("Add Warning"):
        supp_text = new_suppression.strip()
        if supp_text and supp_text not in st.session_state.suppressions:
            st.session_state.suppressions.append(supp_text)
            save_suppressions()
            st.rerun()

    st.markdown("---")
    st.subheader("Current Suppressions")
    if st.session_state.suppressions:
        for i, supp in enumerate(st.session_state.suppressions):
            col1, col2 = st.columns([5, 1])
            col1.write(f"- {supp}")
            if col2.button("✖ Delete", key=f"del_{i}"):
                st.session_state.suppressions.pop(i)
                save_suppressions()
                st.rerun()
    else:
        st.info("No suppressions currently configured.")