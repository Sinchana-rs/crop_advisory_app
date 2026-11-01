import os
import sys

import requests
from dotenv import load_dotenv

load_dotenv()

key = os.getenv("DATA_GOV_API_KEY")

if not key:
    print("DATA_GOV_API_KEY is NOT set in .env")
    sys.exit(1)

print("Key found, length:", len(key))

crop = sys.argv[1] if len(sys.argv) > 1 else "Tomato"
state = sys.argv[2] if len(sys.argv) > 2 else "Karnataka"

r = requests.get(
    "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070",
    params={
        "api-key": key,
        "format": "json",
        "limit": 200,
        "filters[commodity]": crop,
        "filters[state.keyword]": state,
    },
    timeout=90,
    headers={
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120 Safari/537.36",
        "Accept": "application/json",
    },
)

print("HTTP status:", r.status_code)

try:
    body = r.json()
except Exception:
    print("Not JSON:", r.text[:200])
    sys.exit(1)

records = body.get("records", [])

print("Records:", len(records))

for rec in records[:5]:
    print(
        rec.get("arrival_date"),
        rec.get("market"),
        rec.get("commodity"),
        "min/max/modal per quintal:",
        rec.get("min_price"),
        rec.get("max_price"),
        rec.get("modal_price"),
    )

if not records:
    print("Message:", str(body.get("message", ""))[:200])
