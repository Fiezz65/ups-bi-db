INSERT INTO customers (
    customer_name,
    phone,
    address
)
VALUES
    ('Abdul Malik Fajar Putra Syamsi', '081200000001', 'Banjarmasin'),
    ('Sebastian Abe Santoso', '081200000002', 'Banjarmasin'),
    ('Rizky Adhitiya Maulana', '081200000003', 'Banjarmasin'),
    ('Hamka Arifani', '081200000004', 'Banjarmasin'),
    ('Noor Muhammad Akmal Sulaiman', '081200000005', 'Banjarmasin'),
    ('Muhammad Irgi Fahreza', '081200000006', 'Banjarmasin'),
    ('Muhammad Naufal Abdillah', '081200000007', 'Banjarbaru'),
    ('Arya Arrozza Ridho Syaputra', '081200000008', 'Banjarmasin'),
    ('Muhammad Guntur Ricky Adhitya', '081200000009', 'Banjarmasin'),
    ('Muhammad Naufal Khalish', '081200000010', 'Banjarmasin'),
    ('Achmad Reihan Alfaiz', '081200000011', 'Banjarmasin');

INSERT INTO drivers (
    driver_name,
    phone
)
VALUES
    ('Faisal Tanjung', '081300000001'),
    ('Afrian Pradipta Rizky', '081300000002'),
    ('Muhammad Rizki Dinar', '081300000003'),
    ('Hafiz Perdana', '081300000004'),
    ('Muhammad Kusuma', '081300000005');

INSERT INTO vehicles (
    plate_number,
    vehicle_type
)
VALUES
    ('DA 8101 AB', 'Delivery Van'),
    ('DA 8102 AC', 'Delivery Van'),
    ('DA 8201 AD', 'Box Truck'),
    ('DA 8202 AE', 'Box Truck'),
    ('DA 8301 AF', 'Delivery Van');

INSERT INTO locations (
    location_name,
    city
)
VALUES
    ('Banjarmasin Hub', 'Banjarmasin'),
    ('Banjarbaru Hub', 'Banjarbaru'),
    ('Martapura Hub', 'Martapura'),
    ('Pelaihari Hub', 'Pelaihari'),
    ('Barabai Hub', 'Barabai'),
    ('Kandangan Hub', 'Kandangan'),
    ('Amuntai Hub', 'Amuntai'),
    ('Tanjung Hub', 'Tanjung');

INSERT INTO services (
    service_name,
    base_price
)
VALUES
    ('Standard', 50000),
    ('Express', 100000),
    ('Next Day', 150000);

INSERT INTO shipments (
    tracking_number,
    customer_id,
    service_id,
    origin_location_id,
    destination_location_id,
    shipment_date,
    weight_kg,
    shipping_cost,
    status
)
SELECT
    'UPS' || LPAD(g::TEXT, 6, '0'),
    (FLOOR(RANDOM() * 11) + 1)::INT,
    (FLOOR(RANDOM() * 3) + 1)::INT,
    (FLOOR(RANDOM() * 8) + 1)::INT,
    (FLOOR(RANDOM() * 8) + 1)::INT,
    DATE '2026-01-01'
        + (FLOOR(RANDOM() * 180))::INT,
    ROUND(
        (1 + RANDOM() * 19)::NUMERIC,
        2
    ),
    50000
        + (FLOOR(RANDOM() * 10)::INT * 10000),
    CASE
        WHEN g <= 700 THEN 'DELIVERED'
        WHEN g <= 900 THEN 'IN_TRANSIT'
        ELSE 'CANCELLED'
    END
FROM generate_series(1, 1000) AS g;

INSERT INTO pickups (
    shipment_id,
    driver_id,
    vehicle_id,
    pickup_time,
    pickup_status
)
SELECT
    shipment_id,
    (FLOOR(RANDOM() * 5) + 1)::INT,
    (FLOOR(RANDOM() * 5) + 1)::INT,
    shipment_date + TIME '08:00',
    'COMPLETED'
FROM shipments;

INSERT INTO tracking_events (
    shipment_id,
    location_id,
    event_time,
    tracking_status
)
SELECT
    shipment_id,
    origin_location_id,
    shipment_date + TIME '08:00',
    'PICKED_UP'
FROM shipments;

INSERT INTO tracking_events (
    shipment_id,
    location_id,
    event_time,
    tracking_status
)
SELECT
    shipment_id,
    (FLOOR(RANDOM() * 8) + 1)::INT,
    shipment_date + INTERVAL '1 day',
    'IN_TRANSIT'
FROM shipments;

INSERT INTO tracking_events (
    shipment_id,
    location_id,
    event_time,
    tracking_status
)
SELECT
    shipment_id,
    destination_location_id,
    shipment_date + INTERVAL '2 days',
    status
FROM shipments;

INSERT INTO deliveries (
    shipment_id,
    driver_id,
    vehicle_id,
    delivery_time,
    receiver_name,
    delivery_status
)
SELECT
    shipment_id,
    (FLOOR(RANDOM() * 5) + 1)::INT,
    (FLOOR(RANDOM() * 5) + 1)::INT,
    shipment_date + INTERVAL '2 days',
    'Penerima ' || shipment_id,
    'DELIVERED'
FROM shipments
WHERE status = 'DELIVERED';

INSERT INTO vehicle_logs (
    vehicle_id,
    driver_id,
    log_time,
    speed_kmh,
    latitude,
    longitude
)
SELECT
    (FLOOR(RANDOM() * 5) + 1)::INT,
    (FLOOR(RANDOM() * 5) + 1)::INT,
    TIMESTAMP '2026-01-01 08:00:00'
        + (g * INTERVAL '10 minutes'),
    (30 + RANDOM() * 40)::INT,
    ROUND(
        (-3.35 + RANDOM() * 0.10)::NUMERIC,
        6
    ),
    ROUND(
        (114.55 + RANDOM() * 0.10)::NUMERIC,
        6
    )
FROM generate_series(1, 500) AS g;