#!/usr/bin/env bash
set -euo pipefail

API_BASE="https://api.opensubtitles.com/api/v1"
API_KEY="${OPENSUBTITLES_API_KEY:-Er4Y8GbS7JoCcLf9oJmjc2noj2wIsrNu}"
QUERY="${OPENSUBTITLES_QUERY:-inception}"
LANGUAGE="${OPENSUBTITLES_LANGUAGE:-en}"

response_headers="$(mktemp)"
response_body="$(mktemp)"
response_error="$(mktemp)"

cleanup() {
  rm -f "$response_headers" "$response_body" "$response_error"
}
trap cleanup EXIT

set +e
status="$(curl -sS -D "$response_headers" -o "$response_body" \
  -H "Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  "${API_BASE}/subtitles?query=${QUERY}&languages=${LANGUAGE}" \
  -w "%{http_code}" 2>"$response_error")"
curl_exit=$?
set -e

if [[ $curl_exit -ne 0 ]]; then
  printf "curl failed (exit %s).\n" "$curl_exit"
  printf "\nDiagnostics (stderr):\n"
  cat "$response_error"
  exit 1
fi

printf "Status: %s\n" "$status"

if [[ "$status" != "200" && "$status" != "403" ]]; then
  printf "Unexpected status (expected 200 or 403).\n"
fi

printf "\nResponse headers:\n"
cat "$response_headers"

printf "\nResponse body (first 400 chars):\n"
head -c 400 "$response_body"
printf "\n"

if [[ "$status" != "200" && "$status" != "403" ]]; then
  exit 1
fi
