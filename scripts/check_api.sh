#!/usr/bin/env bash
set -euo pipefail

API_BASE="https://api.opensubtitles.com/api/v1"
API_KEY="${OPENSUBTITLES_API_KEY:-Er4Y8GbS7JoCcLf9oJmjc2noj2wIsrNu}"
QUERY="${OPENSUBTITLES_QUERY:-inception}"
LANGUAGE="${OPENSUBTITLES_LANGUAGE:-en}"
USER_AGENT="${OPENSUBTITLES_USER_AGENT:-VLSubWebDemo/1.0}"
KEEP_DIAGNOSTICS="${OPENSUBTITLES_KEEP_DIAGNOSTICS:-1}"

timestamp="$(date +"%Y%m%d_%H%M%S")"
output_dir="$(mktemp -d "opensubtitles_diag_${timestamp}_XXXX")"
response_headers="${output_dir}/response.headers.txt"
response_body="${output_dir}/response.body"
response_error="${output_dir}/response.stderr.txt"

cleanup() {
  if [[ "${KEEP_DIAGNOSTICS}" == "1" ]]; then
    return
  fi
  rm -rf "$output_dir"
}
trap cleanup EXIT

echo "OpenSubtitles API diagnostics"
echo "Time:        $(date +"%Y-%m-%d %H:%M:%S %z")"
echo "Output dir:  ${output_dir}"
echo "API base:    ${API_BASE}"
echo "Query:       ${QUERY}"
echo "Language:    ${LANGUAGE}"
echo "User-Agent:  ${USER_AGENT}"
echo ""
if command -v curl >/dev/null 2>&1; then
  echo "curl:        $(curl --version | head -n 1)"
  echo ""
fi

set +e
status="$(curl -sS -D "$response_headers" -o "$response_body" \
  -H "Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -A "${USER_AGENT}" \
  -L \
  "${API_BASE}/subtitles?query=${QUERY}&languages=${LANGUAGE}" \
  -w "%{http_code}" 2>"$response_error")"
curl_exit=$?
set -e

if [[ $curl_exit -ne 0 ]]; then
  printf "curl failed (exit %s).\n" "$curl_exit"
  printf "\nDiagnostics (stderr):\n"
  cat "$response_error"
  printf "\nArtifacts saved in: %s\n" "$output_dir"
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

printf "\nArtifacts saved in: %s\n" "$output_dir"

if [[ "$status" != "200" && "$status" != "403" ]]; then
  exit 1
fi
