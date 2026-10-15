FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends cron \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir requests

WORKDIR /app
COPY currency_exchange_rate.py cronjob entrypoint.sh ./
RUN crontab cronjob && chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
