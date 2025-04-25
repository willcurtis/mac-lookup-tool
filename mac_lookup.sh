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

# Normalize MAC address to AA:BB:CC or AA:BB:CC:DD:EE:FF
normalize_mac() {
  local input="$1"
  local clean
  clean=$(echo "$input" | tr '[:lower:]' '[:upper:]' | tr -d ':-.')

  if [[ ${#clean} -lt 6 ]]; then
    echo "Invalid MAC: Too short"
    return 1
  fi

  if [[ ${#clean} -ge 12 ]]; then
    # Full MAC
    printf "%s:%s:%s:%s:%s:%s\n" \
      "${clean:0:2}" "${clean:2:2}" "${clean:4:2}" \
      "${clean:6:2}" "${clean:8:2}" "${clean:10:2}"
  else
    # OUI only
    printf "%s:%s:%s\n" \
      "${clean:0:2}" "${clean:2:2}" "${clean:4:2}"
  fi
}

# Validate normalized MAC address
validate_mac() {
  local mac="$1"
  [[ "$mac" =~ ^([0-9A-F]{2}:){2,5}[0-9A-F]{2}$ ]]
}

# Lookup vendor via API or cache
lookup_mac_vendor() {
  local mac="$1"
  local json_output="$2"

  local cached
  cached=$(grep -i "^$mac|" "$CACHE_FILE" | head -n1)
  if [[ -n "$cached" ]]; then
    local vendor="${cached#*|}"
    if [[ -n "$vendor" ]]; then
      output_result "$mac" "$vendor" "$json_output"
      return
    fi
  fi

  local encoded
  encoded=$(rawurlencode "$mac")

  local response http_code body

  response=$(curl -s -w "\n%{http_code}" "$API_URL_BASE/$encoded")
  http_code=$(printf "%s" "$response" | tail -n1)
  body=$(printf "%s" "$response" | sed '$d')

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
      mac=$(normalize_mac "$line")
      if validate_mac "$mac"; then
        lookup_mac_vendor "$mac" "$json_output"
      else
        echo "Invalid MAC address: $line"
      fi
    done < "$input"
  else
    mac=$(normalize_mac "$input")
    if validate_mac "$mac"; then
      lookup_mac_vendor "$mac" "$json_output"
    else
      echo "Invalid MAC address: $input"
      exit 1
    fi
  fi
}

main "$@"