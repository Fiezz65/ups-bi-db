#!/bin/sh

cat > /app/runtime.env <<EOF
export SOURCE_HOST="${SOURCE_HOST}"
export SOURCE_PORT="${SOURCE_PORT}"
export SOURCE_DB="${SOURCE_DB}"
export SOURCE_USER="${SOURCE_USER}"
export SOURCE_PASSWORD="${SOURCE_PASSWORD}"

export TARGET_HOST="${TARGET_HOST}"
export TARGET_PORT="${TARGET_PORT}"
export TARGET_DB="${TARGET_DB}"
export TARGET_USER="${TARGET_USER}"
export TARGET_PASSWORD="${TARGET_PASSWORD}"
EOF

chmod 600 /app/runtime.env

echo "Cron scheduler aktif"
echo "ETL dijalankan setiap 1 menit"

cron -f