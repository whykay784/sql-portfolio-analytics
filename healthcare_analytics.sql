--Hospital Cost Markup Analysis: Calculate markup ratio (covered charges / total payments) for top hospitals
-- Uses BigQuery public data for Medicare inpatient charges from 2014.

SELECT
  provider_name,
  provider_state,
  AVG(average_covered_charges) AS avg_covered_charges,
  AVG(average_total_payments) AS avg_total_payments,
  ROUND(
    SAFE_DIVIDE(AVG(average_covered_charges), AVG(average_total_payments)), 2)
    AS markup_ratio
FROM `bigquery-public-data.medicare.inpatient_charges_2014`
GROUP BY 1, 2
ORDER BY markup_ratio DESC
LIMIT 20;

-- Top 5 Highest-Paying States per Medical Procedure (DRG)
-- Identifies which states have the highest average Medicare payments for each type of procedure.

SELECT
  provider_state,
  drg_definition,
  AVG(average_total_payments) AS avg_payment,
  DENSE_RANK()
    OVER (PARTITION BY drg_definition ORDER BY AVG(average_total_payments) DESC)
    AS payment_rank
FROM `bigquery-public-data.medicare.inpatient_charges_2014`
GROUP BY provider_state, drg_definition
QUALIFY payment_rank <= 5
ORDER BY drg_definition, payment_rank;

-- Medicare Inpatient Outlier Detection: Finding hospitals with charges > 2 Standard Deviations from the national average

WITH
  provider_stats AS (
    SELECT
      provider_name,
      provider_state,
      average_covered_charges,
      AVG(average_covered_charges) OVER () AS national_avg,
      STDDEV_SAMP(average_covered_charges) OVER () AS national_stddev
    FROM `bigquery-public-data.medicare.inpatient_charges_2014`
  )
SELECT
  provider_name,
  provider_state,
  average_covered_charges,
  ROUND(national_avg, 2) AS national_avg
FROM provider_stats
WHERE average_covered_charges > national_avg + (2 * national_stddev)
ORDER BY average_covered_charges DESC;

-- Medicare Analysis: Average Hospital Payments vs. Average Part D Drug Costs by State
-- Joins inpatient charges with prescriber data for the year 2014.

SELECT
  i.provider_state,
  ROUND(AVG(i.average_total_payments), 2) AS avg_hospital_payment,
  ROUND(AVG(p.total_drug_cost), 2) AS avg_drug_cost
FROM `bigquery-public-data.medicare.inpatient_charges_2014` AS i
INNER JOIN `bigquery-public-data.medicare.part_d_prescriber_2014` AS p
  ON i.provider_state = p.nppes_provider_state
GROUP BY i.provider_state
ORDER BY avg_hospital_payment DESC;




