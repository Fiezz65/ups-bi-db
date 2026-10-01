-- =========================================================
-- 1. FACT HARUS MEMILIKI DATA
-- =========================================================

SELECT 'fact_shipment' AS fact, COUNT(*) AS total
FROM dw.fact_shipment

UNION ALL

SELECT 'fact_payment', COUNT(*)
FROM dw.fact_payment;


-- =========================================================
-- 2. DUPLICATE TRANSAKSI SOURCE PADA FACT
-- =========================================================

SELECT 'duplicate_fact_shipment' AS test, COUNT(*) AS result
FROM (
    SELECT shipment_id
    FROM dw.fact_shipment
    GROUP BY shipment_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'duplicate_fact_payment', COUNT(*)
FROM (
    SELECT payment_id
    FROM dw.fact_payment
    GROUP BY payment_id
    HAVING COUNT(*) > 1
) x;


-- =========================================================
-- 3. ORPHAN FOREIGN KEY FACT SHIPMENT
-- =========================================================

SELECT 'orphan_customer' AS test, COUNT(*) AS result
FROM dw.fact_shipment fs
LEFT JOIN dw.dim_customer dc
    ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL

UNION ALL

SELECT 'orphan_service', COUNT(*)
FROM dw.fact_shipment fs
LEFT JOIN dw.dim_service ds
    ON fs.service_key = ds.service_key
WHERE ds.service_key IS NULL

UNION ALL

SELECT 'orphan_origin_location', COUNT(*)
FROM dw.fact_shipment fs
LEFT JOIN dw.dim_location dl
    ON fs.origin_location_key = dl.location_key
WHERE dl.location_key IS NULL

UNION ALL

SELECT 'orphan_destination_location', COUNT(*)
FROM dw.fact_shipment fs
LEFT JOIN dw.dim_location dl
    ON fs.destination_location_key = dl.location_key
WHERE dl.location_key IS NULL

UNION ALL

SELECT 'orphan_shipment_date', COUNT(*)
FROM dw.fact_shipment fs
LEFT JOIN dw.dim_date dd
    ON fs.shipment_date_key = dd.date_key
WHERE dd.date_key IS NULL

UNION ALL

SELECT 'orphan_shipment_status', COUNT(*)
FROM dw.fact_shipment fs
LEFT JOIN dw.dim_shipment_status dss
    ON fs.shipment_status_key = dss.shipment_status_key
WHERE dss.shipment_status_key IS NULL;


-- =========================================================
-- 4. ORPHAN FOREIGN KEY FACT PAYMENT
-- =========================================================

SELECT 'orphan_payment_customer' AS test, COUNT(*) AS result
FROM dw.fact_payment fp
LEFT JOIN dw.dim_customer dc
    ON fp.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL

UNION ALL

SELECT 'orphan_payment_service', COUNT(*)
FROM dw.fact_payment fp
LEFT JOIN dw.dim_service ds
    ON fp.service_key = ds.service_key
WHERE ds.service_key IS NULL

UNION ALL

SELECT 'orphan_payment_origin', COUNT(*)
FROM dw.fact_payment fp
LEFT JOIN dw.dim_location dl
    ON fp.origin_location_key = dl.location_key
WHERE dl.location_key IS NULL

UNION ALL

SELECT 'orphan_payment_destination', COUNT(*)
FROM dw.fact_payment fp
LEFT JOIN dw.dim_location dl
    ON fp.destination_location_key = dl.location_key
WHERE dl.location_key IS NULL

UNION ALL

SELECT 'orphan_payment_date', COUNT(*)
FROM dw.fact_payment fp
LEFT JOIN dw.dim_date dd
    ON fp.payment_date_key = dd.date_key
WHERE dd.date_key IS NULL

UNION ALL

SELECT 'orphan_payment_dimension', COUNT(*)
FROM dw.fact_payment fp
LEFT JOIN dw.dim_payment dp
    ON fp.payment_key = dp.payment_key
WHERE dp.payment_key IS NULL;


-- =========================================================
-- 5. JOIN FACT + DIMENSION
-- =========================================================

SELECT
    fs.shipment_id,
    fs.tracking_number,
    dc.customer_name,
    ds.service_name,
    dd.full_date,
    dss.status_name,
    fs.shipping_cost
FROM dw.fact_shipment fs
JOIN dw.dim_customer dc
    ON fs.customer_key = dc.customer_key
JOIN dw.dim_service ds
    ON fs.service_key = ds.service_key
JOIN dw.dim_date dd
    ON fs.shipment_date_key = dd.date_key
JOIN dw.dim_shipment_status dss
    ON fs.shipment_status_key = dss.shipment_status_key
LIMIT 10;


-- =========================================================
-- 6. DATE DIMENSION
-- =========================================================

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    COUNT(*) AS total_shipment
FROM dw.fact_shipment fs
JOIN dw.dim_date dd
    ON fs.shipment_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name
ORDER BY
    dd.year,
    dd.month;