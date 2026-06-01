--Network Congestion & Fee
--Find daily transaction counts, total value transferred (ETH) and average gas price over 30days.

SELECT
  DATE(block_timestamp) AS transaction_date,
  COUNT(*) AS total_transactions,
  ROUND(SUM(value / POW(10, 18)), 2) AS total_eth_transferred,
  ROUND(AVG(gas_price / POW(10, 9)), 2) AS avg_gas_price_gwei
FROM `bigquery-public-data.crypto_ethereum.transactions`
WHERE DATE(block_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY transaction_date
ORDER BY transaction_date;

-- Whale Wallet Tier Segmentation: Categorize active addresses by volume
-- Whale (>= 1k ETH), Shark (100-999), Fish (< 100)

WITH
  wallet_volume AS (
    SELECT from_address AS wallet_address, SUM(value / 1e18) AS total_eth_sent
    FROM `bigquery-public-data.crypto_ethereum.transactions`
    WHERE from_address IS NOT NULL
    GROUP BY 1
  )
SELECT
  wallet_address,
  ROUND(total_eth_sent, 2) AS total_eth_sent,
  CASE
    WHEN total_eth_sent >= 1000 THEN 'Whale'
    WHEN total_eth_sent >= 100 THEN 'Shark'
    ELSE 'Fish'
    END
    AS wallet_tier
FROM wallet_volume
ORDER BY total_eth_sent DESC;

--Daily Top-Value Transfers: For each day of a chosen week, isolate the top 5 largest value transactions.

WITH
  DailyRankings AS (
    SELECT
      `hash` AS transaction_id,
      block_timestamp AS transaction_date,
      (value / 1e18) AS amount,
      ROW_NUMBER()
        OVER (PARTITION BY DATE(block_timestamp) ORDER BY value DESC)
        AS rank_per_day
    FROM `bigquery-public-data.crypto_ethereum.transactions`
    WHERE DATE(block_timestamp) BETWEEN '2026-05-18' AND '2026-05-24'
  )
SELECT transaction_id, transaction_date, amount
FROM DailyRankings
WHERE rank_per_day <= 5
ORDER BY transaction_date, amount DESC;

-- 7-Day Rolling Average of Gas Prices
-- Calculates the average gas price (in Gwei) for each day,
-- then uses a window function to find the 7-day rolling average.

WITH
  DailyGas AS (
    SELECT
      DATE(block_timestamp) AS price_date,
      AVG(gas_price / 1e9) AS daily_avg_gas_price
    FROM `bigquery-public-data.crypto_ethereum.transactions`
    WHERE block_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
    GROUP BY 1
  )
SELECT
  price_date,
  ROUND(daily_avg_gas_price, 2) AS daily_gas_price_gwei,
  ROUND(
    AVG(daily_avg_gas_price)
      OVER (ORDER BY price_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
    2)
    AS rolling_7day_avg_gwei
FROM DailyGas
ORDER BY price_date DESC;

