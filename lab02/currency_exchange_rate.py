"""Get a currency exchange rate from the lab02 service and save it as JSON."""
import argparse
import json
import logging
import sys
from datetime import date
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
API_URL = "http://localhost:8080/"
FIRST_DATE = date(2025, 1, 1)
LAST_DATE = date(2025, 9, 15)

logging.basicConfig(
    filename=ROOT / "error.log",
    level=logging.ERROR,
    format="%(asctime)s %(message)s",
)


def check_date(value):
    # The service returns the latest rate for unknown dates instead of an error.
    try:
        d = date.fromisoformat(value)
    except ValueError:
        raise RuntimeError("date must be in YYYY-MM-DD format")
    if not FIRST_DATE <= d <= LAST_DATE:
        raise RuntimeError(f"date must be between {FIRST_DATE} and {LAST_DATE}")


def get_rate(from_cur, to_cur, day, key):
    try:
        resp = requests.post(
            API_URL,
            params={"from": from_cur, "to": to_cur, "date": day},
            data={"key": key},
            timeout=10,
        )
        answer = resp.json()
    except (requests.RequestException, ValueError) as e:
        raise RuntimeError(f"Request failed: {e}")
    if answer["error"]:
        raise RuntimeError(f"API error: {answer['error']}")
    return answer["data"]


def save(data):
    DATA_DIR.mkdir(exist_ok=True)
    path = DATA_DIR / f"{data['from']}_{data['to']}_{data['date']}.json"
    path.write_text(json.dumps(data, indent=2))
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("from_cur", help="currency to convert from, e.g. USD")
    parser.add_argument("to_cur", help="currency to convert to, e.g. EUR")
    parser.add_argument("date", help="date in YYYY-MM-DD format")
    parser.add_argument("--key", default="EXAMPLE_API_KEY", help="API key")
    args = parser.parse_args()

    try:
        check_date(args.date)
        data = get_rate(args.from_cur.upper(), args.to_cur.upper(), args.date, args.key)
    except RuntimeError as e:
        msg = f"{args.from_cur} -> {args.to_cur} on {args.date}: {e}"
        print(f"Error: {msg}", file=sys.stderr)
        logging.error(msg)
        sys.exit(1)

    print(f"{data['from']} -> {data['to']} on {data['date']}: {data['rate']}")
    print(f"Saved to {save(data)}")


if __name__ == "__main__":
    main()
