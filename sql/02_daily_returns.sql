-- 02_daily_returns.sql
-- Daily return per stock: (today's adjusted price / yesterday's) - 1.
-- LAG takes the previous row; PARTITION BY ticker restarts the calculation for each company.

CREATE OR REPLACE VIEW daily_returns AS
SELECT
    ticker,
    trade_date,
    adj_close,
    adj_close / LAG(adj_close) OVER (PARTITION BY ticker ORDER BY trade_date) - 1 AS daily_return
FROM prices;

-- Check 1: summary per stock
SELECT ticker,
       COUNT(daily_return)                AS days,
       ROUND(AVG(daily_return) * 100, 3)  AS avg_daily_pct,
       ROUND(MIN(daily_return) * 100, 1)  AS worst_day_pct,
       ROUND(MAX(daily_return) * 100, 1)  AS best_day_pct
FROM daily_returns
GROUP BY ticker
ORDER BY ticker;

-- Check 2: days with moves above +/-15% (used to find data errors)
SELECT ticker, trade_date, adj_close, ROUND(daily_return * 100, 1) AS pct
FROM daily_returns
WHERE ABS(daily_return) > 0.15
ORDER BY daily_return;
