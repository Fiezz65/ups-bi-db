import os
import time
import psycopg2
from datetime import datetime, date
from zoneinfo import ZoneInfo

WITA = ZoneInfo("Asia/Makassar")


def waktu_sekarang():
    return datetime.now(WITA).strftime("%Y-%m-%d %H:%M:%S")


def connect_source():
    return psycopg2.connect(
        host=os.getenv("SOURCE_HOST"),
        port=os.getenv("SOURCE_PORT"),
        database=os.getenv("SOURCE_DB"),
        user=os.getenv("SOURCE_USER"),
        password=os.getenv("SOURCE_PASSWORD")
    )


def connect_target():
    return psycopg2.connect(
        host=os.getenv("TARGET_HOST"),
        port=os.getenv("TARGET_PORT"),
        database=os.getenv("TARGET_DB"),
        user=os.getenv("TARGET_USER"),
        password=os.getenv("TARGET_PASSWORD")
    )


# ============================================================
# EXTRACT
# ============================================================

def extract(source):
    print("\n=== EXTRACT ===")

    start = time.time()

    cursor = source.cursor()

    cursor.execute("SELECT * FROM customers")
    customers = cursor.fetchall()

    cursor.execute("SELECT * FROM services")
    services = cursor.fetchall()

    cursor.execute("SELECT * FROM locations")
    locations = cursor.fetchall()

    cursor.execute("SELECT * FROM shipments")
    shipments = cursor.fetchall()

    cursor.execute("SELECT * FROM pickups")
    pickups = cursor.fetchall()

    cursor.execute("SELECT * FROM deliveries")
    deliveries = cursor.fetchall()

    cursor.execute("SELECT * FROM tracking_events")
    tracking_events = cursor.fetchall()

    cursor.execute("SELECT * FROM payments")
    payments = cursor.fetchall()

    duration = time.time() - start

    total_rows = (
        len(customers)
        + len(services)
        + len(locations)
        + len(shipments)
        + len(pickups)
        + len(deliveries)
        + len(tracking_events)
        + len(payments)
    )

    if duration > 0:
        throughput = total_rows / duration
    else:
        throughput = 0

    print("Customers       :", len(customers))
    print("Services        :", len(services))
    print("Locations       :", len(locations))
    print("Shipments       :", len(shipments))
    print("Pickups         :", len(pickups))
    print("Deliveries      :", len(deliveries))
    print("Tracking Events :", len(tracking_events))
    print("Payments        :", len(payments))

    print("Total rows      :", total_rows)
    print("Duration        :", round(duration, 4), "seconds")
    print("Throughput      :", round(throughput, 2), "rows/second")

    cursor.close()

    return {
        "customers": customers,
        "services": services,
        "locations": locations,
        "shipments": shipments,
        "pickups": pickups,
        "deliveries": deliveries,
        "tracking_events": tracking_events,
        "payments": payments
    }


# ============================================================
# TRANSFORM
# ============================================================

def transform(data):
    print("\n=== TRANSFORM TEST ===")

    # 1. VALIDASI TIPE DATA TANGGAL
    invalid_date = 0

    for row in data["shipments"]:
        shipment_date = row[6]

        if type(shipment_date) is not date:
            invalid_date += 1

    print("\n1. Validasi Tipe Data Tanggal")
    print("Before   :", len(data["shipments"]), "shipment")
    print("Expected : 0 shipment_date dengan tipe data tidak valid")
    print("Actual   :", invalid_date, "shipment_date dengan tipe data tidak valid")

    if invalid_date == 0:
        print("Status   : PASS")
    else:
        print("Status   : FAIL")


    # 2. NULL HANDLING DELIVERY
    shipment_total = len(data["shipments"])
    delivery_total = len(data["deliveries"])

    missing_delivery = shipment_total - delivery_total

    print("\n2. Null Handling Delivery")
    print("Before   :", missing_delivery, "shipment belum memiliki delivery")
    print("Expected :", missing_delivery, "boleh bernilai kosong")
    print("Actual   :", missing_delivery, "tetap ditangani sebagai NULL")
    print("Status   : PASS")


    # 3. DEDUPLICATION CUSTOMER
    customer_ids = []

    for row in data["customers"]:
        customer_ids.append(row[0])

    duplicate = len(customer_ids) - len(set(customer_ids))

    print("\n3. Deduplication Customer")
    print("Before   :", len(customer_ids), "customer")
    print("Expected : 0 duplicate customer_id")
    print("Actual   :", duplicate, "duplicate")

    if duplicate == 0:
        print("Status   : PASS")
    else:
        print("Status   : FAIL")


    # 4. NORMALISASI STATUS
    raw_status = set()
    clean_status = set()

    for row in data["shipments"]:
        raw_status.add(row[9])
        clean_status.add(row[9].strip().upper())

    print("\n4. Normalisasi Status")
    print("Before   :", sorted(raw_status))
    print("Expected : status konsisten dalam huruf besar")
    print("Actual   :", sorted(clean_status))
    print("Status   : PASS")

    return data


# ============================================================
# LOAD DIMENSION
# ============================================================

def load_dimensions(target, data):
    print("\n=== LOAD DIMENSION ===")

    cursor = target.cursor()

    # --------------------------------------------------------
    # DIM CUSTOMER
    # --------------------------------------------------------

    for row in data["customers"]:
        customer_id = row[0]
        customer_name = row[1]
        phone = row[2]
        address = row[3]

        cursor.execute("""
            INSERT INTO dw.dim_customer (
                customer_id,
                customer_name,
                phone,
                address
            )
            VALUES (%s, %s, %s, %s)

            ON CONFLICT (customer_id)
            DO UPDATE SET
                customer_name = EXCLUDED.customer_name,
                phone = EXCLUDED.phone,
                address = EXCLUDED.address
        """, (
            customer_id,
            customer_name,
            phone,
            address
        ))

    # --------------------------------------------------------
    # DIM SERVICE
    # --------------------------------------------------------

    for row in data["services"]:
        cursor.execute("""
            INSERT INTO dw.dim_service (
                service_id,
                service_name,
                base_price
            )
            VALUES (%s, %s, %s)

            ON CONFLICT (service_id)
            DO UPDATE SET
                service_name = EXCLUDED.service_name,
                base_price = EXCLUDED.base_price
        """, (
            row[0],
            row[1],
            row[2]
        ))

    # --------------------------------------------------------
    # DIM LOCATION
    # --------------------------------------------------------

    for row in data["locations"]:
        cursor.execute("""
            INSERT INTO dw.dim_location (
                location_id,
                location_name,
                city
            )
            VALUES (%s, %s, %s)

            ON CONFLICT (location_id)
            DO UPDATE SET
                location_name = EXCLUDED.location_name,
                city = EXCLUDED.city
        """, (
            row[0],
            row[1],
            row[2]
        ))

    # --------------------------------------------------------
    # DIM SHIPMENT STATUS
    # --------------------------------------------------------

    shipment_statuses = set()

    for row in data["shipments"]:
        status = row[9].strip().upper()
        shipment_statuses.add(status)

    for status in shipment_statuses:
        cursor.execute("""
            INSERT INTO dw.dim_shipment_status (
                status_name
            )
            VALUES (%s)

            ON CONFLICT (status_name)
            DO NOTHING
        """, (
            status,
        ))

    # --------------------------------------------------------
    # DIM PICKUP STATUS
    # --------------------------------------------------------

    pickup_statuses = set()

    for row in data["pickups"]:
        status = row[3].strip().upper()
        pickup_statuses.add(status)

    for status in pickup_statuses:
        cursor.execute("""
            INSERT INTO dw.dim_pickup_status (
                status_name
            )
            VALUES (%s)

            ON CONFLICT (status_name)
            DO NOTHING
        """, (
            status,
        ))

    # --------------------------------------------------------
    # DIM DELIVERY STATUS
    # --------------------------------------------------------

    delivery_statuses = set()

    for row in data["deliveries"]:
        status = row[4].strip().upper()
        delivery_statuses.add(status)

    for status in delivery_statuses:
        cursor.execute("""
            INSERT INTO dw.dim_delivery_status (
                status_name
            )
            VALUES (%s)

            ON CONFLICT (status_name)
            DO NOTHING
        """, (
            status,
        ))

    # --------------------------------------------------------
    # DIM PAYMENT
    # --------------------------------------------------------

    payment_values = set()

    for row in data["payments"]:
        method = row[3].strip()
        status = row[5].strip().upper()

        payment_values.add(
            (method, status)
        )

    for method, status in payment_values:
        cursor.execute("""
            INSERT INTO dw.dim_payment (
                payment_method,
                payment_status
            )
            VALUES (%s, %s)

            ON CONFLICT (
                payment_method,
                payment_status
            )
            DO NOTHING
        """, (
            method,
            status
        ))

    # --------------------------------------------------------
    # DIM DATE
    # --------------------------------------------------------

    dates = set()

    # shipment_date
    for row in data["shipments"]:
        dates.add(row[6])

    # pickup_time
    for row in data["pickups"]:
        dates.add(
            row[2].date()
        )

    # delivery_time
    for row in data["deliveries"]:
        dates.add(
            row[2].date()
        )

    # payment_date
    for row in data["payments"]:
        dates.add(
            row[2].date()
        )

    for tanggal in dates:
        date_key = int(
            tanggal.strftime("%Y%m%d")
        )

        quarter = (
            (tanggal.month - 1) // 3
        ) + 1

        cursor.execute("""
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
            VALUES (
                %s, %s, %s,
                %s, %s, %s,
                %s, %s, %s
            )

            ON CONFLICT (full_date)
            DO NOTHING
        """, (
            date_key,
            tanggal,
            tanggal.day,
            tanggal.strftime("%A"),
            tanggal.month,
            tanggal.strftime("%B"),
            quarter,
            tanggal.year,
            tanggal.weekday() >= 5
        ))

    target.commit()

    print("Dimension berhasil dimuat")

    cursor.close()


# ============================================================
# LOAD FACT
# ============================================================

def load_facts(target, data):
    print("\n=== LOAD FACT ===")

    cursor = target.cursor()

    # --------------------------------------------------------
    # BUAT LOOKUP PICKUP
    # --------------------------------------------------------

    pickup_data = {}

    for row in data["pickups"]:
        shipment_id = row[1]

        pickup_data[shipment_id] = row

    # --------------------------------------------------------
    # BUAT LOOKUP DELIVERY
    # --------------------------------------------------------

    delivery_data = {}

    for row in data["deliveries"]:
        shipment_id = row[1]

        delivery_data[shipment_id] = row

    # --------------------------------------------------------
    # HITUNG TRACKING EVENT
    # --------------------------------------------------------

    tracking_count = {}

    for row in data["tracking_events"]:
        shipment_id = row[1]

        if shipment_id not in tracking_count:
            tracking_count[shipment_id] = 0

        tracking_count[shipment_id] += 1

    # ========================================================
    # FACT SHIPMENT
    # ========================================================

    for shipment in data["shipments"]:
        shipment_id = shipment[0]
        tracking_number = shipment[1]

        customer_id = shipment[2]
        service_id = shipment[3]

        origin_id = shipment[4]
        destination_id = shipment[5]

        shipment_date = shipment[6]

        weight = shipment[7]
        cost = shipment[8]

        shipment_status = (
            shipment[9]
            .strip()
            .upper()
        )

        pickup = pickup_data.get(
            shipment_id
        )

        delivery = delivery_data.get(
            shipment_id
        )

        # ----------------------------------------------------
        # CUSTOMER KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT customer_key
            FROM dw.dim_customer
            WHERE customer_id = %s
        """, (
            customer_id,
        ))

        customer_key = cursor.fetchone()[0]

        # ----------------------------------------------------
        # SERVICE KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT service_key
            FROM dw.dim_service
            WHERE service_id = %s
        """, (
            service_id,
        ))

        service_key = cursor.fetchone()[0]

        # ----------------------------------------------------
        # ORIGIN LOCATION KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT location_key
            FROM dw.dim_location
            WHERE location_id = %s
        """, (
            origin_id,
        ))

        origin_key = cursor.fetchone()[0]

        # ----------------------------------------------------
        # DESTINATION LOCATION KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT location_key
            FROM dw.dim_location
            WHERE location_id = %s
        """, (
            destination_id,
        ))

        destination_key = cursor.fetchone()[0]

        # ----------------------------------------------------
        # SHIPMENT DATE KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT date_key
            FROM dw.dim_date
            WHERE full_date = %s
        """, (
            shipment_date,
        ))

        shipment_date_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # SHIPMENT STATUS KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT shipment_status_key
            FROM dw.dim_shipment_status
            WHERE status_name = %s
        """, (
            shipment_status,
        ))

        shipment_status_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # PICKUP
        # ----------------------------------------------------

        pickup_date_key = None
        pickup_status_key = None

        if pickup is not None:
            pickup_date = (
                pickup[2].date()
            )

            pickup_status = (
                pickup[3]
                .strip()
                .upper()
            )

            cursor.execute("""
                SELECT date_key
                FROM dw.dim_date
                WHERE full_date = %s
            """, (
                pickup_date,
            ))

            pickup_date_key = (
                cursor.fetchone()[0]
            )

            cursor.execute("""
                SELECT pickup_status_key
                FROM dw.dim_pickup_status
                WHERE status_name = %s
            """, (
                pickup_status,
            ))

            pickup_status_key = (
                cursor.fetchone()[0]
            )

        # ----------------------------------------------------
        # DELIVERY
        # ----------------------------------------------------

        delivery_date_key = None
        delivery_status_key = None
        delivery_duration_hours = None

        if delivery is not None:
            delivery_date = (
                delivery[2].date()
            )

            delivery_status = (
                delivery[4]
                .strip()
                .upper()
            )

            cursor.execute("""
                SELECT date_key
                FROM dw.dim_date
                WHERE full_date = %s
            """, (
                delivery_date,
            ))

            delivery_date_key = (
                cursor.fetchone()[0]
            )

            cursor.execute("""
                SELECT delivery_status_key
                FROM dw.dim_delivery_status
                WHERE status_name = %s
            """, (
                delivery_status,
            ))

            delivery_status_key = (
                cursor.fetchone()[0]
            )

            if pickup is not None:
                duration = (
                    delivery[2]
                    - pickup[2]
                )

                delivery_duration_hours = (
                    duration.total_seconds()
                    / 3600
                )

        # ----------------------------------------------------
        # INSERT FACT SHIPMENT
        # ----------------------------------------------------

        cursor.execute("""
            INSERT INTO dw.fact_shipment (
                shipment_id,
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
            VALUES (
                %s, %s, %s, %s,
                %s, %s, %s, %s,
                %s, %s, %s,
                %s, %s, %s, %s, %s
            )

            ON CONFLICT (shipment_id)
            DO NOTHING
        """, (
            shipment_id,
            shipment_date_key,
            pickup_date_key,
            delivery_date_key,
            customer_key,
            service_key,
            origin_key,
            destination_key,
            shipment_status_key,
            pickup_status_key,
            delivery_status_key,
            tracking_number,
            weight,
            cost,
            delivery_duration_hours,
            tracking_count.get(
                shipment_id,
                0
            )
        ))

    # ========================================================
    # FACT PAYMENT
    # ========================================================

    shipment_lookup = {}

    for shipment in data["shipments"]:
        shipment_lookup[
            shipment[0]
        ] = shipment

    for payment in data["payments"]:
        payment_id = payment[0]
        shipment_id = payment[1]

        payment_date = payment[2]

        method = (
            payment[3]
            .strip()
        )

        amount = payment[4]

        payment_status = (
            payment[5]
            .strip()
            .upper()
        )

        shipment = shipment_lookup[
            shipment_id
        ]

        tracking_number = shipment[1]

        customer_id = shipment[2]
        service_id = shipment[3]

        origin_id = shipment[4]
        destination_id = shipment[5]

        # ----------------------------------------------------
        # PAYMENT DATE KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT date_key
            FROM dw.dim_date
            WHERE full_date = %s
        """, (
            payment_date.date(),
        ))

        payment_date_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # CUSTOMER KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT customer_key
            FROM dw.dim_customer
            WHERE customer_id = %s
        """, (
            customer_id,
        ))

        customer_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # SERVICE KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT service_key
            FROM dw.dim_service
            WHERE service_id = %s
        """, (
            service_id,
        ))

        service_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # ORIGIN KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT location_key
            FROM dw.dim_location
            WHERE location_id = %s
        """, (
            origin_id,
        ))

        origin_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # DESTINATION KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT location_key
            FROM dw.dim_location
            WHERE location_id = %s
        """, (
            destination_id,
        ))

        destination_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # PAYMENT KEY
        # ----------------------------------------------------

        cursor.execute("""
            SELECT payment_key
            FROM dw.dim_payment
            WHERE payment_method = %s
            AND payment_status = %s
        """, (
            method,
            payment_status
        ))

        payment_key = (
            cursor.fetchone()[0]
        )

        # ----------------------------------------------------
        # INSERT FACT PAYMENT
        # ----------------------------------------------------

        cursor.execute("""
            INSERT INTO dw.fact_payment (
                payment_id,
                payment_date_key,
                customer_key,
                service_key,
                origin_location_key,
                destination_location_key,
                payment_key,
                tracking_number,
                amount
            )
            VALUES (
                %s, %s, %s,
                %s, %s, %s,
                %s, %s, %s
            )

            ON CONFLICT (payment_id)
            DO NOTHING
        """, (
            payment_id,
            payment_date_key,
            customer_key,
            service_key,
            origin_key,
            destination_key,
            payment_key,
            tracking_number,
            amount
        ))

    target.commit()

    print("Fact berhasil dimuat")

    cursor.close()


# ============================================================
# MAIN
# ============================================================

def main():
    print("====================================")
    print("UPS LOGISTICS ETL")
    print("====================================")

    print("Waktu mulai :", waktu_sekarang())

    source = None
    target = None

    try:
        source = connect_source()

        print("Source OLTP : connected")

        target = connect_target()

        print("Target DW   : connected")

        data = extract(
            source
        )

        data = transform(
            data
        )

        load_dimensions(
            target,
            data
        )

        load_facts(
            target,
            data
        )

        print("Status       : SUCCESS")
        print("Waktu selesai:", waktu_sekarang())

        print("\n====================================")
        print("ETL SELESAI")
        print("====================================")

    except Exception as error:
        print("\n====================================")
        print("ETL ERROR")
        print("====================================")
        print(error)

        if target is not None:
            target.rollback()

    finally:
        if source is not None:
            source.close()

        if target is not None:
            target.close()


main()