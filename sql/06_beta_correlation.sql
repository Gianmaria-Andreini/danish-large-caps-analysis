-- 06_beta_correlation.sql
-- How each stock moves together with the market (OMXC25 index).
--   * correlation: from -1 to +1, how closely the stock follows the index
--   * beta: how much the stock moves when the index moves 1%
--     (beta 1.2 = on average +1.2% when the index does +1%)
-- REGR_SLOPE(y, x) is the slope of the regression of y (stock) on x (index), i.e. the beta.
-- Stock and index are joined only on the days that both have a return.

CREATE OR REPLACE VIEW stock_vs_index AS
SELECT
    s.ticker,
    s.trade_date,
    s.daily_return AS stock_return,
    i.daily_return AS index_return
FROM daily_returns s
JOIN daily_returns i
  ON i.trade_date = s.trade_date
 AND i.ticker = '^OMXC25'
WHERE s.ticker <> '^OMXC25'
  AND s.daily_return IS NOT NULL
  AND i.daily_return IS NOT NULL;

-- Whole period
CREATE OR REPLACE VIEW beta_correlation AS
SELECT
    ticker,
    COUNT(*)                                 AS common_days,
    REGR_SLOPE(stock_return, index_return)   AS beta,
    CORR(stock_return, index_return)         AS correlation
FROM stock_vs_index
GROUP BY ticker;

SELECT ticker,
       common_days,
       ROUND(beta::numeric, 2)        AS beta,
       ROUND(correlation::numeric, 2) AS correlation
FROM beta_correlation
ORDER BY beta DESC;

-- Beta year by year: has the stock become more or less sensitive to the market?
SELECT ticker,
       EXTRACT(YEAR FROM trade_date)::int                          AS year,
       ROUND(REGR_SLOPE(stock_return, index_return)::numeric, 2)   AS beta
FROM stock_vs_index
GROUP BY ticker, EXTRACT(YEAR FROM trade_date)
ORDER BY ticker, year;
