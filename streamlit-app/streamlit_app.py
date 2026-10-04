import os
import streamlit as st
import pandas as pd

st.set_page_config(
    page_title="Banking Compliance Intelligence",
    page_icon="🏦",
    layout="wide",
)

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


# --- Cached data loaders ---
@st.cache_data(ttl=300)
def load_aml_alerts():
    return conn.query("""
        SELECT ALERT_TYPE, SEVERITY, ACCOUNT_ID, CUSTOMER_ID, FULL_NAME,
               RISK_RATING, PEP_FLAG, PATTERN_COUNT, TOTAL_AMOUNT,
               FIRST_TXN_DATE, LAST_TXN_DATE, DESCRIPTION, REGULATORY_ACTION
        FROM BANKING_COMPLIANCE_AI.ANALYTICS.AML_ALERTS
        ORDER BY
            CASE SEVERITY WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 ELSE 3 END,
            TOTAL_AMOUNT DESC
    """)


@st.cache_data(ttl=300)
def load_fraud_signals():
    return conn.query("""
        SELECT FRAUD_SIGNAL_TYPE, SEVERITY, ACCOUNT_ID, CUSTOMER_ID, FULL_NAME,
               RISK_RATING, AMOUNT, TRANSACTION_TYPE, CHANNEL,
               TRANSACTION_DATE, ORIGINATOR_COUNTRY, BENEFICIARY_COUNTRY,
               DISTANCE_FROM_PREV_KM, MINUTES_SINCE_PREV,
               TXN_COUNT_30MIN, DISTINCT_DEVICES_30MIN
        FROM BANKING_COMPLIANCE_AI.ANALYTICS.FRAUD_SIGNALS
        ORDER BY
            CASE SEVERITY WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 ELSE 3 END,
            AMOUNT DESC
    """)


@st.cache_data(ttl=300)
def load_basel_metrics():
    return conn.query("""
        SELECT METRIC_TYPE, METRIC_NAME, METRIC_VALUE, METRIC_UNIT, STATUS,
               REGULATORY_MINIMUM, TOTAL_ADJUSTED_HQLA, TOTAL_STRESSED_OUTFLOW,
               TOTAL_STRESSED_INFLOW, CAPPED_INFLOW, NET_CASH_OUTFLOW,
               REGULATORY_REFERENCE
        FROM BANKING_COMPLIANCE_AI.ANALYTICS.BASEL_METRICS
    """)


@st.cache_data(ttl=300)
def load_compliance_reports():
    return conn.query("""
        SELECT REPORT_TYPE, ALERT_TYPE, SEVERITY, CUSTOMER_NAME, RISK_RATING,
               DESCRIPTION, TOTAL_AMOUNT, REGULATORY_ACTION,
               REGULATORY_REFERENCE, STATUS, CREATED_AT
        FROM BANKING_COMPLIANCE_AI.ANALYTICS.COMPLIANCE_REPORTS
        ORDER BY CREATED_AT DESC
        LIMIT 200
    """)


@st.cache_data(ttl=300)
def load_summary_stats():
    return conn.query("""
        SELECT
            (SELECT COUNT(*) FROM BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS) AS total_transactions,
            (SELECT COUNT(*) FROM BANKING_COMPLIANCE_AI.RAW_DATA.CUSTOMERS WHERE RISK_RATING IN ('HIGH','CRITICAL')) AS high_risk_customers,
            (SELECT COUNT(*) FROM BANKING_COMPLIANCE_AI.ANALYTICS.AML_ALERTS) AS aml_alerts,
            (SELECT COUNT(*) FROM BANKING_COMPLIANCE_AI.ANALYTICS.FRAUD_SIGNALS) AS fraud_signals,
            (SELECT COUNT(*) FROM BANKING_COMPLIANCE_AI.ANALYTICS.AML_ALERTS WHERE SEVERITY = 'CRITICAL') AS critical_aml,
            (SELECT COUNT(*) FROM BANKING_COMPLIANCE_AI.ANALYTICS.FRAUD_SIGNALS WHERE SEVERITY = 'CRITICAL') AS critical_fraud
    """)


# --- Sidebar ---
with st.sidebar:
    st.title("Compliance Intelligence")
    st.caption("Banking & NBFC (Non-Banking Financial Company) Compliance Dashboard")
    st.divider()

    page = st.radio(
        "Navigation",
        [
            "Executive Summary",
            "AML Alerts",
            "Fraud Signals",
            "Basel III (Liquidity & Capital Rules)",
            "Compliance Reports",
        ],
        index=0,
    )

    st.divider()
    if st.button("Refresh Data", type="primary", width="stretch"):
        load_aml_alerts.clear()
        load_fraud_signals.clear()
        load_basel_metrics.clear()
        load_compliance_reports.clear()
        load_summary_stats.clear()
        st.rerun()

    st.divider()
    st.caption("Dashboard data is at most 5 minutes old. Click Refresh for the latest.")


# --- Helpers ---
def severity_color(severity):
    return {"CRITICAL": "red", "HIGH": "orange", "MEDIUM": "blue"}.get(severity, "gray")


def format_inr(val):
    if val is None:
        return "N/A"
    if val >= 1e7:
        return f"₹{val / 1e7:,.2f} Cr"
    if val >= 1e5:
        return f"₹{val / 1e5:,.2f} L"
    return f"₹{val:,.0f}"


# --- Pages ---
if page == "Executive Summary":
    st.header("Executive Summary")
    st.caption("A snapshot of the bank's compliance health across anti-money laundering, fraud, and liquidity.")

    stats = load_summary_stats()
    row = stats.iloc[0]

    with st.container(horizontal=True):
        st.metric("Total Transactions", f"{int(row['TOTAL_TRANSACTIONS']):,}", border=True)
        st.metric("High-Risk Customers", int(row["HIGH_RISK_CUSTOMERS"]), border=True)
        st.metric("AML Alerts", int(row["AML_ALERTS"]), f"{int(row['CRITICAL_AML'])} critical", border=True)
        st.metric("Fraud Signals", int(row["FRAUD_SIGNALS"]), f"{int(row['CRITICAL_FRAUD'])} critical", border=True)

    col1, col2 = st.columns(2)

    with col1:
        with st.container(border=True):
            st.subheader("AML (Anti-Money Laundering) Alert Breakdown")
            st.caption("Alerts grouped by pattern type — structuring, high-risk wires, and layering.")
            aml = load_aml_alerts()
            if not aml.empty:
                chart_data = aml.groupby(["ALERT_TYPE", "SEVERITY"]).size().reset_index(name="COUNT")
                st.bar_chart(chart_data, x="ALERT_TYPE", y="COUNT", color="SEVERITY", horizontal=True)

    with col2:
        with st.container(border=True):
            st.subheader("LCR — Liquidity Coverage Ratio")
            st.caption("Can the bank survive 30 days of cash outflows using its liquid assets? Min required: 100%.")
            basel = load_basel_metrics()
            lcr_row = basel[basel["METRIC_TYPE"] == "LCR_SUMMARY"]
            if not lcr_row.empty:
                lcr_val = float(lcr_row.iloc[0]["METRIC_VALUE"])
                lcr_status = lcr_row.iloc[0]["STATUS"]
                st.metric(
                    "LCR (Liquidity Coverage Ratio)",
                    f"{lcr_val:.1f}%",
                    f"Min: 100% — {lcr_status}",
                    border=True,
                )
                hqla_rows = basel[basel["METRIC_TYPE"] != "LCR_SUMMARY"]
                for _, r in hqla_rows.iterrows():
                    st.metric(
                        r["METRIC_NAME"],
                        format_inr(float(r["METRIC_VALUE"])),
                        r["STATUS"],
                        border=True,
                    )

    with st.container(border=True):
        st.subheader("Recent Compliance Reports")
        reports = load_compliance_reports()
        if not reports.empty:
            st.dataframe(
                reports.head(20),
                hide_index=True,
                width="stretch",
                column_config={
                    "TOTAL_AMOUNT": st.column_config.NumberColumn("Amount (INR)", format="₹%.0f"),
                    "CREATED_AT": st.column_config.DatetimeColumn("Generated At", format="DD MMM YYYY HH:mm"),
                },
            )


elif page == "AML Alerts":
    st.header("AML — Anti-Money Laundering Alerts")
    st.caption("Transactions that match known money laundering patterns. Each alert may require a Suspicious Transaction Report (STR) to be filed with FIU-IND (Financial Intelligence Unit of India).")

    aml = load_aml_alerts()

    if aml.empty:
        st.info("No AML alerts detected.")
    else:
        sev_filter = st.multiselect("Filter by Severity", ["CRITICAL", "HIGH", "MEDIUM"], default=["CRITICAL", "HIGH"])
        type_filter = st.multiselect(
            "Filter by Pattern",
            aml["ALERT_TYPE"].unique().tolist(),
            default=aml["ALERT_TYPE"].unique().tolist(),
        )

        filtered = aml[(aml["SEVERITY"].isin(sev_filter)) & (aml["ALERT_TYPE"].isin(type_filter))]

        with st.container(horizontal=True):
            st.metric("Filtered Alerts", len(filtered), border=True)
            st.metric("Total Exposure", format_inr(float(filtered["TOTAL_AMOUNT"].sum())), border=True)
            st.metric("Unique Customers", filtered["CUSTOMER_ID"].nunique(), border=True)

        st.dataframe(
            filtered,
            hide_index=True,
            width="stretch",
            column_config={
                "TOTAL_AMOUNT": st.column_config.NumberColumn("Total Amount (INR)", format="₹%.0f"),
                "PEP_FLAG": st.column_config.CheckboxColumn("PEP (Politically Exposed Person)"),
                "FIRST_TXN_DATE": st.column_config.DatetimeColumn("First Txn", format="DD MMM YYYY"),
                "LAST_TXN_DATE": st.column_config.DatetimeColumn("Last Txn", format="DD MMM YYYY"),
            },
        )

        st.divider()
        with st.container(border=True):
            st.subheader("Regulatory Context — What Do These Patterns Mean?")
            st.markdown("""
            | Pattern | What It Means | Regulation | Action Required |
            |---------|--------------|-----------|-----------------|
            | **Structuring** | Splitting deposits to stay under the ₹10 lakh Cash Transaction Report (CTR) limit | PMLA (Prevention of Money Laundering Act) Rules 2005, Section 12 | File an STR (Suspicious Transaction Report) with FIU-IND |
            | **High-Risk Wire** | Cross-border transfers to countries on the FATF (Financial Action Task Force) grey/blacklist, or to shell companies | RBI (Reserve Bank of India) Master Direction on KYC (Know Your Customer) | Immediate STR + enhanced monitoring |
            | **Layering** | Money sent abroad and returned quickly through intermediaries to obscure its origin | FIU-IND (Financial Intelligence Unit) Red Flag Indicators | STR + Enhanced Due Diligence (EDD) |
            """)


elif page == "Fraud Signals":
    st.header("Real-Time Fraud Signals")
    st.caption("Suspicious transaction patterns detected automatically — impossible travel (transactions from distant locations within minutes), rapid-fire activity, and stolen credential indicators.")

    fraud = load_fraud_signals()

    if fraud.empty:
        st.info("No fraud signals detected.")
    else:
        sev_filter = st.multiselect(
            "Filter by Severity",
            ["CRITICAL", "HIGH", "MEDIUM"],
            default=["CRITICAL", "HIGH"],
            key="fraud_sev",
        )

        filtered = fraud[fraud["SEVERITY"].isin(sev_filter)]

        with st.container(horizontal=True):
            st.metric("Active Signals", len(filtered), border=True)
            st.metric("Impossible Travel (distant locations, short time)", int((filtered["FRAUD_SIGNAL_TYPE"] == "IMPOSSIBLE_TRAVEL").sum()), border=True)
            st.metric("Velocity Spikes (too many transactions too fast)", int((filtered["FRAUD_SIGNAL_TYPE"] == "VELOCITY_SPIKE").sum()), border=True)
            st.metric("Device Switching (multiple devices, one account)", int((filtered["FRAUD_SIGNAL_TYPE"] == "DEVICE_SWITCHING").sum()), border=True)

        st.dataframe(
            filtered,
            hide_index=True,
            width="stretch",
            column_config={
                "AMOUNT": st.column_config.NumberColumn("Amount (INR)", format="₹%.0f"),
                "DISTANCE_FROM_PREV_KM": st.column_config.NumberColumn("Distance (km)", format="%.0f km"),
                "MINUTES_SINCE_PREV": st.column_config.NumberColumn("Time Gap (min)", format="%d min"),
                "TRANSACTION_DATE": st.column_config.DatetimeColumn("Txn Time", format="DD MMM YYYY HH:mm"),
            },
        )


elif page == "Basel III (Liquidity & Capital Rules)":
    st.header("Basel III — Liquidity Metrics")
    st.caption("Basel III is the international standard for bank capital and liquidity. This page shows whether the bank holds enough liquid assets (cash, government bonds) to cover 30 days of stressed cash outflows.")

    basel = load_basel_metrics()

    if basel.empty:
        st.info("No Basel metrics available.")
    else:
        lcr_row = basel[basel["METRIC_TYPE"] == "LCR_SUMMARY"]
        if not lcr_row.empty:
            r = lcr_row.iloc[0]
            lcr_val = float(r["METRIC_VALUE"])

            with st.container(horizontal=True):
                st.metric("LCR (Liquidity Coverage Ratio)", f"{lcr_val:.1f}%", f"Min: 100% — {r['STATUS']}", border=True)
                st.metric("Total HQLA (High-Quality Liquid Assets)", format_inr(float(r["TOTAL_ADJUSTED_HQLA"])), border=True)
                st.metric("Net Cash Outflow (30-day stress)", format_inr(float(r["NET_CASH_OUTFLOW"])), border=True)

            col1, col2 = st.columns(2)

            with col1:
                with st.container(border=True):
                    st.subheader("HQLA — High-Quality Liquid Assets")
                    st.caption("Assets the bank can quickly convert to cash: government bonds (Level 1), corporate bonds (Level 2A), and equities (Level 2B). Higher levels are safer.")
                    hqla_rows = basel[basel["METRIC_TYPE"] != "LCR_SUMMARY"].copy()
                    hqla_rows["AMOUNT_CR"] = hqla_rows["METRIC_VALUE"].astype(float) / 1e7
                    st.bar_chart(hqla_rows, x="METRIC_NAME", y="AMOUNT_CR")

            with col2:
                with st.container(border=True):
                    st.subheader("LCR Computation Breakdown")
                    st.caption("LCR = HQLA / Net Cash Outflow. If > 100%, the bank can cover 30 days of withdrawals.")
                    st.markdown(f"""
                    | Component | What It Means | Value |
                    |-----------|--------------|-------|
                    | **HQLA (adjusted)** | Total liquid assets after haircuts (safety discounts) | {format_inr(float(r['TOTAL_ADJUSTED_HQLA']))} |
                    | **Stressed Outflows** | Expected cash going out under a crisis scenario | {format_inr(float(r['TOTAL_STRESSED_OUTFLOW']))} |
                    | **Stressed Inflows** | Expected cash coming in under a crisis scenario | {format_inr(float(r['TOTAL_STRESSED_INFLOW']))} |
                    | **Capped Inflows (75%)** | Inflows are capped at 75% of outflows (conservative rule) | {format_inr(float(r['CAPPED_INFLOW']))} |
                    | **Net Cash Outflow** | Outflows minus capped inflows — the gap HQLA must cover | {format_inr(float(r['NET_CASH_OUTFLOW']))} |
                    | **LCR** | HQLA divided by Net Cash Outflow | **{lcr_val:.1f}%** |
                    | **Regulatory Minimum** | Set by RBI under Basel III framework | 100% |
                    | **Reference** | | {r['REGULATORY_REFERENCE']} |
                    """)

        with st.container(border=True):
            st.subheader("All Basel Metrics")
            st.dataframe(
                basel,
                hide_index=True,
                width="stretch",
                column_config={
                    "METRIC_VALUE": st.column_config.NumberColumn("Value", format="%.2f"),
                    "REGULATORY_MINIMUM": st.column_config.NumberColumn("Min Required"),
                },
            )


elif page == "Compliance Reports":
    st.header("Audit-Ready Compliance Reports")
    st.caption("Consolidated reports from all detection pipelines (AML, fraud, Basel). These are the records a regulator or auditor would review. Open status means the alert has not yet been investigated.")

    reports = load_compliance_reports()

    if reports.empty:
        st.info("No compliance reports generated yet.")
    else:
        report_type = st.multiselect(
            "Report Type",
            reports["REPORT_TYPE"].unique().tolist(),
            default=reports["REPORT_TYPE"].unique().tolist(),
        )
        status_filter = st.multiselect(
            "Status",
            reports["STATUS"].unique().tolist(),
            default=reports["STATUS"].unique().tolist(),
        )

        filtered = reports[(reports["REPORT_TYPE"].isin(report_type)) & (reports["STATUS"].isin(status_filter))]

        with st.container(horizontal=True):
            st.metric("Total Reports", len(filtered), border=True)
            open_count = int((filtered["STATUS"] == "OPEN").sum())
            st.metric("Open / Pending", open_count, border=True)
            st.metric("Closed", int((filtered["STATUS"] == "CLOSED").sum()), border=True)

        st.dataframe(
            filtered,
            hide_index=True,
            width="stretch",
            column_config={
                "TOTAL_AMOUNT": st.column_config.NumberColumn("Amount", format="₹%.0f"),
                "CREATED_AT": st.column_config.DatetimeColumn("Generated At", format="DD MMM YYYY HH:mm"),
            },
        )
