-- =========================================================
-- REPORT 1
-- JUMLAH SHIPMENT DAN TOTAL BIAYA PER BULAN
-- =========================================================

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    COUNT(*) AS total_shipment,
    SUM(fs.shipping_cost) AS total_shipping_cost
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


-- =========================================================
-- REPORT 2
-- JUMLAH SHIPMENT DAN TOTAL BIAYA PER CUSTOMER
-- =========================================================

SELECT
    dc.customer_name,
    COUNT(*) AS total_shipment,
    SUM(fs.shipping_cost) AS total_shipping_cost
FROM dw.fact_shipment fs
JOIN dw.dim_customer dc
    ON fs.customer_key = dc.customer_key
GROUP BY
    dc.customer_key,
    dc.customer_name
ORDER BY
    total_shipment DESC,
    dc.customer_name;


-- =========================================================
-- REPORT 3
-- RINGKASAN PEMBAYARAN
-- =========================================================

SELECT
    dp.payment_method,
    dp.payment_status,
    COUNT(*) AS total_payment,
    SUM(fp.amount) AS total_amount
FROM dw.fact_payment fp
JOIN dw.dim_payment dp
    ON fp.payment_key = dp.payment_key
GROUP BY
    dp.payment_method,
    dp.payment_status
ORDER BY
    total_amount DESC;