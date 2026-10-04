-- ============================================================
-- Banking Compliance AI — Step 3: Seed Reference Data
-- Regulatory thresholds, HQLA portfolio, cash flows, and
-- regulatory documents for Cortex Search
-- Run after 02_seed_data.sql
-- ============================================================

-- -------------------------------------------------------
-- 3.1 Regulatory Thresholds
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.REFERENCE_DATA.REGULATORY_THRESHOLDS VALUES
('AML001','AML','CTR Threshold','Cash transaction reporting threshold for single transactions',1000000,'INR','INDIA','2016-01-01',NULL,'RBI Master Direction on KYC 2016, Rule 3',CURRENT_TIMESTAMP()),
('AML002','AML','STR Threshold - Structuring','Multiple transactions below CTR appearing structured',900000,'INR','INDIA','2016-01-01',NULL,'PMLA Rules 2005, Section 12',CURRENT_TIMESTAMP()),
('AML003','AML','Cross-Border Wire Threshold','Reporting threshold for cross-border wire transfers',500000,'INR','INDIA','2016-01-01',NULL,'RBI Circular on SWIFT Reporting 2019',CURRENT_TIMESTAMP()),
('AML004','AML','Structuring Window Days','Time window for detecting structuring patterns',7,'DAYS','INDIA','2016-01-01',NULL,'FIU-IND Guidelines',CURRENT_TIMESTAMP()),
('AML005','AML','PEP Enhanced Due Diligence','Enhanced monitoring required for PEP customers',NULL,NULL,'INDIA','2016-01-01',NULL,'RBI Master Direction on KYC, Section 38',CURRENT_TIMESTAMP()),
('AML006','AML','Rapid Movement Threshold','Funds received and moved out within short period',3,'DAYS','INDIA','2016-01-01',NULL,'FIU-IND Red Flag Indicators',CURRENT_TIMESTAMP()),
('BSL001','BASEL_III','LCR Minimum','Minimum Liquidity Coverage Ratio',100,'PERCENT','INDIA','2019-01-01',NULL,'RBI Basel III Liquidity Standards, April 2019',CURRENT_TIMESTAMP()),
('BSL002','BASEL_III','NSFR Minimum','Minimum Net Stable Funding Ratio',100,'PERCENT','INDIA','2020-10-01',NULL,'RBI NSFR Guidelines, October 2020',CURRENT_TIMESTAMP()),
('BSL003','BASEL_III','Level 2A Cap','Maximum Level 2A assets as share of HQLA',40,'PERCENT','INDIA','2019-01-01',NULL,'Basel III LCR Paragraph 50',CURRENT_TIMESTAMP()),
('BSL004','BASEL_III','Level 2B Cap','Maximum Level 2B assets as share of HQLA',15,'PERCENT','INDIA','2019-01-01',NULL,'Basel III LCR Paragraph 54',CURRENT_TIMESTAMP()),
('BSL005','BASEL_III','Inflow Cap','Maximum net cash inflows as share of outflows',75,'PERCENT','INDIA','2019-01-01',NULL,'Basel III LCR Paragraph 69',CURRENT_TIMESTAMP()),
('RBI001','RBI','SLR Requirement','Statutory Liquidity Ratio',18,'PERCENT','INDIA','2023-04-01',NULL,'RBI Monetary Policy, April 2023',CURRENT_TIMESTAMP()),
('RBI002','RBI','CRR Requirement','Cash Reserve Ratio',4.5,'PERCENT','INDIA','2023-04-01',NULL,'RBI Monetary Policy, April 2023',CURRENT_TIMESTAMP()),
('FATF01','FATF','High Risk Jurisdiction','FATF grey/blacklist country monitoring',NULL,NULL,'GLOBAL','2024-01-01',NULL,'FATF Public Statement, Feb 2024',CURRENT_TIMESTAMP());

-- -------------------------------------------------------
-- 3.2 HQLA Portfolio
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.HQLA_PORTFOLIO
SELECT
    'HQLA' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 4, '0'),
    v.asset_type, v.hqla_level, v.issuer, 'INR', v.face_value,
    ROUND(v.face_value * v.market_pct, 2), v.haircut,
    DATEADD(DAY, UNIFORM(90, 3650, RANDOM()), CURRENT_DATE()),
    UNIFORM(1, 10, RANDOM()) = 1, CURRENT_DATE(), CURRENT_TIMESTAMP()
FROM (VALUES
    ('CASH','LEVEL_1','Reserve Bank of India',500000000000,1.0,0),
    ('CENTRAL_BANK_RESERVES','LEVEL_1','Reserve Bank of India',300000000000,1.0,0),
    ('GOV_BONDS','LEVEL_1','Government of India',800000000000,0.98,0),
    ('GOV_BONDS','LEVEL_1','Government of India',600000000000,0.97,0),
    ('GOV_BONDS','LEVEL_1','Government of India',400000000000,0.96,0),
    ('GOV_BONDS','LEVEL_1','US Treasury',200000000000,0.99,0),
    ('CORP_BONDS','LEVEL_2A','Reliance Industries',150000000000,0.92,15),
    ('CORP_BONDS','LEVEL_2A','Tata Group',120000000000,0.91,15),
    ('CORP_BONDS','LEVEL_2A','HDFC Ltd',100000000000,0.93,15),
    ('COVERED_BONDS','LEVEL_2A','National Housing Bank',80000000000,0.90,15),
    ('EQUITY','LEVEL_2B','NSE Nifty 50 ETF',50000000000,0.85,50),
    ('CORP_BONDS','LEVEL_2B','Infosys Ltd',30000000000,0.80,50),
    ('CORP_BONDS','LEVEL_2B','Wipro Ltd',25000000000,0.78,50),
    ('EQUITY','LEVEL_2B','BSE Sensex ETF',40000000000,0.82,50),
    ('GOV_BONDS','LEVEL_1','Government of India SDL',350000000000,0.95,0)
) AS v(asset_type, hqla_level, issuer, face_value, market_pct, haircut);

-- -------------------------------------------------------
-- 3.3 Cash Flows
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.CASH_FLOWS
SELECT 'CF' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 5, '0'),
    v.flow_type, v.category, v.cp_type, v.amount, 'INR', v.runoff_rate, v.maturity_bucket,
    CURRENT_DATE(), CURRENT_TIMESTAMP()
FROM (VALUES
    ('OUTFLOW','RETAIL_DEPOSIT_STABLE','RETAIL',200000000000,5.0,'8_30_DAYS'),
    ('OUTFLOW','RETAIL_DEPOSIT_LESS_STABLE','RETAIL',150000000000,10.0,'8_30_DAYS'),
    ('OUTFLOW','UNSECURED_WHOLESALE_OPERATIONAL','CORPORATE',300000000000,25.0,'8_30_DAYS'),
    ('OUTFLOW','UNSECURED_WHOLESALE_NON_OPERATIONAL','CORPORATE',250000000000,40.0,'8_30_DAYS'),
    ('OUTFLOW','UNSECURED_WHOLESALE_FI','FINANCIAL_INSTITUTION',180000000000,100.0,'8_30_DAYS'),
    ('OUTFLOW','SECURED_FUNDING_L1','FINANCIAL_INSTITUTION',100000000000,0.0,'8_30_DAYS'),
    ('OUTFLOW','SECURED_FUNDING_L2A','FINANCIAL_INSTITUTION',80000000000,15.0,'8_30_DAYS'),
    ('OUTFLOW','CREDIT_FACILITY_DRAWDOWN','CORPORATE',120000000000,5.0,'8_30_DAYS'),
    ('OUTFLOW','LIQUIDITY_FACILITY_DRAWDOWN','FINANCIAL_INSTITUTION',60000000000,100.0,'8_30_DAYS'),
    ('OUTFLOW','DERIVATIVE_COLLATERAL','FINANCIAL_INSTITUTION',40000000000,100.0,'OVERNIGHT'),
    ('INFLOW','CONTRACTUAL_INFLOW_RETAIL','RETAIL',80000000000,50.0,'8_30_DAYS'),
    ('INFLOW','CONTRACTUAL_INFLOW_WHOLESALE','CORPORATE',100000000000,50.0,'8_30_DAYS'),
    ('INFLOW','CONTRACTUAL_INFLOW_FI','FINANCIAL_INSTITUTION',150000000000,100.0,'8_30_DAYS'),
    ('INFLOW','SECURED_LENDING_L1','FINANCIAL_INSTITUTION',90000000000,0.0,'8_30_DAYS'),
    ('INFLOW','SECURED_LENDING_L2A','FINANCIAL_INSTITUTION',50000000000,15.0,'8_30_DAYS'),
    ('OUTFLOW','TERM_DEPOSIT_RETAIL','RETAIL',400000000000,5.0,'91_180_DAYS'),
    ('OUTFLOW','TERM_DEPOSIT_WHOLESALE','CORPORATE',300000000000,10.0,'181_365_DAYS'),
    ('INFLOW','LOAN_REPAYMENT','RETAIL',200000000000,50.0,'31_90_DAYS'),
    ('INFLOW','LOAN_REPAYMENT_CORPORATE','CORPORATE',350000000000,50.0,'91_180_DAYS'),
    ('OUTFLOW','OPERATIONAL_COSTS','CORPORATE',50000000000,100.0,'OVERNIGHT')
) AS v(flow_type, category, cp_type, amount, runoff_rate, maturity_bucket);

-- -------------------------------------------------------
-- 3.4 Regulatory Documents (for Cortex Search)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.REFERENCE_DATA.REGULATORY_DOCUMENTS VALUES
('RBI-KYC-001','RBI','Master Direction on KYC — Customer Due Diligence','Section 3: Customer Identification','Every bank and financial institution must verify the identity of customers before opening an account or executing a transaction. Customer Due Diligence (CDD) requires obtaining the customer''s name, address, date of birth, and a valid identity document (Aadhaar, PAN, passport, or voter ID). For individuals, the bank must verify the document against the original. For legal entities (companies, trusts, partnerships), the bank must identify the beneficial owners — anyone who ultimately owns or controls more than 25% of the entity. Enhanced Due Diligence (EDD) must be applied to high-risk customers, including Politically Exposed Persons (PEPs), customers from high-risk jurisdictions, and those with complex or unusual transaction patterns. Banks must update KYC records periodically: every 2 years for high-risk customers, every 8 years for medium-risk, and every 10 years for low-risk customers.','Reserve Bank of India','2016-02-25','INDIA',NULL,CURRENT_TIMESTAMP()),
('RBI-KYC-002','RBI','Master Direction on KYC — Wire Transfer Regulations','Section 12: Cross-Border Wire Transfers','For cross-border wire transfers of INR 50,000 or more (or equivalent in foreign currency), banks must include full originator information: name, account number, and address or national identity number. The beneficiary bank must verify the completeness of this information. If originator information is missing or incomplete, the beneficiary bank must consider filing a Suspicious Transaction Report (STR). Banks must maintain records of all cross-border wire transfers for at least 5 years. Correspondent banking relationships must be subject to enhanced due diligence, and banks must not enter into or continue correspondent banking relationships with shell banks.','Reserve Bank of India','2016-02-25','INDIA',NULL,CURRENT_TIMESTAMP()),
('PMLA-001','PMLA','Prevention of Money Laundering Act 2002 — Cash Transaction Reporting','Section 12: Obligations of Banking Companies','Every banking company, financial institution, and intermediary must furnish Cash Transaction Reports (CTRs) to the Financial Intelligence Unit-India (FIU-IND) for all cash transactions of the value of INR 10,00,000 (ten lakh rupees) or more, or its equivalent in foreign currency, whether the transaction is a single transaction or a series of connected transactions within a month. CTRs must be filed within 15 days of the month in which the transaction occurs. Additionally, Suspicious Transaction Reports (STRs) must be filed for any transaction that gives reason to suspect that it may involve proceeds of an offence related to scheduled offences under PMLA, regardless of the amount. STRs must be filed within 7 working days of forming the suspicion.','Government of India','2005-07-01','INDIA',NULL,CURRENT_TIMESTAMP()),
('PMLA-002','PMLA','Prevention of Money Laundering Act — Structuring and Smurfing','Rule 3: Maintenance of Records','Structuring, also known as smurfing, refers to the practice of deliberately breaking down financial transactions into smaller amounts to avoid the reporting threshold of INR 10,00,000. This is a serious offence under PMLA. Banks must monitor for patterns where a customer or a group of connected customers make multiple cash deposits or withdrawals that individually fall below the reporting threshold but collectively exceed it within a short period (typically 7 days). Red flags include: multiple cash deposits of INR 8-9.9 lakh at different branches on the same day; regular cash deposits just below INR 10 lakh across multiple accounts held by the same customer; use of multiple accounts in the names of family members or associates to avoid CTR filing. Banks must file an STR when structuring is suspected, regardless of the individual transaction amounts.','Government of India','2005-07-01','INDIA',NULL,CURRENT_TIMESTAMP()),
('PMLA-003','PMLA','PMLA — Layering and Round-Tripping','FIU-IND Red Flag Indicators','Layering is the second stage of money laundering where funds are moved through multiple transactions, accounts, or jurisdictions to distance them from their criminal origin. Round-tripping involves sending money abroad and bringing it back through seemingly legitimate channels to disguise its source. Red flags for layering include: rapid movement of funds into and out of an account within 3-5 days; funds received from a high-risk jurisdiction and immediately transferred to a different jurisdiction; multiple transactions between related entities with no clear business purpose; use of shell companies or entities in jurisdictions with weak AML controls. Banks must apply Enhanced Due Diligence (EDD) when these patterns are identified and file STRs with FIU-IND.','FIU-IND','2020-01-01','INDIA',NULL,CURRENT_TIMESTAMP()),
('FATF-001','FATF','FATF Recommendations — Risk-Based Approach','Recommendation 1: Assessing Risks','Countries and financial institutions should identify, assess, and understand the money laundering and terrorist financing risks they face, and take appropriate measures to mitigate those risks. The risk-based approach allows countries and financial institutions to allocate resources more efficiently by focusing enhanced measures on higher-risk areas. Higher-risk factors include: customers from countries identified by FATF as having strategic AML/CFT deficiencies (grey list) or subject to a call for counter-measures (black list); complex or unusually large transactions with no apparent economic or lawful purpose; transactions involving countries or geographic areas that do not sufficiently apply FATF recommendations; business relationships or transactions with PEPs (Politically Exposed Persons).','FATF','2012-02-01','GLOBAL',NULL,CURRENT_TIMESTAMP()),
('FATF-002','FATF','FATF Grey List and Black List — High-Risk Jurisdictions','Public Statement on High-Risk Jurisdictions','The FATF identifies jurisdictions with strategic deficiencies in their AML/CFT regimes. Grey List (Jurisdictions Under Increased Monitoring): These countries have committed to resolve strategic deficiencies within agreed timeframes. Financial institutions should apply enhanced due diligence to business relationships and transactions involving these jurisdictions. Black List (High-Risk Jurisdictions Subject to a Call for Action): These countries have significant strategic deficiencies. Financial institutions should apply counter-measures proportionate to the risks. Countries include: Iran, North Korea, and Myanmar (as of latest update). Banks must screen all cross-border transactions against the current FATF lists and escalate transactions involving listed jurisdictions for enhanced review.','FATF','2024-02-01','GLOBAL',NULL,CURRENT_TIMESTAMP()),
('BASEL-LCR-001','BASEL_III','Basel III Liquidity Coverage Ratio (LCR) Framework','Paragraphs 17-23: LCR Overview','The Liquidity Coverage Ratio (LCR) is designed to ensure that banks hold a sufficient stock of high-quality liquid assets (HQLA) to survive a 30-day period of significant liquidity stress. The LCR is calculated as: LCR = Stock of HQLA / Total Net Cash Outflows over the next 30 calendar days. The minimum LCR requirement is 100%, meaning the stock of HQLA must be at least equal to total net cash outflows. HQLA are classified into three levels: Level 1 assets (cash, central bank reserves, qualifying sovereign debt) receive no haircut and have no cap; Level 2A assets (certain government securities, covered bonds, corporate debt rated AA- or higher) receive a 15% haircut and are capped at 40% of total HQLA; Level 2B assets (lower-rated corporate bonds, equities in major indices) receive a 50% haircut and are capped at 15% of total HQLA. Assets must be unencumbered — not pledged as collateral or subject to any legal restriction on sale.','Basel Committee on Banking Supervision (BCBS)','2013-01-01','GLOBAL',NULL,CURRENT_TIMESTAMP()),
('BASEL-LCR-002','BASEL_III','Basel III LCR — Cash Flow Stress Assumptions','Paragraphs 69-75: Run-Off Rates and Inflow Caps','Under the LCR framework, banks must estimate stressed cash outflows and inflows over a 30-day horizon using prescribed run-off rates and inflow assumptions. Key outflow categories and their run-off rates: Stable retail deposits: 5%; Less stable retail deposits: 10%; Operational deposits from financial institutions: 25%; Non-operational wholesale funding from corporates: 40%; Unsecured wholesale funding from financial institutions: 100%. Key inflow assumptions: Contractual inflows from performing loans: 50% of amounts due; Inflows from fully performing financial institution counterparties: 100%. Total inflows are capped at 75% of total outflows, ensuring the bank cannot rely entirely on expected inflows. Net Cash Outflows = Total Outflows - min(Total Inflows, 75% of Total Outflows). The RBI adopted the Basel III LCR framework effective January 2015, with the minimum LCR requirement phased in to reach 100% by January 2019.','Basel Committee on Banking Supervision (BCBS)','2013-01-01','GLOBAL',NULL,CURRENT_TIMESTAMP()),
('BASEL-NSFR-001','BASEL_III','Basel III Net Stable Funding Ratio (NSFR)','Overview and Key Requirements','The Net Stable Funding Ratio (NSFR) requires banks to maintain a stable funding profile relative to the composition of their assets and off-balance sheet activities. NSFR = Available Stable Funding (ASF) / Required Stable Funding (RSF). The minimum NSFR is 100%. Available Stable Funding (ASF) is calculated by assigning ASF factors to each funding source: Tier 1 and Tier 2 capital: 100%; Stable retail deposits and term deposits with maturity > 1 year: 95%; Less stable retail deposits: 90%; Wholesale funding with maturity > 1 year: 100%; Operational deposits: 50%. Required Stable Funding (RSF) is calculated by assigning RSF factors to assets: Cash and central bank reserves: 0%; Unencumbered Level 1 HQLA: 5%; Loans to financial institutions with maturity < 6 months: 10%; Performing loans with maturity > 1 year: 85%; Non-performing loans: 100%. The RBI implemented NSFR requirements effective October 1, 2020.','Basel Committee on Banking Supervision (BCBS)','2014-10-01','GLOBAL',NULL,CURRENT_TIMESTAMP()),
('RBI-FRAUD-001','RBI','RBI Master Direction on Frauds — Classification and Reporting','Chapter 3: Early Detection','Banks must implement robust fraud detection systems covering all transaction channels including branch, ATM, online banking, mobile banking, and UPI. Key indicators of fraud include: Transactions from geographically impossible locations within a short time span (impossible travel); Unusual velocity of transactions — more than 3 transactions within 30 minutes from the same account; Use of multiple devices or IP addresses for transactions from the same account in rapid succession; Transactions significantly deviating from the customer''s normal pattern in terms of amount, frequency, or type. Banks must report all frauds of INR 1 lakh and above to the RBI within 3 weeks of detection. For frauds of INR 1 crore and above, an initial report must be submitted within 7 days. All fraud cases must be reported in the RBI''s XBRL-based fraud reporting system.','Reserve Bank of India','2016-07-01','INDIA',NULL,CURRENT_TIMESTAMP()),
('RBI-PEP-001','RBI','RBI Guidelines on Politically Exposed Persons (PEPs)','Section 38: Enhanced Due Diligence for PEPs','Politically Exposed Persons (PEPs) are individuals who hold or have held prominent public positions, such as heads of state, senior politicians, senior government officials, judicial officials, military officers, and senior executives of state-owned enterprises. Family members and close associates of PEPs are also covered. Banks must: obtain senior management approval before establishing a business relationship with a PEP; take reasonable measures to establish the source of wealth and source of funds; conduct enhanced ongoing monitoring of the business relationship. PEP status does not automatically mean the person is involved in criminal activity, but the position they hold makes them more vulnerable to corruption. Banks should apply a risk-based approach and may apply simplified measures if the PEP holds a lower-risk domestic political position. Foreign PEPs must always be treated as higher risk.','Reserve Bank of India','2016-02-25','INDIA',NULL,CURRENT_TIMESTAMP());
