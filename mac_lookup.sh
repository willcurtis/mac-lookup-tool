#!/bin/bash

# Config
CACHE_FILE="$HOME/.cache/mac_lookup_cache"
API_URL_BASE="https://api.macvendors.com"
RETRIES=3
RETRY_DELAY=2

mkdir -p "$(dirname "$CACHE_FILE")"
touch "$CACHE_FILE"

# URL-encode a string
rawurlencode() {
  local string="$1"
  local encoded=""
  local c

  for (( i = 0; i < ${#string}; i++ )); do
    c="${string:$i:1}"
    case "$c" in
      [-_.~a-zA-Z0-9]) encoded+="$c" ;;
      *) printf -v encoded '%s%%%02X' "$encoded" "'$c" ;;
    esac
  done
  echo "$encoded"
}

# Validate MAC address format
validate_mac() {
  local mac="$1"
  [[ "$mac" =~ ^([0-9A-Fa-f]{2}[:\-]){5}([0-9A-Fa-f]{2})$ ]]
}

# Lookup vendor via API or cache
lookup_mac_vendor() {
  local mac="$1"
  local json_output="$2"

  echo "DEBUG: Lookup MAC=[$mac]"

  local cached
  cached=$(grep -i "^$mac|" "$CACHE_FILE" | head -n1)
  if [[ -n "$cached" ]]; then
    echo "DEBUG: Found in cache: $cached"
    local vendor="${cached#*|}"
    output_result "$mac" "$vendor" "$json_output"
    return
  fi

  local encoded
  encoded=$(rawurlencode "$mac")
  echo "DEBUG: Encoded MAC=[$encoded]"

  local response http_code body

  response=$(curl -s -w "\n%{http_code}" "$API_URL_BASE/$encoded")
  echo "DEBUG: Raw response=[$response]"

  http_code=$(printf "%s" "$response" | tail -n1)
  body=$(printf "%s" "$response" | sed '$d')

  echo "DEBUG: Parsed HTTP code=[$http_code]"
  echo "DEBUG: Parsed body=[$body]"

  if [[ "$http_code" -ne 200 || -z "$body" ]]; then
    echo "MAC: $mac"
    echo "Vendor: Not Found (HTTP $http_code)"
  else
    echo "$mac|$body" >> "$CACHE_FILE"
    output_result "$mac" "$body" "$json_output"
  fi
}

# Output result nicely
output_result() {
  local mac="$1"
  local vendor="$2"
  local json="$3"

  if [[ "$json" == "true" ]]; then
    printf '{"mac":"%s","vendor":"%s"}\n' "$mac" "$vendor"
  else
    echo "MAC: $mac"
    echo "Vendor: $vendor"
    echo
  fi
}

# Main entry
main() {
  local input=""
  local json_output="false"

  for arg in "$@"; do
    if [[ "$arg" == "--json" ]]; then
      json_output="true"
    elif [[ -z "$input" ]]; then
      input="$arg"
    fi
  done

  if [[ -z "$input" ]]; then
    echo "Usage: $0 <MAC address or file> [--json]"
    exit 1
  fi

  if [[ -f "$input" ]]; then
    while IFS= read -r line; do
      mac=$(echo "$line" | tr '[:lower:]' '[:upper:]' | tr -d '\r\n')
      validate_mac "$mac" && lookup_mac_vendor "$mac" "$json_output"
    done < "$input"
  else
    mac=$(echo "$input" | tr '[:lower:]' '[:upper:]')
    if validate_mac "$mac"; then
      lookup_mac_vendor "$mac" "$json_output"
    else
      echo "Invalid MAC address: $mac"
      exit 1
    fi
  fi
}

main "$@"