#!/usr/bin/env bash
# Verify every link and every jbx/pip command referenced in profile/README.md
# (the org's public front page) still actually resolves. Parses the file
# rather than hardcoding a checklist, so it stays useful as the content
# changes — a broken link or a dead `jbx` alias here is public-facing
# breakage, not an internal doc nit, and it won't show up in this repo's
# own CI the way a code change would.
set -euo pipefail

FILE="${1:-profile/README.md}"
NS_URL="https://just-buildit.github.io"
FAIL=0

curl_code() {
    curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$1" 2>/dev/null || echo "000"
}

ok()   { echo "  OK   $*"; }
bad()  { echo "::error::BROKEN $*"; FAIL=1; }

echo "--- checking URLs referenced in ${FILE} ---"
# Markdown links, HTML href/src attributes, and bare URLs inside inline code
# (e.g. the `curl -sSL https://...` install line) — de-duplicated. Process
# substitution (not a pipe) so `bad()`'s FAIL=1 runs in this shell, not a
# subshell that discards it once the loop exits.
while read -r url; do
    code=$(curl_code "$url")
    if [[ "$code" -ge 200 && "$code" -lt 400 ]]; then
        ok "($code) $url"
    else
        bad "($code) $url"
    fi
done < <(grep -oE 'https?://[^ )"'"'"'<>]+' "$FILE" | sed 's/[.,;]*$//' | sort -u)

echo "--- checking 'pip install <pkg>' commands ---"
while read -r pkg; do
    code=$(curl_code "https://pypi.org/pypi/${pkg}/json")
    if [[ "$code" == "200" ]]; then
        ok "pip install ${pkg} (PyPI has it)"
    else
        bad "pip install ${pkg} -- PyPI lookup returned ${code}"
    fi
done < <(grep -oE 'pip install [A-Za-z0-9_.-]+' "$FILE" | awk '{print $3}' | sort -u)

echo "--- checking 'jbx <name>' commands ---"
curl -s "${NS_URL}/aliases.toml" -o /tmp/aliases.toml || true
while read -r name; do
    if [[ "$name" == just-bashit:* ]]; then
        # Built-in NS prefix: co-fetches straight from just-bashit's
        # source tree, bypassing aliases.toml entirely.
        rest="${name#just-bashit:}"
        resolved=""
        for ext in sh py; do
            url="https://raw.githubusercontent.com/just-buildit/just-bashit/main/src/just_bashit/${rest}.${ext}"
            code=$(curl_code "$url")
            if [[ "$code" == "200" ]]; then
                ok "jbx ${name} -> ${url}"
                resolved=1
                break
            fi
        done
        [[ -n "$resolved" ]] || bad "jbx ${name} -- no .sh/.py at just-bashit:src/just_bashit/${rest}"
        continue
    fi
    if [[ "$name" == gh:* || "$name" == http* ]]; then
        ok "jbx ${name} (explicit NS/URL, resolves directly)"
        continue
    fi
    # Bare name: aliases.toml, then the runner's own direct-hit fallback.
    if grep -qE "^${name}[[:space:]]*=" /tmp/aliases.toml 2>/dev/null; then
        ok "jbx ${name} (aliases.toml)"
        continue
    fi
    resolved=""
    for ext in sh py; do
        code=$(curl_code "${NS_URL}/${name}.${ext}")
        if [[ "$code" == "200" ]]; then
            ok "jbx ${name} -> ${NS_URL}/${name}.${ext}"
            resolved=1
            break
        fi
    done
    [[ -n "$resolved" ]] || bad "jbx ${name} -- no aliases.toml entry, no ${NS_URL}/${name}.{sh,py}"
done < <(grep -oE 'jbx [A-Za-z0-9_:.-]+' "$FILE" | awk '{print $2}' | sort -u)

if [[ "$FAIL" -ne 0 ]]; then
    echo
    echo "One or more links/commands in ${FILE} no longer resolve." >&2
    exit 1
fi
echo
echo "All links and commands in ${FILE} resolve."
