CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200)
);

CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    driver_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    plate_number VARCHAR(20) NOT NULL UNIQUE,
    vehicle_type VARCHAR(50) NOT NULL
);

CREATE TABLE locations (
    location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL
);

CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    base_price NUMERIC(12, 2) NOT NULL
);

CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,
    tracking_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    service_id INT NOT NULL,
    origin_location_id INT NOT NULL,
    destination_location_id INT NOT NULL,
    shipment_date DATE NOT NULL,
    weight_kg NUMERIC(8, 2) NOT NULL,
    shipping_cost NUMERIC(12, 2) NOT NULL,
    status VARCHAR(30) NOT NULL,

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    FOREIGN KEY (service_id)
        REFERENCES services(service_id),

    FOREIGN KEY (origin_location_id)
        REFERENCES locations(location_id),

    FOREIGN KEY (destination_location_id)
        REFERENCES locations(location_id)
);

CREATE TABLE pickups (
    pickup_id SERIAL PRIMARY KEY,
    shipment_id INT NOT NULL,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    pickup_time TIMESTAMP NOT NULL,
    pickup_status VARCHAR(30) NOT NULL,

    FOREIGN KEY (shipment_id)
        REFERENCES shipments(shipment_id),

    FOREIGN KEY (driver_id)
        REFERENCES drivers(driver_id),

    FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(vehicle_id)
);

CREATE TABLE tracking_events (
    tracking_id SERIAL PRIMARY KEY,
    shipment_id INT NOT NULL,
    location_id INT NOT NULL,
    event_time TIMESTAMP NOT NULL,
    tracking_status VARCHAR(50) NOT NULL,

    FOREIGN KEY (shipment_id)
        REFERENCES shipments(shipment_id),

    FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
);

CREATE TABLE deliveries (
    delivery_id SERIAL PRIMARY KEY,
    shipment_id INT NOT NULL,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    delivery_time TIMESTAMP NOT NULL,
    receiver_name VARCHAR(100),
    delivery_status VARCHAR(30) NOT NULL,

    FOREIGN KEY (shipment_id)
        REFERENCES shipments(shipment_id),

    FOREIGN KEY (driver_id)
        REFERENCES drivers(driver_id),

    FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(vehicle_id)
);

CREATE TABLE vehicle_logs (
    log_id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    log_time TIMESTAMP NOT NULL,
    speed_kmh INT,
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),

    FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(vehicle_id),

    FOREIGN KEY (driver_id)
        REFERENCES drivers(driver_id)
);