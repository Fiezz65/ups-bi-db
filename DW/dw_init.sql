CREATE SCHEMA dw;

CREATE TABLE dw.dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE dw.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id INT NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200)
);

CREATE TABLE dw.dim_service (
    service_key SERIAL PRIMARY KEY,
    service_id INT NOT NULL UNIQUE,
    service_name VARCHAR(100) NOT NULL,
    base_price NUMERIC(12,2) NOT NULL
);

CREATE TABLE dw.dim_location (
    location_key SERIAL PRIMARY KEY,
    location_id INT NOT NULL UNIQUE,
    location_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL
);

CREATE TABLE dw.dim_shipment_status (
    shipment_status_key SERIAL PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dw.dim_pickup_status (
    pickup_status_key SERIAL PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dw.dim_delivery_status (
    delivery_status_key SERIAL PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dw.dim_payment (
    payment_key SERIAL PRIMARY KEY,
    payment_method VARCHAR(30) NOT NULL,
    payment_status VARCHAR(30) NOT NULL,
    UNIQUE (payment_method, payment_status)
);

CREATE TABLE dw.fact_shipment (
    shipment_fact_key SERIAL PRIMARY KEY,
    shipment_id INT NOT NULL UNIQUE,
    shipment_date_key INT NOT NULL,
    pickup_date_key INT,
    delivery_date_key INT,
    customer_key INT NOT NULL,
    service_key INT NOT NULL,
    origin_location_key INT NOT NULL,
    destination_location_key INT NOT NULL,
    shipment_status_key INT NOT NULL,
    pickup_status_key INT,
    delivery_status_key INT,
    tracking_number VARCHAR(30) NOT NULL,
    weight_kg NUMERIC(8,2) NOT NULL,
    shipping_cost NUMERIC(12,2) NOT NULL,
    delivery_duration_hours NUMERIC,
    tracking_event_count INT NOT NULL,
    FOREIGN KEY (shipment_date_key) REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (pickup_date_key) REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (delivery_date_key) REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dw.dim_customer(customer_key),
    FOREIGN KEY (service_key) REFERENCES dw.dim_service(service_key),
    FOREIGN KEY (origin_location_key) REFERENCES dw.dim_location(location_key),
    FOREIGN KEY (destination_location_key) REFERENCES dw.dim_location(location_key),
    FOREIGN KEY (shipment_status_key) REFERENCES dw.dim_shipment_status(shipment_status_key),
    FOREIGN KEY (pickup_status_key) REFERENCES dw.dim_pickup_status(pickup_status_key),
    FOREIGN KEY (delivery_status_key) REFERENCES dw.dim_delivery_status(delivery_status_key)
);

CREATE TABLE dw.fact_payment (
    payment_fact_key SERIAL PRIMARY KEY,
    payment_id INT NOT NULL UNIQUE,
    payment_date_key INT NOT NULL,
    customer_key INT NOT NULL,
    service_key INT NOT NULL,
    origin_location_key INT NOT NULL,
    destination_location_key INT NOT NULL,
    payment_key INT NOT NULL,
    tracking_number VARCHAR(30) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    FOREIGN KEY (payment_date_key) REFERENCES dw.dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dw.dim_customer(customer_key),
    FOREIGN KEY (service_key) REFERENCES dw.dim_service(service_key),
    FOREIGN KEY (origin_location_key) REFERENCES dw.dim_location(location_key),
    FOREIGN KEY (destination_location_key) REFERENCES dw.dim_location(location_key),
    FOREIGN KEY (payment_key) REFERENCES dw.dim_payment(payment_key)
);