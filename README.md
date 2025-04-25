# MAC Lookup Tool

A Bash script that looks up MAC addresses using the [macvendors.com](https://macvendors.com/) API. It supports:

- URL encoding and input validation
- API error handling with retries
- Local result caching to avoid redundant lookups
- Batch processing via file input
- JSON or plain-text output

## Usage

```bash
./mac_lookup.sh <MAC address or file> [--json]
```

### Examples

**Single MAC address:**

```bash
./mac_lookup.sh 00:1A:2B:3C:4D:5E
```

**JSON output:**

```bash
./mac_lookup.sh 00:1A:2B:3C:4D:5E --json
```

**Batch mode:**

```bash
./mac_lookup.sh mac_list.txt
```

Where `mac_list.txt` contains one MAC address per line.

## Caching

The script caches results in `~/.cache/mac_lookup_cache` to speed up future lookups and reduce API usage.

## Dependencies

- `bash`
- `curl`

### Install via Homebrew:

```bash
brew tap willcurtis/tools
brew install mac-lookup-tool
```


## License

MIT – see [LICENSE](LICENSE) for details.
