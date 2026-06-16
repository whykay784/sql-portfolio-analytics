-- World Port Analysis: Count total ports and breakdown by size (Large, Medium, Small) per country.
-- Uses the BigQuery public dataset for international ports.

SELECT
  country,
  COUNT(*) AS total_ports,
  COUNTIF(harbor_size = 'L') AS large_ports,
  COUNTIF(harbor_size = 'M') AS medium_ports,
  COUNTIF(harbor_size = 'S') AS small_ports
FROM `bigquery-public-data.geo_international_ports.world_port_index`
GROUP BY country
ORDER BY total_ports DESC;

-- World Port Risk Profile Analysis: Categorize ports by size and shelter quality
-- Uses the BigQuery public dataset for international ports.

SELECT
  port_name,
  country,
  harbor_size,
  shelter_afforded,
  CASE
    WHEN harbor_size = 'S' AND shelter_afforded IN ('P', 'N') THEN 'High Risk'
    WHEN harbor_size = 'L' AND shelter_afforded IN ('E', 'G')
      THEN 'Premium Gateway'
    ELSE 'Moderate Risk'
    END
    AS risk_profile
FROM `bigquery-public-data.geo_international_ports.world_port_index`;

-- Top 3 Largest Ports per Region
-- Ranks ports within each region based on harbor size and filters for the top 3.

SELECT
  region_number,
  port_name,
  country,
  harbor_size,
  DENSE_RANK()
    OVER (PARTITION BY region_number ORDER BY harbor_size DESC) AS regional_rank
FROM `bigquery-public-data.geo_international_ports.world_port_index`
QUALIFY regional_rank <= 3
ORDER BY region_number, regional_rank;

-- Distance Calculation: Finding the 5 nearest ports to Lagos
-- Uses the BigQuery public dataset for international ports.

WITH
  selected_port AS (
    SELECT port_name, country, port_latitude, port_longitude
    FROM `bigquery-public-data.geo_international_ports.world_port_index`
    WHERE UPPER(port_name) = 'LAGOS'
  )
SELECT
  p.port_name,
  p.country,
  ROUND(
    ST_DISTANCE(
      ST_GEOGPOINT(s.port_longitude, s.port_latitude),
      ST_GEOGPOINT(p.port_longitude, p.port_latitude))
      / 1000,
    2)
    AS distance_km
FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
CROSS JOIN selected_port AS s
WHERE p.port_name <> s.port_name
ORDER BY distance_km
LIMIT 5;

