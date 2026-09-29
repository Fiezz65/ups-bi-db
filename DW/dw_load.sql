INSERT INTO dw.dim_customer (
    customer_id,
    customer_name,
    phone,
    address
)
SELECT
    customer_id,
    customer_name,
    phone,
    address
FROM public.customers;

INSERT INTO dw.dim_service (
    service_id,
    service_name,
    base_price
)
SELECT
    service_id,
    service_name,
    base_price
FROM public.services;

INSERT INTO dw.dim_location (
    location_id,
    location_name,
    city
)
SELECT
    location_id,
    location_name,
    city
FROM public.locations;

WITH all_dates AS (
    SELECT shipment_date AS tanggal
    FROM public.shipments

    UNION

    SELECT pickup_time::DATE
    FROM public.pickups

    UNION

    SELECT delivery_time::DATE
    FROM public.deliveries

    UNION

    SELECT payment_date::DATE
    FROM public.payments
),
date_range AS (
    SELECT generate_series(
        MIN(tanggal),
        MAX(tanggal),
        INTERVAL '1 day'
    )::DATE AS tanggal
    FROM all_dates
)
INSERT INTO dw.dim_date (
    date_key,
    full_date,
    day,
    day_name,
    month,
    month_name,
    quarter,
    year,
    is_weekend
)
SELECT
    TO_CHAR(tanggal, 'YYYYMMDD')::INT,
    tanggal,
    EXTRACT(DAY FROM tanggal)::INT,
    TRIM(TO_CHAR(tanggal, 'Day')),
    EXTRACT(MONTH FROM tanggal)::INT,
    TRIM(TO_CHAR(tanggal, 'Month')),
    EXTRACT(QUARTER FROM tanggal)::INT,
    EXTRACT(YEAR FROM tanggal)::INT,
    EXTRACT(ISODOW FROM tanggal) IN (6, 7)
FROM date_range;

INSERT INTO dw.dim_status (
    status_type,
    status_name
)
SELECT
    'SHIPMENT',
    status
FROM public.shipments

UNION

SELECT
    'PICKUP',
    pickup_status
FROM public.pickups

UNION

SELECT
    'DELIVERY',
    delivery_status
FROM public.deliveries;

INSERT INTO dw.dim_payment (
    payment_method,
    payment_status
)
SELECT DISTINCT
    payment_method,
    payment_status
FROM public.payments;

INSERT INTO dw.fact_shipment (
    shipment_date_key,
    pickup_date_key,
    delivery_date_key,
    customer_key,
    service_key,
    origin_location_key,
    destination_location_key,
    shipment_status_key,
    pickup_status_key,
    delivery_status_key,
    tracking_number,
    weight_kg,
    shipping_cost,
    delivery_duration_hours,
    tracking_event_count
)
SELECT
    shipment_date.date_key,
    pickup_date.date_key,
    delivery_date.date_key,
    customer.customer_key,
    service.service_key,
    origin_location.location_key,
    destination_location.location_key,
    shipment_status.status_key,
    pickup_status.status_key,
    delivery_status.status_key,
    s.tracking_number,
    s.weight_kg,
    s.shipping_cost,
    CASE
        WHEN p.pickup_time IS NOT NULL
             AND d.delivery_time IS NOT NULL
        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (d.delivery_time - p.pickup_time)
                ) / 3600
            )::NUMERIC,
            2
        )
        ELSE NULL
    END,
    COALESCE(te.tracking_event_count, 0)
FROM public.shipments s
JOIN dw.dim_customer customer
    ON customer.customer_id = s.customer_id
JOIN dw.dim_service service
    ON service.service_id = s.service_id
JOIN dw.dim_location origin_location
    ON origin_location.location_id = s.origin_location_id
JOIN dw.dim_location destination_location
    ON destination_location.location_id = s.destination_location_id
JOIN dw.dim_date shipment_date
    ON shipment_date.full_date = s.shipment_date
JOIN dw.dim_status shipment_status
    ON shipment_status.status_type = 'SHIPMENT'
    AND shipment_status.status_name = s.status
LEFT JOIN public.pickups p
    ON p.shipment_id = s.shipment_id
LEFT JOIN dw.dim_date pickup_date
    ON pickup_date.full_date = p.pickup_time::DATE
LEFT JOIN dw.dim_status pickup_status
    ON pickup_status.status_type = 'PICKUP'
    AND pickup_status.status_name = p.pickup_status
LEFT JOIN public.deliveries d
    ON d.shipment_id = s.shipment_id
LEFT JOIN dw.dim_date delivery_date
    ON delivery_date.full_date = d.delivery_time::DATE
LEFT JOIN dw.dim_status delivery_status
    ON delivery_status.status_type = 'DELIVERY'
    AND delivery_status.status_name = d.delivery_status
LEFT JOIN (
    SELECT
        shipment_id,
        COUNT(*)::INT AS tracking_event_count
    FROM public.tracking_events
    GROUP BY shipment_id
) te
    ON te.shipment_id = s.shipment_id;

INSERT INTO dw.fact_payment (
    payment_date_key,
    customer_key,
    service_key,
    origin_location_key,
    destination_location_key,
    payment_key,
    payment_id,
    tracking_number,
    amount
)
SELECT
    payment_date.date_key,
    customer.customer_key,
    service.service_key,
    origin_location.location_key,
    destination_location.location_key,
    payment_dim.payment_key,
    p.payment_id,
    s.tracking_number,
    p.amount
FROM public.payments p
JOIN public.shipments s
    ON s.shipment_id = p.shipment_id
JOIN dw.dim_date payment_date
    ON payment_date.full_date = p.payment_date::DATE
JOIN dw.dim_customer customer
    ON customer.customer_id = s.customer_id
JOIN dw.dim_service service
    ON service.service_id = s.service_id
JOIN dw.dim_location origin_location
    ON origin_location.location_id = s.origin_location_id
JOIN dw.dim_location destination_location
    ON destination_location.location_id = s.destination_location_id
JOIN dw.dim_payment payment_dim
    ON payment_dim.payment_method = p.payment_method
    AND payment_dim.payment_status = p.payment_status;