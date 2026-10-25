-- 07_dashboard_exports.sql
-- Two tables for Power BI, exported to CSV:
--   dashboard_daily   one row per stock per day (lines and charts over time)
--   dashboard_summary one row per stock (KPI cards, risk vs return scatter)

CREATE OR REPLACE VIEW dashboard_daily AS
SELECT
    c.ticker,
    c.name,
    c.sector,
    p.trade_date,
    ROUND(p.adj_close, 4)                  AS adj_close,
    ROUND(r.daily_return, 6)               AS daily_return,
    cp.value_of_100,
    ROUND(d.drawdown, 4)                   AS drawdown,
    ROUND(v.volatility_30d, 4)             AS volatility_30d
FROM prices p
JOIN companies c               ON c.ticker = p.ticker
JOIN daily_returns r           ON r.ticker = p.ticker AND r.trade_date = p.trade_date
JOIN cumulative_performance cp ON cp.ticker = p.ticker AND cp.trade_date = p.trade_date
JOIN drawdowns d               ON d.ticker = p.ticker AND d.trade_date = p.trade_date
JOIN rolling_volatility v      ON v.ticker = p.ticker AND v.trade_date = p.trade_date;

CREATE OR REPLACE VIEW dashboard_summary AS
SELECT
    c.ticker,
    c.name,
    c.sector,
    ROUND(s.cagr, 4)                     AS cagr,
    ROUND(s.annual_volatility, 4)        AS annual_volatility,
    ROUND(s.return_per_unit_of_risk, 2)  AS return_per_risk,
    ROUND(s.max_drawdown, 4)             AS max_drawdown,
    s.max_drawdown_date,
    ROUND(b.beta::numeric, 2)            AS beta,          -- empty for the index itself
    ROUND(b.correlation::numeric, 2)     AS correlation
FROM risk_return_summary s
JOIN companies c             ON c.ticker = s.ticker
LEFT JOIN beta_correlation b ON b.ticker = s.ticker;

-- Run each SELECT on its own, then save the result as CSV
-- (Data Output panel -> "Save results to file" button):
--   1) dashboard_daily.csv
SELECT * FROM dashboard_daily ORDER BY ticker, trade_date;
--   2) dashboard_summary.csv
SELECT * FROM dashboard_summary ORDER BY return_per_risk DESC;
