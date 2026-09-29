# UPS Logistics Database

Repository ini berisi database dummy bertema operasional UPS untuk tugas mata kuliah Kecerdasan Bisnis.

Database menggunakan PostgreSQL yang dijalankan melalui Docker.

## Anggota Kelompok

- Faisal Tanjung (2410817310012)
- Hafiz Perdana (2410817210027)

## Database Design

![UPS Logistics ERD](ERD_OLTP_UPS_Logistics.png)

### Tabel Master

- `customers`
- `locations`
- `services`

### Tabel Transaksi

- `shipments`
- `pickups`
- `tracking_events`
- `payments`
- `deliveries`

Tabel `shipments` menjadi transaksi utama yang menyimpan data pengiriman. Proses selanjutnya dicatat melalui `pickups`, `tracking_events`, `payments`, dan `deliveries`.

## Cara Menjalankan

1. Clone repository:

```bash
git clone https://github.com/Fiezz65/ups-bi-db.git
```

2. Masuk ke folder project:

```bash
cd ups-bi-db
```

3. Jalankan PostgreSQL melalui Docker:

```bash
docker compose up -d
```

4. Hubungkan pgAdmin dengan konfigurasi:

```text
Host     : localhost
Port     : 5433
Username : postgres
Password : postgres
```

5. Buat database:

```text
ups_logistics
```

6. Jalankan file berikut secara berurutan:

```text
init.sql
seed.sql
```

`init.sql` digunakan untuk membuat tabel dan relasi, sedangkan `seed.sql` digunakan untuk mengisi data dummy.

## Jumlah Data Transaksi

```text
shipments           1000
pickups             1000
tracking_events     3000
payments            1000
deliveries           700
```

Untuk mengecek jumlah data:

```sql
SELECT 'shipments' AS table_name, COUNT(*) AS total
FROM shipments

UNION ALL

SELECT 'pickups', COUNT(*)
FROM pickups

UNION ALL

SELECT 'tracking_events', COUNT(*)
FROM tracking_events

UNION ALL

SELECT 'payments', COUNT(*)
FROM payments

UNION ALL

SELECT 'deliveries', COUNT(*)
FROM deliveries;
```

Seluruh data yang digunakan merupakan data dummy untuk kebutuhan tugas dan bukan data operasional asli UPS.
