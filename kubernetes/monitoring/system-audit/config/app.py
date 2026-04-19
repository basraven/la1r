import streamlit as st
import yaml
import os
import subprocess
from datetime import datetime

st.set_page_config(page_title="System Audit AI", layout="wide")

REPORTS_DIR = "/reports"

# --- UI Sidebar ---
st.sidebar.title("System Audit AI")
with open("/config/checks.yaml", "r") as f:
    config = yaml.safe_load(f)

st.sidebar.markdown("### Configuration")
st.sidebar.checkbox("ZFS Audit", value=config['checks']['zfs_health'], disabled=True)
st.sidebar.checkbox("Disk SMART", value=config['checks']['smart_attributes'], disabled=True)
st.sidebar.checkbox("Journal Errors", value=config['checks']['journal_errors'], disabled=True)

st.title("🛡️ System Audit AI Dashboard")

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

st.markdown("---")
st.header("Previous Reports")

if not os.path.exists(REPORTS_DIR):
    os.makedirs(REPORTS_DIR, exist_ok=True)

reports = sorted([f for f in os.listdir(REPORTS_DIR) if f.endswith(".md") or f.endswith(".html")], reverse=True)

if not reports:
    st.info("No reports found. Wait for the cron job or trigger one manually.")
else:
    selected_report = st.selectbox("Select a report to view", reports)
    if selected_report:
        report_path = os.path.join(REPORTS_DIR, selected_report)
        with open(report_path, "r") as f:
            content = f.read()
        st.markdown(content, unsafe_allow_html=True)