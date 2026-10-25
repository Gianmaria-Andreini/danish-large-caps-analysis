-- 05_risk.sql
-- Risk measures per stock:
--   * volatility: standard deviation of daily returns, annualised with SQRT(252 trading days)
--   * rolling 30-day volatility (for the dashboard line chart)
--   * drawdown: how far the price is below its highest level so far
--   * max drawdown: the worst drawdown in the whole period

-- Rolling 30-day annualised volatility, per stock and day
CREATE OR REPLACE VIEW rolling_volatility AS
SELECT
    ticker,
    trade_date,
    STDDEV(daily_return) OVER (PARTITION BY ticker ORDER BY trade_date
                               ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) * SQRT(252.0) AS volatility_30d
FROM daily_returns;

-- Drawdown, per stock and day
CREATE OR REPLACE VIEW drawdowns AS
SELECT
    ticker,
    trade_date,
    adj_close,
    MAX(adj_close) OVER (PARTITION BY ticker ORDER BY trade_date) AS running_peak,
    adj_close / MAX(adj_close) OVER (PARTITION BY ticker ORDER BY trade_date) - 1 AS drawdown
FROM prices;

-- Summary per stock: return vs risk
CREATE OR REPLACE VIEW risk_return_summary AS
WITH vol AS (
    SELECT ticker,
           STDDEV(daily_return) * SQRT(252.0) AS annual_volatility
    FROM daily_returns
    GROUP BY ticker
),
dd AS (
    SELECT DISTINCT ON (ticker)
           ticker, drawdown AS max_drawdown, trade_date AS max_drawdown_date
    FROM drawdowns
    ORDER BY ticker, drawdown
),
ret AS (
    SELECT DISTINCT
        ticker,
        FIRST_VALUE(trade_date) OVER w AS first_day,
        FIRST_VALUE(adj_close)  OVER w AS first_price,
        LAST_VALUE(trade_date)  OVER w AS last_day,
        LAST_VALUE(adj_close)   OVER w AS last_price
    FROM prices
    WINDOW w AS (PARTITION BY ticker ORDER BY trade_date
                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
)
SELECT
    ret.ticker,
    POWER(last_price / first_price, 365.25 / (last_day - first_day)) - 1 AS cagr,
    vol.annual_volatility,
    (POWER(last_price / first_price, 365.25 / (last_day - first_day)) - 1)
        / vol.annual_volatility AS return_per_unit_of_risk,
    dd.max_drawdown,
    dd.max_drawdown_date
FROM ret
JOIN vol USING (ticker)
JOIN dd  USING (ticker);

SELECT
    ticker,
    ROUND(cagr * 100, 1)                    AS cagr_pct,
    ROUND(annual_volatility * 100, 1)       AS volatility_pct,
    ROUND(return_per_unit_of_risk, 2)       AS return_per_risk,
    ROUND(max_drawdown * 100, 1)            AS max_drawdown_pct,
    max_drawdown_date
FROM risk_return_summary
ORDER BY return_per_unit_of_risk DESC;
