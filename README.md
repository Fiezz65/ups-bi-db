# UPS Logistics Database

Repository ini berisi database dummy bertema operasional United Parcel Service (UPS) untuk tugas mata kuliah Kecerdasan Bisnis.

Database menggunakan PostgreSQL yang dijalankan melalui Docker dan berisi data simulasi mengenai shipment, pickup, tracking, delivery, serta aktivitas kendaraan.

## Database Design

![UPS Shipments ERD](UPS_Shipments_ERD.png)

Tabel master yang digunakan adalah:

- `customers`
- `drivers`
- `vehicles`
- `locations`
- `services`

Sedangkan tabel transaksi yang digunakan adalah:

- `shipments`
- `pickups`
- `tracking_events`
- `deliveries`
- `vehicle_logs`

Tabel `shipments` menjadi tabel transaksi utama yang menyimpan informasi pengiriman paket. Tabel tersebut terhubung dengan `customers`, `services`, dan `locations`.

Proses pengiriman kemudian dicatat lebih lanjut melalui tabel `pickups`, `tracking_events`, dan `deliveries`. Sementara itu, tabel `vehicle_logs` digunakan untuk menyimpan pencatatan aktivitas kendaraan seperti waktu, kecepatan, latitude, dan longitude.

## Cara Menjalankan

1. Clone repository ini:

```bash
git clone https://github.com/Fiezz65/ups-bi-db.git
```

2. Masuk ke folder project:

```bash
cd ups-bi-db
```

3. Pastikan Docker Desktop sudah berjalan, kemudian jalankan PostgreSQL menggunakan Docker Compose:

```bash
docker compose up -d
```

Container PostgreSQL akan berjalan dengan nama:

```text
ups_postgres
```

4. Hubungkan PostgreSQL melalui pgAdmin menggunakan konfigurasi berikut:

```text
Host     : localhost
Port     : 5433
Username : postgres
Password : postgres
```

5. Buat database dengan nama:

```text
ups_logistics
```

6. Buka Query Tool pada database `ups_logistics`, kemudian jalankan file berikut secara berurutan:

```text
init.sql
seed.sql
```

`init.sql` digunakan untuk membuat struktur tabel dan relasinya, sedangkan `seed.sql` digunakan untuk mengisi data dummy.

7. Gunakan query berikut untuk memverifikasi jumlah data pada masing-masing tabel transaksi:

```sql
SELECT 'shipments' AS table_name, COUNT(*) AS row_count FROM shipments
UNION ALL
SELECT 'pickups', COUNT(*) FROM pickups
UNION ALL
SELECT 'tracking_events', COUNT(*) FROM tracking_events
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries
UNION ALL
SELECT 'vehicle_logs', COUNT(*) FROM vehicle_logs;
```

Hasil yang diharapkan:

```text
shipments          1000
pickups            1000
tracking_events    3000
deliveries          700
vehicle_logs        500
```

Seluruh data yang digunakan pada database ini merupakan data dummy untuk kebutuhan simulasi tugas dan bukan merupakan data operasional asli UPS.

## Anggota Kelompok

**1. Faisal Tanjung (2410817310012)**
**2. Hafiz Perdana (2410817210027)**
