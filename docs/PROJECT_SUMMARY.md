# Banking Compliance Intelligence — Project Summary

## Problem Statement

Banks and NBFCs (Non-Banking Financial Companies) deal with three challenges simultaneously:

1. **Real-time fraud detection** — catching bad transactions as they happen
2. **AML (Anti-Money Laundering) monitoring** — spotting and reporting suspicious activity like structuring, layering, and shell company flows
3. **Basel III regulatory reporting** — computing liquidity metrics like LCR (Liquidity Coverage Ratio) and NSFR (Net Stable Funding Ratio)

Today, compliance teams stitch together data and write reports by hand — slow, error-prone, and hard to scale. This solution automates the full pipeline: from data ingestion to detection to audit-ready reporting, built entirely on Snowflake using CoCo CLI (Cortex Code).

---

## Architecture

```
                         ┌──────────────────────────────────┐
                         │     RAW_DATA (Synthetic Base)     │
                         │                                    │
                         │  CUSTOMERS ─── ACCOUNTS ─── TRANSACTIONS
                         │       │                      │
                         │  COUNTERPARTIES              │
                         │  HQLA_PORTFOLIO              │
                         │  CASH_FLOWS                  │
                         └──────────┬───────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
           ┌──────────────┐ ┌─────────────┐ ┌─────────────┐
           │ FRAUD_SIGNALS│ │ AML_ALERTS  │ │BASEL_METRICS│
           │ Dynamic Table│ │Dynamic Table│ │Dynamic Table│
           │  (5 min lag) │ │ (5 min lag) │ │(30 min lag) │
           └──────┬───────┘ └──────┬──────┘ └──────┬──────┘
                  │                │                │
                  └────────┬───────┘                │
                           ▼                        │
                  ┌─────────────────┐               │
                  │  COMPLIANCE_    │               │
                  │  REPORTS (Task) │◄──────────────┘
                  │  Every 6 hours  │
                  └────────┬────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌──────────────┐ ┌────────┐ ┌──────────┐
     │  Streamlit   │ │ Cortex │ │   MCP    │
     │  Dashboard   │ │ Agent  │ │  Server  │
     │ (5 pages)    │ │(2 tools)│ │(external)│
     └──────────────┘ └────────┘ └──────────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
              Semantic View  Cortex Search
              (data queries) (regulatory docs)
```

---

## Object Inventory

### Database: BANKING_COMPLIANCE_AI

#### Schema: RAW_DATA — Base Tables

| Table | Rows | Purpose |
|-------|------|---------|
| CUSTOMERS | 500 | Customer master with KYC (Know Your Customer), PEP (Politically Exposed Person) flags, risk ratings, sanctions status |
| ACCOUNTS | 1,090 | Savings, current, loan, NRE/NRO accounts linked to customers |
| COUNTERPARTIES | 30 | External entities: banks, corporates, shell companies, sanctioned entities with jurisdiction risk flags |
| TRANSACTIONS | 7,221 | All financial transactions across UPI, NEFT, RTGS, SWIFT, cash channels with geo-location and device data |
| HQLA_PORTFOLIO | 15 | High-Quality Liquid Assets (cash, government bonds, corporate bonds) for Basel III LCR computation |
| CASH_FLOWS | 20 | Projected cash inflows/outflows with run-off rates for LCR/NSFR stress testing |

#### Schema: REFERENCE_DATA — Regulatory Reference

| Table | Rows | Purpose |
|-------|------|---------|
| REGULATORY_THRESHOLDS | 14 | AML reporting limits, Basel III parameters, RBI/FATF rules with legal references |
| REGULATORY_DOCUMENTS | 12 | Full regulatory text: RBI circulars, PMLA sections, Basel guidelines, FATF recommendations |

#### Schema: ANALYTICS — Detection & Reporting

| Object | Type | Rows | Purpose |
|--------|------|------|---------|
| BANKING_COMPLIANCE | Semantic View | — | Business-meaning layer over all 7 base tables with 8 verified queries |
| FRAUD_SIGNALS | Dynamic Table | 18 | Real-time fraud detection: impossible travel, velocity spikes, device switching (5-min refresh) |
| AML_ALERTS | Dynamic Table | 66 | AML pattern detection: structuring, shell company wires, layering (5-min refresh) |
| BASEL_METRICS | Dynamic Table | 4 | LCR computation: HQLA by level, stressed cash flows, compliance status (30-min refresh) |
| COMPLIANCE_REPORTS | Table | 198 | Audit-ready consolidated reports from all detection pipelines |
| GENERATE_COMPLIANCE_REPORT | Task | — | Scheduled task (every 6 hours IST) consolidating alerts into reports |
| COMPLIANCE_AGENT | Cortex Agent | — | AI agent with 2 tools: data analytics (Cortex Analyst) + regulatory search (Cortex Search) |
| COMPLIANCE_MCP_SERVER | MCP Server | — | Exposes the compliance agent to external MCP clients (Claude Desktop, LangGraph, etc.) |

#### Schema: REFERENCE_DATA — Search Service

| Object | Type | Purpose |
|--------|------|---------|
| REGULATORY_SEARCH | Cortex Search Service | Semantic search over 12 regulatory documents (1-hour refresh) |

#### Schema: RAW_DATA — Stream

| Object | Type | Purpose |
|--------|------|---------|
| TRANSACTIONS_STREAM | Stream | CDC (Change Data Capture) on the transactions table |

---

## Embedded Suspicious Patterns (for detection)

The synthetic transaction data includes intentionally planted patterns for the detection pipeline to find:

| Pattern | Count | What It Simulates |
|---------|-------|-------------------|
| Structuring (STXN) | 101 txns | Multiple cash deposits of INR 8.9–9.99 lakh, just under the 10 lakh CTR threshold |
| Fraud / Impossible Travel (FTXN) | 120 txns | Rapid-fire transactions from geographically impossible locations (Mumbai → Moscow in 10 min) |
| Shell Company Wires (WTXN) | 74 txns | Large cross-border wires to counterparties in FATF grey/blacklist jurisdictions |
| Layering / Round-Tripping (LTXN) | 44 txns | Funds sent abroad via SWIFT and returned through intermediaries within 3 days |

---

## How Each Step Was Built

### Step 1: Data Foundation
- Generated 500 synthetic customers with realistic Indian names, KYC statuses, PEP flags
- Created referentially consistent accounts, counterparties, and transactions (zero orphan records)
- Planted 339 suspicious transactions across 4 AML/fraud pattern types
- Added Basel III data: HQLA portfolio (Level 1/2A/2B) and cash flow projections with run-off rates

### Step 2: Semantic Views
- Built a semantic view over all 7 base tables with auto-detected foreign key relationships
- Added 8 verified queries covering: high-risk customers, structuring detection, cross-border flows, HQLA computation, LCR cash flows, KYC reviews, PEP transactions, AML thresholds
- Enables Cortex Analyst to answer compliance questions in plain English

### Step 3: Cortex Agent
- Created a compliance agent with two tools:
  - **compliance_analytics** (Cortex Analyst) — queries structured data via the semantic view
  - **regulatory_search** (Cortex Search) — looks up live regulatory text from RBI, PMLA, Basel, FATF
- Agent instructions include INR formatting, regulatory citation requirements, and response templates
- Orchestration rules tell the agent when to use each tool (and when to use both)

### Step 4: Orchestration
- **Stream** on TRANSACTIONS captures new rows via CDC
- **3 Dynamic Tables** auto-refresh every 5–30 minutes:
  - FRAUD_SIGNALS: Haversine distance for impossible travel, 30-min velocity windows, device fingerprinting
  - AML_ALERTS: Structuring (sub-threshold deposits), shell company wires, layering (rapid in-out flows)
  - BASEL_METRICS: Full LCR computation with HQLA haircuts, stressed outflows/inflows, 75% inflow cap
- **Scheduled Task** runs every 6 hours (IST) to consolidate all alerts into audit-ready reports

### Step 5: Streamlit Dashboard
- 5-page compliance officer interface:
  - Executive Summary: KPI cards, AML breakdown chart, LCR status
  - AML Alerts: Filterable table with severity, exposure amounts, regulatory context
  - Fraud Signals: Impossible travel, velocity spikes, device switching with geo/time data
  - Basel III Metrics: LCR computation breakdown, HQLA composition chart
  - Compliance Reports: Audit-ready consolidated reports with status tracking
- All acronyms expanded inline for beginner-friendliness
- Refresh button clears UI cache; data at most 5 minutes old

### Step 6: MCP + Regulatory Sources
- Created 12 regulatory documents covering RBI KYC, PMLA structuring/layering, FATF grey/blacklists, Basel III LCR/NSFR
- Built a Cortex Search Service for semantic search over regulatory text
- Added the search tool to the agent so it cites current regulations, not stale rules
- Created an MCP Server exposing the agent to external clients

---

## Demo Script

### Quick Demo (2 minutes)

1. Open the Streamlit dashboard — show Executive Summary (66 AML alerts, 18 fraud signals, LCR at 1,158%)
2. Navigate to AML Alerts — filter by CRITICAL, show structuring patterns with ₹ amounts
3. Navigate to Basel III — show LCR computation breakdown
4. Ask the Cortex Agent: "What are the PMLA rules on structuring and do we have any customers violating them?"
5. Show that the agent uses BOTH tools — regulatory text from search + live data from analyst

### Live Refresh Demo (5 minutes)

```sql
-- Step 1: Note current AML alert count (66)

-- Step 2: Insert suspicious transactions
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS VALUES
('DEMO_TXN_001', 'ACC0000979', NULL, 'CASH_DEPOSIT', 'BRANCH', 950000.00, 'INR',
 CURRENT_TIMESTAMP(), CURRENT_DATE(), NULL, NULL, 'India', 'India', 'PERSONAL',
 'Cash deposit', FALSE, NULL, NULL, 19.07, 72.87, 'COMPLETED', CURRENT_TIMESTAMP());

-- Step 3: Force the Dynamic Table to recompute
ALTER DYNAMIC TABLE BANKING_COMPLIANCE_AI.ANALYTICS.AML_ALERTS REFRESH;

-- Step 4: Click "Refresh Data" on the dashboard — count changes to 67

-- Step 5: Cleanup
DELETE FROM BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS WHERE TRANSACTION_ID LIKE 'DEMO_TXN_%';
ALTER DYNAMIC TABLE BANKING_COMPLIANCE_AI.ANALYTICS.AML_ALERTS REFRESH;
-- Click "Refresh Data" — count returns to 66
```

---

## MCP Server Connection

External MCP clients (Claude Desktop, LangGraph, custom apps) can connect to the compliance agent at:

```
https://<account-url>/api/v2/databases/BANKING_COMPLIANCE_AI/schemas/ANALYTICS/mcp-servers/COMPLIANCE_MCP_SERVER
```

Authentication: Snowflake OAuth (default) or Programmatic Access Token.

---

## Key Talking Points

1. **No production data needed** — entirely synthetic but referentially consistent, with realistic Indian banking patterns
2. **End-to-end in Snowflake** — no Airflow, no Kafka, no external infrastructure. Streams + Dynamic Tables + Tasks handle orchestration natively
3. **Explainable AI** — the agent cites specific transaction IDs, regulatory sections (PMLA Rule 3, Basel III Paragraph 69), and recommends concrete actions (file STR with FIU-IND within 7 working days)
4. **Live regulatory knowledge** — the agent looks up current RBI/PMLA/FATF text via Cortex Search instead of relying on stale hard-coded rules
5. **Built by describing it** — the entire solution was prototyped from natural-language instructions to CoCo CLI, demonstrating that manual compliance work can be automated safely
