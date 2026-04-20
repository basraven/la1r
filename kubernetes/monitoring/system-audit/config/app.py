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

with open("/config/checks.yaml", "r") as f:
    config = yaml.safe_load(f)

if st.session_state.page == "Dashboard":
    st.sidebar.markdown("### Configuration")
    st.sidebar.checkbox("ZFS Audit", value=config['checks']['zfs_health'], disabled=True)
    st.sidebar.checkbox("Disk SMART", value=config['checks']['smart_attributes'], disabled=True)
    st.sidebar.checkbox("Journal Errors", value=config['checks']['journal_errors'], disabled=True)
    st.sidebar.checkbox("Kubernetes Node Health", value=config['checks']['kubernetes_node_health'], disabled=True)
    st.sidebar.checkbox("System Updates", value=config['checks']['system_updates'], disabled=True)
    st.sidebar.checkbox("Service Status", value=config['checks']['service_status'], disabled=True)
    st.sidebar.checkbox("System Health", value=config['checks']['system_health'], disabled=True)

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