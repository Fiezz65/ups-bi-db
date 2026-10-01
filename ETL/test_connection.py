import os
import psycopg2


def main():
    print("Mencoba koneksi ke OLTP...")

    conn = psycopg2.connect(
        host=os.getenv("SOURCE_HOST"),
        port=os.getenv("SOURCE_PORT"),
        database=os.getenv("SOURCE_DB"),
        user=os.getenv("SOURCE_USER"),
        password=os.getenv("SOURCE_PASSWORD")
    )

    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM shipments;")
    total = cursor.fetchone()[0]

    print("Berhasil terhubung ke OLTP")
    print("Total shipment:", total)

    cursor.close()
    conn.close()


main()