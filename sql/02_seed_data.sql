-- ============================================================
-- Banking Compliance AI — Step 2: Synthetic Data Population
-- Run after 01_create_tables.sql
-- Generates ~7,200 transactions with embedded fraud/AML patterns
-- ============================================================

-- -------------------------------------------------------
-- 2.1 Customers (500 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.CUSTOMERS
WITH name_parts AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn,
        CASE MOD(SEQ4(), 20)
            WHEN 0 THEN 'Rajesh' WHEN 1 THEN 'Priya' WHEN 2 THEN 'Amit' WHEN 3 THEN 'Sunita'
            WHEN 4 THEN 'Vikram' WHEN 5 THEN 'Anjali' WHEN 6 THEN 'Suresh' WHEN 7 THEN 'Deepa'
            WHEN 8 THEN 'Arun' WHEN 9 THEN 'Kavita' WHEN 10 THEN 'Nikhil' WHEN 11 THEN 'Meena'
            WHEN 12 THEN 'Sanjay' WHEN 13 THEN 'Pooja' WHEN 14 THEN 'Ramesh' WHEN 15 THEN 'Lakshmi'
            WHEN 16 THEN 'Manish' WHEN 17 THEN 'Neha' WHEN 18 THEN 'Vivek' ELSE 'Ananya'
        END AS first_name,
        CASE MOD(SEQ4(), 15)
            WHEN 0 THEN 'Sharma' WHEN 1 THEN 'Patel' WHEN 2 THEN 'Gupta' WHEN 3 THEN 'Singh'
            WHEN 4 THEN 'Kumar' WHEN 5 THEN 'Mehta' WHEN 6 THEN 'Reddy' WHEN 7 THEN 'Nair'
            WHEN 8 THEN 'Joshi' WHEN 9 THEN 'Iyer' WHEN 10 THEN 'Shah' WHEN 11 THEN 'Das'
            WHEN 12 THEN 'Chopra' WHEN 13 THEN 'Verma' ELSE 'Agarwal'
        END AS last_name
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT
    'CUST' || LPAD(rn::VARCHAR, 6, '0'),
    first_name || ' ' || last_name,
    DATEADD(DAY, -UNIFORM(7000, 25000, RANDOM()), CURRENT_DATE()),
    CASE WHEN rn <= 450 THEN 'Indian' WHEN rn <= 470 THEN 'British' WHEN rn <= 480 THEN 'American' WHEN rn <= 490 THEN 'Emirati' ELSE 'Nigerian' END,
    CASE WHEN rn <= 460 THEN 'India' WHEN rn <= 475 THEN 'UAE' WHEN rn <= 485 THEN 'UK' WHEN rn <= 495 THEN 'USA' ELSE 'Nigeria' END,
    CASE MOD(rn, 8) WHEN 0 THEN 'Mumbai' WHEN 1 THEN 'Delhi' WHEN 2 THEN 'Bangalore' WHEN 3 THEN 'Chennai' WHEN 4 THEN 'Hyderabad' WHEN 5 THEN 'Pune' WHEN 6 THEN 'Kolkata' ELSE 'Ahmedabad' END,
    CASE WHEN rn <= 400 THEN 'INDIVIDUAL' WHEN rn <= 470 THEN 'CORPORATE' ELSE 'TRUST' END,
    CASE WHEN rn <= 420 THEN 'VERIFIED' WHEN rn <= 460 THEN 'PENDING' WHEN rn <= 490 THEN 'EXPIRED' ELSE 'REJECTED' END,
    CASE WHEN rn <= 420 THEN DATEADD(DAY, -UNIFORM(30, 365, RANDOM()), CURRENT_TIMESTAMP()) ELSE NULL END,
    CASE WHEN rn <= 300 THEN 'LOW' WHEN rn <= 420 THEN 'MEDIUM' WHEN rn <= 480 THEN 'HIGH' ELSE 'CRITICAL' END,
    rn > 485,
    rn > 495,
    CASE MOD(rn, 5) WHEN 0 THEN '5221' WHEN 1 THEN '5411' WHEN 2 THEN '6022' WHEN 3 THEN '7372' ELSE '8111' END,
    CASE WHEN rn <= 400 THEN UNIFORM(200000, 5000000, RANDOM()) ELSE UNIFORM(5000000, 500000000, RANDOM()) END,
    CASE MOD(rn, 4) WHEN 0 THEN 'Salary' WHEN 1 THEN 'Business Income' WHEN 2 THEN 'Investments' ELSE 'Inheritance' END,
    DATEADD(DAY, -UNIFORM(100, 3650, RANDOM()), CURRENT_DATE()),
    DATEADD(DAY, -UNIFORM(1, 180, RANDOM()), CURRENT_DATE()),
    CURRENT_TIMESTAMP()
FROM name_parts;

-- -------------------------------------------------------
-- 2.2 Counterparties (30 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.COUNTERPARTIES
SELECT
    'CP' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 4, '0'),
    name, entity_type, country, risk_jurisdiction, swift_code, is_correspondent, sanctions_listed, CURRENT_TIMESTAMP()
FROM (
    VALUES
    ('State Bank of India','BANK','India',FALSE,'SBININBB',TRUE,FALSE),
    ('HDFC Bank','BANK','India',FALSE,'HDFCINBB',TRUE,FALSE),
    ('ICICI Bank','BANK','India',FALSE,'ABORINBB',TRUE,FALSE),
    ('Barclays UK','BANK','UK',FALSE,'BARCGB22',TRUE,FALSE),
    ('Deutsche Bank','BANK','Germany',FALSE,'DEUTDEFF',TRUE,FALSE),
    ('Emirates NBD','BANK','UAE',FALSE,'EABORAEA',TRUE,FALSE),
    ('First National Nigeria','BANK','Nigeria',TRUE,'FIABORNG',FALSE,FALSE),
    ('Bank of Iran','BANK','Iran',TRUE,'BMIJIRTH',FALSE,TRUE),
    ('Pyongyang Commerce','BANK','North Korea',TRUE,NULL,FALSE,TRUE),
    ('Myanmar Trade Bank','BANK','Myanmar',TRUE,NULL,FALSE,FALSE),
    ('Reliance Industries','CORPORATE','India',FALSE,NULL,FALSE,FALSE),
    ('Tata Consultancy','CORPORATE','India',FALSE,NULL,FALSE,FALSE),
    ('Infosys Ltd','CORPORATE','India',FALSE,NULL,FALSE,FALSE),
    ('Shell Trading','CORPORATE','Netherlands',FALSE,NULL,FALSE,FALSE),
    ('Global Resources LLC','SHELL_COMPANY','Cayman Islands',TRUE,NULL,FALSE,FALSE),
    ('Pacific Holdings BVI','SHELL_COMPANY','British Virgin Islands',TRUE,NULL,FALSE,FALSE),
    ('Meridian Ventures','SHELL_COMPANY','Panama',TRUE,NULL,FALSE,FALSE),
    ('Government of India','GOVERNMENT','India',FALSE,NULL,FALSE,FALSE),
    ('Reserve Bank of India','GOVERNMENT','India',FALSE,'RBININBB',FALSE,FALSE),
    ('US Treasury','GOVERNMENT','USA',FALSE,NULL,FALSE,FALSE),
    ('Dubai Gold Traders','CORPORATE','UAE',FALSE,NULL,FALSE,FALSE),
    ('Silk Route Imports','CORPORATE','Pakistan',TRUE,NULL,FALSE,FALSE),
    ('Lakeview Trust SA','CORPORATE','Switzerland',FALSE,NULL,FALSE,FALSE),
    ('Pan African Mining','CORPORATE','South Africa',FALSE,NULL,FALSE,FALSE),
    ('Al-Rashid Trading','INDIVIDUAL','Iraq',TRUE,NULL,FALSE,FALSE),
    ('Viktor Petrov','INDIVIDUAL','Russia',TRUE,NULL,FALSE,FALSE),
    ('Caribbean Logistics','CORPORATE','Jamaica',TRUE,NULL,FALSE,FALSE),
    ('Sunrise Exports HK','CORPORATE','Hong Kong',FALSE,NULL,FALSE,FALSE),
    ('Ankara Textiles','CORPORATE','Turkey',FALSE,NULL,FALSE,FALSE),
    ('Nordic Shipping AS','CORPORATE','Norway',FALSE,NULL,FALSE,FALSE)
) AS v(name, entity_type, country, risk_jurisdiction, swift_code, is_correspondent, sanctions_listed);

-- -------------------------------------------------------
-- 2.3 Accounts (~1090 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.ACCOUNTS
WITH customer_accounts AS (
    SELECT CUSTOMER_ID, ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID) AS cust_seq
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.CUSTOMERS
)
SELECT
    'ACC' || LPAD(ROW_NUMBER() OVER (ORDER BY c.CUSTOMER_ID, a.account_num)::VARCHAR, 7, '0'),
    c.CUSTOMER_ID, a.acct_type,
    CASE WHEN a.acct_type IN ('NRE','NRO') THEN 'USD' ELSE 'INR' END,
    DATEADD(DAY, -UNIFORM(30, 2000, RANDOM()), CURRENT_DATE()),
    CASE WHEN UNIFORM(1,100,RANDOM()) <= 85 THEN 'ACTIVE' WHEN UNIFORM(1,100,RANDOM()) <= 95 THEN 'DORMANT' ELSE 'FROZEN' END,
    UNIFORM(1000, 50000000, RANDOM())::NUMBER(18,2),
    CASE WHEN a.acct_type = 'LOAN' THEN UNIFORM(100000, 10000000, RANDOM()) ELSE NULL END,
    'BR' || LPAD(UNIFORM(1, 50, RANDOM())::VARCHAR, 3, '0'),
    UNIFORM(1, 100, RANDOM()) > 90,
    CURRENT_TIMESTAMP()
FROM customer_accounts c
CROSS JOIN (
    SELECT 1 AS account_num, 'SAVINGS' AS acct_type UNION ALL
    SELECT 2, 'CURRENT' UNION ALL
    SELECT 3, 'LOAN'
) a
WHERE (a.account_num = 1) OR (a.account_num = 2 AND c.cust_seq <= 350) OR (a.account_num = 3 AND c.cust_seq <= 200)
UNION ALL
SELECT
    'ACC' || LPAD((1050 + ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID))::VARCHAR, 7, '0'),
    CUSTOMER_ID,
    CASE WHEN UNIFORM(1,2,RANDOM()) = 1 THEN 'NRE' ELSE 'NRO' END,
    'USD',
    DATEADD(DAY, -UNIFORM(30, 1000, RANDOM()), CURRENT_DATE()),
    'ACTIVE',
    UNIFORM(50000, 5000000, RANDOM())::NUMBER(18,2),
    NULL, 'BR001', FALSE, CURRENT_TIMESTAMP()
FROM BANKING_COMPLIANCE_AI.RAW_DATA.CUSTOMERS
WHERE COUNTRY_OF_RESIDENCE != 'India';

-- -------------------------------------------------------
-- 2.4 Normal Transactions (~6800 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS
WITH active_accounts AS (
    SELECT ACCOUNT_ID, ACCOUNT_TYPE, CURRENCY,
           ROW_NUMBER() OVER (ORDER BY ACCOUNT_ID) AS rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.ACCOUNTS WHERE STATUS = 'ACTIVE'
),
cp_ids AS (
    SELECT COUNTERPARTY_ID, ROW_NUMBER() OVER (ORDER BY COUNTERPARTY_ID) AS cp_rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.COUNTERPARTIES WHERE SANCTIONS_LISTED = FALSE
),
txn_base AS (
    SELECT ROW_NUMBER() OVER (ORDER BY a.rn, seq.n) AS txn_seq, a.ACCOUNT_ID, a.CURRENCY, seq.n
    FROM active_accounts a
    CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n FROM TABLE(GENERATOR(ROWCOUNT => 10))) seq
    WHERE seq.n <= CASE WHEN a.ACCOUNT_TYPE = 'CURRENT' THEN 10 WHEN a.ACCOUNT_TYPE = 'SAVINGS' THEN 7 ELSE 4 END
)
SELECT
    'TXN' || LPAD(t.txn_seq::VARCHAR, 8, '0'), t.ACCOUNT_ID, cp.COUNTERPARTY_ID,
    CASE MOD(t.txn_seq, 8) WHEN 0 THEN 'CREDIT' WHEN 1 THEN 'DEBIT' WHEN 2 THEN 'TRANSFER' WHEN 3 THEN 'UPI' WHEN 4 THEN 'NEFT' WHEN 5 THEN 'RTGS' WHEN 6 THEN 'CASH_DEPOSIT' ELSE 'CASH_WITHDRAWAL' END,
    CASE MOD(t.txn_seq, 5) WHEN 0 THEN 'ONLINE' WHEN 1 THEN 'MOBILE' WHEN 2 THEN 'BRANCH' WHEN 3 THEN 'ATM' ELSE 'API' END,
    ROUND(UNIFORM(100, 500000, RANDOM()), 2), t.CURRENCY,
    DATEADD(MINUTE, -UNIFORM(1, 525600, RANDOM()), CURRENT_TIMESTAMP()),
    DATEADD(DAY, -UNIFORM(0, 365, RANDOM()), CURRENT_DATE()),
    NULL, NULL, 'India', 'India',
    CASE MOD(t.txn_seq, 6) WHEN 0 THEN 'SALARY' WHEN 1 THEN 'VENDOR_PAYMENT' WHEN 2 THEN 'UTILITY' WHEN 3 THEN 'INVESTMENT' WHEN 4 THEN 'LOAN_EMI' ELSE 'MISC' END,
    'Regular transaction', FALSE,
    CONCAT(UNIFORM(10,223,RANDOM())::VARCHAR,'.',UNIFORM(0,255,RANDOM())::VARCHAR,'.',UNIFORM(0,255,RANDOM())::VARCHAR,'.',UNIFORM(1,254,RANDOM())::VARCHAR),
    'DEV' || LPAD(UNIFORM(1, 2000, RANDOM())::VARCHAR, 5, '0'),
    UNIFORM(8.0, 37.0, RANDOM())::FLOAT, UNIFORM(68.0, 97.0, RANDOM())::FLOAT,
    'COMPLETED', CURRENT_TIMESTAMP()
FROM txn_base t
JOIN cp_ids cp ON cp.cp_rn = MOD(t.txn_seq, 28) + 1
LIMIT 8500;

-- -------------------------------------------------------
-- 2.5 Suspicious Patterns: Structuring (~100 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS
WITH high_risk_customers AS (
    SELECT c.CUSTOMER_ID, a.ACCOUNT_ID, a.CURRENCY,
           ROW_NUMBER() OVER (ORDER BY c.CUSTOMER_ID, a.ACCOUNT_ID) AS rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.CUSTOMERS c
    JOIN BANKING_COMPLIANCE_AI.RAW_DATA.ACCOUNTS a ON c.CUSTOMER_ID = a.CUSTOMER_ID
    WHERE c.RISK_RATING IN ('HIGH', 'CRITICAL') AND a.STATUS = 'ACTIVE'
    LIMIT 25
),
structuring_txns AS (
    SELECT h.CUSTOMER_ID, h.ACCOUNT_ID, h.CURRENCY, h.rn, seq.n AS split_num
    FROM high_risk_customers h
    CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n FROM TABLE(GENERATOR(ROWCOUNT => 5))) seq
    WHERE seq.n <= UNIFORM(3, 5, RANDOM())
)
SELECT
    'STXN' || LPAD(ROW_NUMBER() OVER (ORDER BY s.rn, s.split_num)::VARCHAR, 6, '0'),
    s.ACCOUNT_ID, NULL, 'CASH_DEPOSIT', 'BRANCH',
    ROUND(UNIFORM(890000, 990000, RANDOM()), 2), s.CURRENCY,
    DATEADD(HOUR, -UNIFORM(1, 720, RANDOM()), CURRENT_TIMESTAMP()), CURRENT_DATE(),
    NULL, NULL, 'India', 'India', 'PERSONAL', 'Cash deposit - personal savings', FALSE,
    NULL, NULL, UNIFORM(18.0, 22.0, RANDOM())::FLOAT, UNIFORM(72.0, 78.0, RANDOM())::FLOAT,
    'COMPLETED', CURRENT_TIMESTAMP()
FROM structuring_txns s;

-- -------------------------------------------------------
-- 2.6 Suspicious Patterns: Rapid-fire Fraud (~120 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS
WITH fraud_accounts AS (
    SELECT ACCOUNT_ID, CURRENCY, ROW_NUMBER() OVER (ORDER BY ACCOUNT_ID) AS rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.ACCOUNTS WHERE STATUS = 'ACTIVE' ORDER BY RANDOM() LIMIT 15
),
rapid_txns AS (
    SELECT f.ACCOUNT_ID, f.CURRENCY, f.rn, seq.n
    FROM fraud_accounts f
    CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n FROM TABLE(GENERATOR(ROWCOUNT => 8))) seq
)
SELECT
    'FTXN' || LPAD(ROW_NUMBER() OVER (ORDER BY r.rn, r.n)::VARCHAR, 6, '0'),
    r.ACCOUNT_ID, NULL,
    CASE MOD(r.n, 3) WHEN 0 THEN 'UPI' WHEN 1 THEN 'DEBIT' ELSE 'TRANSFER' END,
    CASE MOD(r.n, 2) WHEN 0 THEN 'MOBILE' ELSE 'ONLINE' END,
    ROUND(UNIFORM(5000, 200000, RANDOM()), 2), r.CURRENCY,
    DATEADD(MINUTE, -(UNIFORM(1, 30, RANDOM())), DATEADD(HOUR, -UNIFORM(1, 168, RANDOM()), CURRENT_TIMESTAMP())),
    CURRENT_DATE(), NULL, NULL,
    CASE MOD(r.n, 4) WHEN 0 THEN 'India' WHEN 1 THEN 'Russia' WHEN 2 THEN 'Nigeria' ELSE 'UAE' END,
    'India', 'PURCHASE', 'Online purchase', MOD(r.n, 4) != 0,
    CONCAT(UNIFORM(10,223,RANDOM())::VARCHAR,'.',UNIFORM(0,255,RANDOM())::VARCHAR,'.',UNIFORM(0,255,RANDOM())::VARCHAR,'.',UNIFORM(1,254,RANDOM())::VARCHAR),
    'DEV' || LPAD(UNIFORM(5000, 9999, RANDOM())::VARCHAR, 5, '0'),
    CASE MOD(r.n, 4) WHEN 0 THEN 19.07 WHEN 1 THEN 55.75 WHEN 2 THEN 6.52 ELSE 25.20 END,
    CASE MOD(r.n, 4) WHEN 0 THEN 72.87 WHEN 1 THEN 37.61 WHEN 2 THEN 3.37 ELSE 55.27 END,
    'COMPLETED', CURRENT_TIMESTAMP()
FROM rapid_txns r;

-- -------------------------------------------------------
-- 2.7 Suspicious Patterns: Shell Company Wires (~70 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS
WITH shell_cps AS (
    SELECT COUNTERPARTY_ID, COUNTRY, ROW_NUMBER() OVER (ORDER BY COUNTERPARTY_ID) AS rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.COUNTERPARTIES
    WHERE ENTITY_TYPE = 'SHELL_COMPANY' OR RISK_JURISDICTION = TRUE
),
suspect_accounts AS (
    SELECT a.ACCOUNT_ID, a.CURRENCY, ROW_NUMBER() OVER (ORDER BY a.ACCOUNT_ID) AS rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.ACCOUNTS a
    JOIN BANKING_COMPLIANCE_AI.RAW_DATA.CUSTOMERS c ON a.CUSTOMER_ID = c.CUSTOMER_ID
    WHERE c.RISK_RATING IN ('HIGH', 'CRITICAL') AND a.STATUS = 'ACTIVE' LIMIT 20
)
SELECT
    'WTXN' || LPAD(ROW_NUMBER() OVER (ORDER BY sa.rn, sc.rn)::VARCHAR, 6, '0'),
    sa.ACCOUNT_ID, sc.COUNTERPARTY_ID,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY sa.rn, sc.rn), 3) WHEN 0 THEN 'SWIFT' WHEN 1 THEN 'WIRE' ELSE 'RTGS' END,
    CASE MOD(ROW_NUMBER() OVER (ORDER BY sa.rn, sc.rn), 2) WHEN 0 THEN 'ONLINE' ELSE 'BRANCH' END,
    ROUND(UNIFORM(2000000, 50000000, RANDOM()), 2), sa.CURRENCY,
    DATEADD(DAY, -UNIFORM(1, 90, RANDOM()), CURRENT_TIMESTAMP()),
    DATEADD(DAY, -UNIFORM(0, 90, RANDOM()), CURRENT_DATE()),
    NULL, NULL, 'India', sc.COUNTRY, 'TRADE_PAYMENT', 'Trade settlement - import consignment',
    TRUE, NULL, NULL, 19.07, 72.87, 'COMPLETED', CURRENT_TIMESTAMP()
FROM suspect_accounts sa CROSS JOIN shell_cps sc
WHERE MOD(sa.rn + sc.rn, 3) = 0 LIMIT 150;

-- -------------------------------------------------------
-- 2.8 Suspicious Patterns: Layering / Round-Tripping (~40 rows)
-- -------------------------------------------------------
INSERT INTO BANKING_COMPLIANCE_AI.RAW_DATA.TRANSACTIONS
WITH layer_accounts AS (
    SELECT ACCOUNT_ID, CURRENCY, ROW_NUMBER() OVER (ORDER BY ACCOUNT_ID) AS rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.ACCOUNTS WHERE STATUS = 'ACTIVE' ORDER BY RANDOM() LIMIT 10
),
layer_cps AS (
    SELECT COUNTERPARTY_ID, COUNTRY, ROW_NUMBER() OVER (ORDER BY COUNTERPARTY_ID) AS rn
    FROM BANKING_COMPLIANCE_AI.RAW_DATA.COUNTERPARTIES
    WHERE ENTITY_TYPE IN ('SHELL_COMPANY', 'CORPORATE') AND RISK_JURISDICTION = TRUE LIMIT 5
)
SELECT 'LTXN' || LPAD((la.rn * 10 + lc.rn)::VARCHAR, 6, '0'),
    la.ACCOUNT_ID, lc.COUNTERPARTY_ID, 'SWIFT', 'ONLINE',
    ROUND(UNIFORM(5000000, 20000000, RANDOM()), 2), la.CURRENCY,
    DATEADD(DAY, -UNIFORM(15, 60, RANDOM()), CURRENT_TIMESTAMP()),
    DATEADD(DAY, -UNIFORM(15, 60, RANDOM()), CURRENT_DATE()),
    NULL, NULL, 'India', lc.COUNTRY, 'CONSULTANCY_FEE', 'Consultancy services payment',
    TRUE, NULL, NULL, 19.07, 72.87, 'COMPLETED', CURRENT_TIMESTAMP()
FROM layer_accounts la CROSS JOIN layer_cps lc WHERE MOD(la.rn + lc.rn, 2) = 0
UNION ALL
SELECT 'LTXN' || LPAD((la.rn * 10 + lc.rn + 500)::VARCHAR, 6, '0'),
    la.ACCOUNT_ID, lc.COUNTERPARTY_ID, 'SWIFT', 'ONLINE',
    ROUND(UNIFORM(4750000, 21000000, RANDOM()), 2), la.CURRENCY,
    DATEADD(DAY, -UNIFORM(1, 14, RANDOM()), CURRENT_TIMESTAMP()),
    DATEADD(DAY, -UNIFORM(1, 14, RANDOM()), CURRENT_DATE()),
    NULL, NULL, lc.COUNTRY, 'India', 'INVESTMENT_RETURN', 'Return on overseas investment',
    TRUE, NULL, NULL, 19.07, 72.87, 'COMPLETED', CURRENT_TIMESTAMP()
FROM layer_accounts la CROSS JOIN layer_cps lc WHERE MOD(la.rn + lc.rn, 2) = 0;
