-- ============================================================
-- Banking Compliance AI — Step 5: Cortex Agent + MCP Server
-- Creates the AI agent with data + regulatory search tools
-- and exposes it via MCP for external clients
-- Run after 04_orchestration.sql
-- ============================================================

-- -------------------------------------------------------
-- 5.1 Cortex Agent (deploy via agent-studio CLI, not raw SQL)
-- The agent YAML spec is in ../agent/COMPLIANCE_AGENT.agent.yaml
-- Deploy with:
--   cortex agent-studio agent-deploy \
--     --file-path COMPLIANCE_AGENT.agent.yaml \
--     --fqn BANKING_COMPLIANCE_AI.ANALYTICS.COMPLIANCE_AGENT
-- -------------------------------------------------------

-- -------------------------------------------------------
-- 5.2 MCP Server
-- -------------------------------------------------------
CREATE OR REPLACE MCP SERVER BANKING_COMPLIANCE_AI.ANALYTICS.COMPLIANCE_MCP_SERVER
  FROM SPECIFICATION $$
  tools:
    - title: "Banking Compliance Intelligence Agent"
      name: "compliance_agent"
      type: "CORTEX_AGENT_RUN"
      identifier: "BANKING_COMPLIANCE_AI.ANALYTICS.COMPLIANCE_AGENT"
      description: "A governed compliance agent for banks and NBFCs. Detects fraud, identifies AML red flags, computes Basel III liquidity metrics, looks up live regulatory text from RBI/PMLA/FATF/Basel, and generates audit-ready reports."
  $$;

-- -------------------------------------------------------
-- 5.3 Grant access (adjust roles as needed)
-- -------------------------------------------------------
-- GRANT USAGE ON MCP SERVER BANKING_COMPLIANCE_AI.ANALYTICS.COMPLIANCE_MCP_SERVER TO ROLE <role>;
-- GRANT USAGE ON DATABASE BANKING_COMPLIANCE_AI TO ROLE <role>;
-- GRANT USAGE ON SCHEMA BANKING_COMPLIANCE_AI.ANALYTICS TO ROLE <role>;
