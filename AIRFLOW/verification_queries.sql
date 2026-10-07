-- [Q1] Jumlah baris seluruh dimension & fact
SELECT 'dim_customer' AS tabel, COUNT(*) AS total FROM dw.dim_customer
UNION ALL SELECT 'dim_service', COUNT(*) FROM dw.dim_service
UNION ALL SELECT 'dim_location', COUNT(*) FROM dw.dim_location
UNION ALL SELECT 'dim_date', COUNT(*) FROM dw.dim_date
UNION ALL SELECT 'dim_shipment_status', COUNT(*) FROM dw.dim_shipment_status
UNION ALL SELECT 'dim_pickup_status', COUNT(*) FROM dw.dim_pickup_status
UNION ALL SELECT 'dim_delivery_status', COUNT(*) FROM dw.dim_delivery_status
UNION ALL SELECT 'dim_payment', COUNT(*) FROM dw.dim_payment
UNION ALL SELECT 'fact_shipment', COUNT(*) FROM dw.fact_shipment
UNION ALL SELECT 'fact_payment', COUNT(*) FROM dw.fact_payment;

-- [Q2] Jumlah baris fact (untuk bukti rerun)
SELECT 'fact_shipment' AS fact_name, COUNT(*) AS total_rows FROM dw.fact_shipment
UNION ALL
SELECT 'fact_payment', COUNT(*) FROM dw.fact_payment;

-- [Q3] Kosongkan DW (hanya sekali, sebelum Airflow pertama kali dijalankan)
TRUNCATE dw.fact_shipment, dw.fact_payment,
         dw.dim_customer, dw.dim_service, dw.dim_location, dw.dim_date,
         dw.dim_shipment_status, dw.dim_pickup_status, dw.dim_delivery_status, dw.dim_payment
RESTART IDENTITY CASCADE;