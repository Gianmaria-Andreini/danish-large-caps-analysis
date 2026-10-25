-- 01_create_tables.sql
-- Tables for the Danish large caps project. Columns match the CSV files
-- produced by scarica_dati.py (folder "data").

DROP TABLE IF EXISTS fundamentals;
DROP TABLE IF EXISTS prices;
DROP TABLE IF EXISTS companies;

CREATE TABLE companies (
    ticker  TEXT PRIMARY KEY,
    name    TEXT NOT NULL,
    sector  TEXT
);

CREATE TABLE prices (
    ticker      TEXT REFERENCES companies (ticker),
    trade_date  DATE,
    open        NUMERIC,
    high        NUMERIC,
    low         NUMERIC,
    close       NUMERIC,
    adj_close   NUMERIC,   -- adjusted for dividends and splits: use this for returns
    volume      BIGINT,
    PRIMARY KEY (ticker, trade_date)
);

CREATE TABLE fundamentals (
    ticker                    TEXT REFERENCES companies (ticker),
    fiscal_year               INT,
    currency                  TEXT,     -- reporting currency (Maersk reports in USD, Vestas in EUR)
    revenue                   NUMERIC,
    ebit                      NUMERIC,
    net_income                NUMERIC,
    diluted_shares            NUMERIC,
    dividends_paid_per_share  NUMERIC,  -- dividends paid during the calendar year, in DKK
    PRIMARY KEY (ticker, fiscal_year)
);

-- Import the CSV files (import companies first).
-- In pgAdmin: right click on each table -> Import/Export Data -> Import,
-- choose the CSV, Format csv, and switch on "Header" in the Options tab.
-- Or, in the PSQL Tool of pgAdmin, with your own path:
-- \copy companies    FROM '/Users/<you>/.../data/companies.csv'    WITH (FORMAT csv, HEADER true)
-- \copy prices       FROM '/Users/<you>/.../data/prices.csv'       WITH (FORMAT csv, HEADER true)
-- \copy fundamentals FROM '/Users/<you>/.../data/fundamentals.csv' WITH (FORMAT csv, HEADER true)

-- Quick checks after the import
SELECT ticker, COUNT(*) AS days, MIN(trade_date) AS first_day, MAX(trade_date) AS last_day
FROM prices
GROUP BY ticker
ORDER BY ticker;

SELECT * FROM fundamentals ORDER BY ticker, fiscal_year;
