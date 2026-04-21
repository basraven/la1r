import streamlit as st
import yaml
import os
import subprocess
from datetime import datetime

st.set_page_config(page_title="System Audit AI", layout="wide")

REPORTS_DIR = "/reports"

# --- UI Sidebar ---
st.sidebar.title("System Audit AI")

if "page" not in st.session_state:
    st.session_state.page = "Dashboard"

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

    # Editable checkboxes for each check
    st.session_state.checks_config['zfs_health'] = st.sidebar.checkbox(
        "ZFS Audit",
        value=st.session_state.checks_config['zfs_health']
    )
    st.session_state.checks_config['smart_attributes'] = st.sidebar.checkbox(
        "Disk SMART",
        value=st.session_state.checks_config['smart_attributes']
    )
    st.session_state.checks_config['journal_errors'] = st.sidebar.checkbox(
        "Journal Errors",
        value=st.session_state.checks_config['journal_errors']
    )
    st.session_state.checks_config['kubernetes_node_health'] = st.sidebar.checkbox(
        "Kubernetes Node Health",
        value=st.session_state.checks_config['kubernetes_node_health']
    )
    st.session_state.checks_config['system_updates'] = st.sidebar.checkbox(
        "System Updates",
        value=st.session_state.checks_config['system_updates']
    )
    st.session_state.checks_config['service_status'] = st.sidebar.checkbox(
        "Service Status",
        value=st.session_state.checks_config['service_status']
    )
    st.session_state.checks_config['system_health'] = st.sidebar.checkbox(
        "System Health",
        value=st.session_state.checks_config['system_health']
    )
    st.session_state.checks_config['host_log_analysis'] = st.sidebar.checkbox(
        "Host Log Analysis",
        value=st.session_state.checks_config.get('host_log_analysis', True)
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

elif st.session_state.page == "Manage Suppressions":
    if st.button("← Back to Dashboard"):
        st.session_state.page = "Dashboard"
        st.rerun()

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