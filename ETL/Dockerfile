FROM python:3.12-slim

ENV TZ=Asia/Makassar

RUN apt-get update \
    && apt-get install -y --no-install-recommends cron tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Makassar /etc/localtime \
    && echo "Asia/Makassar" > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ETL/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY ETL/test_connection.py /app/test_connection.py
COPY ETL/etl.py /app/etl.py
COPY ETL/run_etl.sh /app/run_etl.sh
COPY ETL/entrypoint.sh /app/entrypoint.sh
COPY ETL/crontab /etc/cron.d/ups-etl

RUN sed -i 's/\r$//' /app/run_etl.sh \
    && sed -i 's/\r$//' /app/entrypoint.sh \
    && sed -i 's/\r$//' /etc/cron.d/ups-etl \
    && chmod +x /app/run_etl.sh \
    && chmod +x /app/entrypoint.sh \
    && chmod 0644 /etc/cron.d/ups-etl \
    && mkdir -p /app/logs

CMD ["sh", "/app/entrypoint.sh"]