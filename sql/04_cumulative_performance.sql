-- 04_cumulative_performance.sql
-- How much 100 DKK invested on the first trading day of 2019 would be worth on each day.
-- FIRST_VALUE takes the first adjusted price of each stock; every price is divided by it.

CREATE OR REPLACE VIEW cumulative_performance AS
SELECT
    ticker,
    trade_date,
    adj_close,
    ROUND(100 * adj_close
          / FIRST_VALUE(adj_close) OVER (PARTITION BY ticker ORDER BY trade_date), 2) AS value_of_100
FROM prices;

-- Summary: total return and average yearly return (CAGR) per stock over the whole period
WITH first_last AS (
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
    ticker,
    first_day,
    last_day,
    ROUND(100 * last_price / first_price, 0)                 AS value_of_100,
    ROUND((last_price / first_price - 1) * 100, 1)           AS total_return_pct,
    ROUND((POWER(last_price / first_price,
                 365.25 / (last_day - first_day)) - 1) * 100, 1) AS cagr_pct
FROM first_last
ORDER BY total_return_pct DESC;
