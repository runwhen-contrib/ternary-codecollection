#!/usr/bin/env bash
set -euo pipefail
{ set +o xtrace 2>/dev/null || true; }

TOKEN_FILE="${TERNARY_API_TOKEN:?missing secret file path}"
BASE_URL="${TERNARY_BASE_API_URL:?missing}"
TENANT_ID=$(cat TERNARY_TENANT_ID)
OUT_FILE="reports.json"

HDR_FILE="temp-header"
printf 'header = "Authorization: Bearer %s"\n' "$( < "$TOKEN_FILE" )" > "$HDR_FILE"

curl --silent -H 'Content-Type: application/json' \
     -K "$HDR_FILE" \
     "${BASE_URL}/reports?tenantID=${TENANT_ID}" \
     -o "$OUT_FILE"

rm -f "$HDR_FILE"
cat "$OUT_FILE"
