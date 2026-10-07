import pickle
from datetime import timedelta
from pathlib import Path

import pendulum
from airflow.sdk import dag, task

from etl_functions import (
    connect_source,
    connect_target,
    extract,
    transform,
    load_dimensions,
    load_facts,
)

STAGING_DIR = Path("/opt/airflow/staging")
EXTRACT_FILE = STAGING_DIR / "extract_data.pkl"
TRANSFORM_FILE = STAGING_DIR / "transform_data.pkl"


def simpan_staging(data, path):
    """Menyimpan data (dictionary berisi list baris) ke file staging."""
    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        pickle.dump(data, f)
    print(f"Data disimpan ke staging: {path}")


def baca_staging(path):
    """Membaca kembali data dari file staging."""
    with open(path, "rb") as f:
        data = pickle.load(f)
    print(f"Data dibaca dari staging: {path}")
    return data


@dag(
    dag_id="ups_logistics_etl",
    description="ETL OLTP ups_logistics -> Data Warehouse ups_logistics_dw",
    schedule="*/5 * * * *",
    start_date=pendulum.datetime(2026, 10, 1, tz="Asia/Makassar"),
    catchup=False,
    max_active_runs=1,
    default_args={
        "owner": "kelompok-ups",
        "retries": 1,
        "retry_delay": timedelta(minutes=1),
    },
    tags=["ups", "etl"],
)
def ups_logistics_etl():

    @task(task_id="check_connection")
    def task_check_connection():
        source = connect_source()
        print("Source OLTP : connected")
        source.close()

        target = connect_target()
        print("Target DW   : connected")
        target.close()

    @task(task_id="extract")
    def task_extract():
        source = connect_source()
        try:
            data = extract(source)
        finally:
            source.close()
        simpan_staging(data, EXTRACT_FILE)

    @task(task_id="transform")
    def task_transform():
        data = baca_staging(EXTRACT_FILE)
        data = transform(data)
        simpan_staging(data, TRANSFORM_FILE)

    @task(task_id="load_dimension")
    def task_load_dimension():
        data = baca_staging(TRANSFORM_FILE)
        target = connect_target()
        try:
            load_dimensions(target, data)
        except Exception:
            target.rollback()
            raise
        finally:
            target.close()

    @task(task_id="load_fact")
    def task_load_fact():
        data = baca_staging(TRANSFORM_FILE)
        target = connect_target()
        try:
            load_facts(target, data)
        except Exception:
            target.rollback()
            raise
        finally:
            target.close()

    @task(task_id="validate")
    def task_validate():
        target = connect_target()
        cursor = target.cursor()

        cursor.execute("SELECT COUNT(*) FROM dw.fact_shipment")
        total_shipment = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM dw.fact_payment")
        total_payment = cursor.fetchone()[0]

        cursor.execute("""
            SELECT COUNT(*) FROM (
                SELECT shipment_id FROM dw.fact_shipment
                GROUP BY shipment_id HAVING COUNT(*) > 1
            ) x
        """)
        duplicate_shipment = cursor.fetchone()[0]

        cursor.execute("""
            SELECT COUNT(*) FROM (
                SELECT payment_id FROM dw.fact_payment
                GROUP BY payment_id HAVING COUNT(*) > 1
            ) x
        """)
        duplicate_payment = cursor.fetchone()[0]

        cursor.close()
        target.close()

        print("=== VALIDASI DATA WAREHOUSE ===")
        print("fact_shipment          :", total_shipment)
        print("fact_payment           :", total_payment)
        print("duplicate fact_shipment:", duplicate_shipment)
        print("duplicate fact_payment :", duplicate_payment)

        if total_shipment == 0 or total_payment == 0:
            raise ValueError("Fact kosong, load gagal")
        if duplicate_shipment > 0 or duplicate_payment > 0:
            raise ValueError("Terdapat duplikasi pada fact")

        print("Status                 : SUCCESS")

    # Urutan task
    (
        task_check_connection()
        >> task_extract()
        >> task_transform()
        >> task_load_dimension()
        >> task_load_fact()
        >> task_validate()
    )


ups_logistics_etl()