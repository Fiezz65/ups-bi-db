# UPS Logistics Data Warehouse

Repository ini merupakan project tugas mata kuliah **Kecerdasan Bisnis** dengan studi kasus UPS Logistics.

Project menggunakan database OLTP sebagai sumber data, kemudian data diproses melalui ETL berbasis Python dan dimuat ke Data Warehouse dengan pendekatan dimensional modeling.

## Anggota Kelompok

- Faisal Tanjung  (2410817310012)
- Hafiz Perdana   (2410817210027)

## Arsitektur

Arsitektur yang digunakan terdiri dari tiga bagian utama:

```text
PostgreSQL Lokal
ups_logistics
(OLTP)
      |
      | Extract
      v
Python ETL
(Docker)
      |
      | Transform & Load
      v
PostgreSQL Lokal
ups_logistics_dw
(Data Warehouse)
```

Database OLTP dan Data Warehouse berjalan pada PostgreSQL lokal, sedangkan proses ETL dan cron scheduler dijalankan melalui Docker.

## OLTP Database

Database `ups_logistics` digunakan sebagai sumber data operasional.

Tabel yang digunakan:

### Master

- `customers`
- `locations`
- `services`

### Transaksi

- `shipments`
- `pickups`
- `tracking_events`
- `payments`
- `deliveries`

`shipments` menjadi tabel transaksi utama yang menghubungkan customer, service, lokasi asal, dan lokasi tujuan. Proses pengiriman selanjutnya dicatat melalui pickup, tracking event, payment, dan delivery.

### Jumlah Data

| Tabel | Jumlah |
|---|---:|
| customers | 11 |
| locations | 8 |
| services | 3 |
| shipments | 1000 |
| pickups | 1000 |
| tracking_events | 3000 |
| payments | 1000 |
| deliveries | 700 |

## ERD OLTP

![ERD OLTP UPS Logistics](OLTP/ERD_OLTP.png)

## Data Warehouse

Data Warehouse menggunakan pendekatan dimensional modeling dengan **2 fact table dan 8 dimension table**.

### Fact Table

- `fact_shipment`
- `fact_payment`

### Dimension Table

- `dim_date`
- `dim_customer`
- `dim_service`
- `dim_location`
- `dim_shipment_status`
- `dim_pickup_status`
- `dim_delivery_status`
- `dim_payment`

## Business Process dan Grain

### Fact Shipment

Business process yang dianalisis adalah proses pengiriman paket.

**Grain:** satu row pada `fact_shipment` merepresentasikan satu transaksi shipment.

Measure yang digunakan:

- `weight_kg`
- `shipping_cost`
- `delivery_duration_hours`
- `tracking_event_count`

### Fact Payment

Business process yang dianalisis adalah transaksi pembayaran pada shipment.

**Grain:** satu row pada `fact_payment` merepresentasikan satu transaksi pembayaran.

Measure yang digunakan:

- `amount`

## Shipment Star Schema

`fact_shipment` digunakan untuk menganalisis proses pengiriman berdasarkan customer, service, tanggal, lokasi, dan status pengiriman.

![Shipment Star Schema](DW/Shipment_Star_Schema.png)

## Payment Star Schema

`fact_payment` digunakan untuk menganalisis transaksi pembayaran berdasarkan customer, service, tanggal, lokasi, metode pembayaran, dan status pembayaran.

![Payment Star Schema](DW/Payment_Star_Schema.png)

## ETL

Proses ETL dibuat menggunakan Python dan dijalankan sebagai service di dalam Docker.

Alur ETL:

```text
OLTP
  |
  v
Extract
  |
  v
Transform
  |
  v
Load Dimension
  |
  v
Load Fact
  |
  v
Data Warehouse
```

### Extract

ETL membaca data dari tabel OLTP dan mencatat beberapa metric:

- jumlah row
- duration
- throughput

Pengujian extract dilakukan minimal tiga kali untuk melihat konsistensi proses.

### Transform

Transform test yang digunakan terdiri dari:

1. Validasi tipe data tanggal
2. Null handling delivery
3. Deduplication customer
4. Normalisasi status

Setiap rule menampilkan nilai `Before`, `Expected`, `Actual`, dan `Status`.

### Load

Dimension dimuat terlebih dahulu sebelum fact.

Fact menggunakan surrogate key dari dimension yang sesuai. Proses load juga dibuat agar dapat dijalankan ulang tanpa menambahkan transaksi fact yang sama.

## Cara Menjalankan

### 1. Clone Repository

```bash
git clone https://github.com/Fiezz65/ups-bi-db.git
cd ups-bi-db
```

### 2. Buat Database OLTP

Buat database PostgreSQL lokal:

```text
ups_logistics
```

Kemudian jalankan secara berurutan:

```text
OLTP/init.sql
OLTP/seed.sql
```

`init.sql` digunakan untuk membuat tabel dan relasi OLTP, sedangkan `seed.sql` digunakan untuk mengisi data dummy.

### 3. Buat Database Data Warehouse

Buat database PostgreSQL lokal:

```text
ups_logistics_dw
```

Kemudian jalankan:

```text
DW/dw_init.sql
```

File tersebut membuat schema `dw`, dimension table, fact table, primary key, dan foreign key yang digunakan pada Data Warehouse.

### 4. Konfigurasi Environment

Salin file:

```text
.env.example
```

menjadi:

```text
.env
```

Kemudian sesuaikan konfigurasi koneksi PostgreSQL lokal.

File `.env` digunakan untuk menyimpan konfigurasi koneksi source OLTP dan target Data Warehouse dan tidak disimpan ke repository.

### 5. Build Service ETL

Pastikan Docker Desktop sudah berjalan.

```bash
docker compose build --no-cache etl
```

### 6. Menjalankan ETL Secara Manual

```bash
docker compose run --rm etl python /app/etl.py
```

Jika berhasil, output akan menunjukkan proses:

```text
Source OLTP : connected
Target DW   : connected

=== EXTRACT ===

=== TRANSFORM TEST ===

=== LOAD DIMENSION ===
Dimension berhasil dimuat

=== LOAD FACT ===
Fact berhasil dimuat

Status : SUCCESS
```

### 7. Menjalankan Cron Scheduler

Jalankan service ETL:

```bash
docker compose up -d etl
```

Cron dikonfigurasi untuk menjalankan ETL secara otomatis setiap satu menit.

Untuk melihat jadwal cron:

```bash
docker exec -it ups_etl cat /etc/cron.d/ups-etl
```

Konfigurasi:

```text
* * * * * root /bin/sh /app/run_etl.sh >> /app/logs/cron.log 2>&1
```

Untuk melihat log ETL otomatis:

```bash
docker exec -it ups_etl tail -n 120 /app/logs/cron.log
```

## Validasi Data Warehouse

Pengujian Data Warehouse tersedia pada:

```text
DW/acceptance_test.sql
```

Pengujian mencakup:

- duplicate fact
- orphan foreign key
- join fact dengan dimension
- penggunaan date dimension

Hasil yang diharapkan:

```text
Duplicate Fact = 0
Orphan Foreign Key = 0
```

Proses ETL juga diuji dengan rerun menggunakan source yang sama. Jumlah data fact harus tetap sama dan tidak menghasilkan duplicate load.

Jumlah data utama setelah ETL:

```text
fact_shipment = 1000
fact_payment  = 1000
```

## Report Data Warehouse

Query report tersedia pada:

```text
DW/report_queries.sql
```

Report yang digunakan:

1. Jumlah shipment dan total biaya pengiriman per bulan
2. Jumlah shipment dan total biaya pengiriman per customer
3. Ringkasan pembayaran berdasarkan metode dan status pembayaran

## Catatan

Seluruh data yang digunakan merupakan data dummy untuk kebutuhan tugas dan bukan data operasional asli UPS.