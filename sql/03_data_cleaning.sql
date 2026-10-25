-- 03_data_cleaning.sql
-- Orsted rights issue (September 2025): Yahoo Finance adjusted only the prices
-- of 8-16 September, so the series showed an artificial -44.9% on 8 September.
-- Fix: apply the TERP factor to all earlier adjusted prices.
--   TERP   = (204.5 + 15/7 * 66.60) / (1 + 15/7) = 110.48 DKK
--   factor = 110.48 / 204.5 = 0.5402
-- (204.5 = close on 5 Sept 2025; 66.60 DKK = subscription price; 15/7 = new shares per existing share)
-- Safe to run more than once: it only applies while the 5 Sept price is still unadjusted (> 150).

UPDATE prices
SET adj_close = adj_close * 0.5402
WHERE ticker = 'ORSTED.CO'
  AND trade_date < '2025-09-08'
  AND (SELECT adj_close FROM prices
       WHERE ticker = 'ORSTED.CO' AND trade_date = '2025-09-05') > 150;

-- Check: the 5 Sept price should now be about 110.5 and the 8 Sept return about +2%
SELECT trade_date, adj_close, ROUND(daily_return * 100, 1) AS pct
FROM daily_returns
WHERE ticker = 'ORSTED.CO'
  AND trade_date BETWEEN '2025-09-03' AND '2025-09-10'
ORDER BY trade_date;
