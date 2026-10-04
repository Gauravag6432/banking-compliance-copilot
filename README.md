# Banking Compliance Intelligence on Snowflake

End-to-end banking compliance solution built entirely on Snowflake — fraud detection, AML (Anti-Money Laundering) monitoring, Basel III liquidity metrics, and regulatory reporting. No external infrastructure needed.

## What This Does

| Capability | How It Works |
|-----------|-------------|
| **Fraud Detection** | Impossible travel, velocity spikes, device switching — detected via Dynamic Tables refreshing every 5 minutes |
| **AML Monitoring** | Structuring (deposits just under ₹10 lakh), shell company wires, layering/round-tripping — flagged with PMLA/RBI/FATF references |
| **Basel III Metrics** | LCR (Liquidity Coverage Ratio) and HQLA (High-Quality Liquid Assets) computed from portfolio and cash flow data |
| **Regulatory Search** | Cortex Search over 12 regulatory documents (RBI, PMLA, Basel, FATF) — the agent cites current rules, not stale ones |
| **AI Agent** | Plain-English compliance questions answered with data + regulatory citations via Cortex Agent |
| **Dashboard** | 5-page Streamlit app for compliance officers with live alert counts, Basel metrics, and audit-ready reports |
| **MCP Server** | External apps (Claude Desktop, LangGraph) can query the agent via Model Context Protocol |

## Architecture

```
Raw Transactions → [Stream] → [Dynamic Tables: Fraud/AML/Basel] → [Task: Reports]
                                        ↓
                              [Semantic View] ← Cortex Agent → [Regulatory Search]
                                        ↓                              ↓
                              [Streamlit Dashboard]          [MCP Server → External Apps]
```

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` (or a role with `CREATE DATABASE`, `CREATE WAREHOUSE`, etc.)
- Warehouse: `COMPUTE_WH` (or change the name in the SQL scripts)
- Compute pool for Streamlit: `SYSTEM_COMPUTE_POOL_CPU` (or your account's default)
- CoCo CLI access (for agent deployment)

## Setup Instructions

### Step 1: Run SQL Scripts (in order)

Execute these in a Snowflake worksheet or via SnowSQL:

```bash
# 1. Create database, schemas, and all tables
sql/01_create_tables.sql

# 2. Populate synthetic data (~7,200 transactions with embedded suspicious patterns)
sql/02_seed_data.sql

# 3. Seed regulatory thresholds, HQLA portfolio, cash flows, and regulatory documents
sql/03_seed_reference_data.sql

# 4. Create the orchestration pipeline (stream, dynamic tables, search service, task)
sql/04_orchestration.sql

# 5. Create MCP server (agent is deployed separately via CLI)
sql/05_agent_and_mcp.sql
```

### Step 2: Create the Semantic View

```bash
# From CoCo CLI or Snowsight Workspace:
# The semantic view is generated from the 7 base tables with 8 verified queries.
# Use CoCo to generate it:
cortex agent-studio sv-generate --file-path /path/to/proto.json --out-path /tmp/response.json
cortex agent-studio sv-deploy --file-path BANKING_COMPLIANCE.sv.yaml --fqn BANKING_COMPLIANCE_AI.ANALYTICS.BANKING_COMPLIANCE
```

### Step 3: Deploy the Cortex Agent

```bash
cortex agent-studio agent-write \
  --yaml-content "$(cat agent/COMPLIANCE_AGENT.agent.yaml)" \
  --source-object BANKING_COMPLIANCE_AI.ANALYTICS.COMPLIANCE_AGENT

cortex agent-studio agent-deploy \
  --file-path COMPLIANCE_AGENT.agent.yaml \
  --fqn BANKING_COMPLIANCE_AI.ANALYTICS.COMPLIANCE_AGENT
```

### Step 4: Deploy the Streamlit Dashboard

Copy the `streamlit-app/` folder contents into a Snowflake Workspace:
- `snowflake.yml` — app configuration (update `query_warehouse` and `compute_pool` if different)
- `streamlit_app.py` — the 5-page dashboard
- `pyproject.toml` — dependencies
- `.streamlit/config.toml` — dark theme

Click **Run** in the Workspace to start the app.

### Step 5: Share the Dashboard

```sql
-- Grant access to other roles
GRANT USAGE ON DATABASE BANKING_COMPLIANCE_AI TO ROLE <viewer_role>;
GRANT USAGE ON SCHEMA BANKING_COMPLIANCE_AI.ANALYTICS TO ROLE <viewer_role>;
GRANT USAGE ON SCHEMA BANKING_COMPLIANCE_AI.RAW_DATA TO ROLE <viewer_role>;
GRANT USAGE ON SCHEMA BANKING_COMPLIANCE_AI.REFERENCE_DATA TO ROLE <viewer_role>;
GRANT SELECT ON ALL TABLES IN SCHEMA BANKING_COMPLIANCE_AI.RAW_DATA TO ROLE <viewer_role>;
GRANT SELECT ON ALL TABLES IN SCHEMA BANKING_COMPLIANCE_AI.REFERENCE_DATA TO ROLE <viewer_role>;
GRANT SELECT ON ALL TABLES IN SCHEMA BANKING_COMPLIANCE_AI.ANALYTICS TO ROLE <viewer_role>;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA BANKING_COMPLIANCE_AI.ANALYTICS TO ROLE <viewer_role>;
```

## Repository Structure

```
banking-compliance-ai/
├── README.md                          # This file
├── sql/
│   ├── 01_create_tables.sql           # Database, schemas, all table DDL
│   ├── 02_seed_data.sql               # Synthetic customers, accounts, transactions
│   ├── 03_seed_reference_data.sql     # Regulatory thresholds, HQLA, cash flows, reg docs
│   ├── 04_orchestration.sql           # Stream, Dynamic Tables, Search Service, Task
│   └── 05_agent_and_mcp.sql           # MCP Server + agent deployment notes
├── agent/
│   └── COMPLIANCE_AGENT.agent.yaml    # Cortex Agent specification (2 tools)
├── streamlit-app/
│   ├── snowflake.yml                  # Workspace app configuration
│   ├── streamlit_app.py               # 5-page compliance dashboard
│   ├── pyproject.toml                 # Python dependencies
│   └── .streamlit/
│       └── config.toml                # Dark theme configuration
├── docs/
│   └── PROJECT_SUMMARY.md             # Detailed project summary with demo script
└── .gitignore
```

## Demo Script

```sql
-- 1. Show dashboard (66 AML alerts)
-- 2. Insert a suspicious transaction
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS VALUES
('DEMO_TXN_001','ACC0000979',NULL,'CASH_DEPOSIT','BRANCH',950000.00,'INR',
 CURRENT_TIMESTAMP(),CURRENT_DATE(),NULL,NULL,'India','India','PERSONAL',
 'Cash deposit',FALSE,NULL,NULL,19.07,72.87,'COMPLETED',CURRENT_TIMESTAMP());

-- 3. Force Dynamic Table refresh
ALTER DYNAMIC TABLE BANKING_COMPLIANCE_AI.ANALYTICS.AML_ALERTS REFRESH;

-- 4. Click "Refresh Data" on dashboard — count increases to 67

-- 5. Cleanup
DELETE FROM BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS WHERE TRANSACTION_ID LIKE 'DEMO_TXN_%';
ALTER DYNAMIC TABLE BANKING_COMPLIANCE_AI.ANALYTICS.AML_ALERTS REFRESH;
```

## Built With

- **Snowflake** — database, Dynamic Tables, Streams, Tasks, Cortex AI
- **Cortex Agent** — AI agent with Cortex Analyst + Cortex Search tools
- **Cortex Analyst** — natural-language to SQL via Semantic View
- **Cortex Search** — semantic search over regulatory documents
- **Streamlit in Snowflake** — compliance officer dashboard
- **MCP Server** — Model Context Protocol for external app integration
- **CoCo CLI** — Snowflake's Cortex Code agent for building the solution

## License

This is a demo/prototype project using synthetic data. No production or customer data is included.
