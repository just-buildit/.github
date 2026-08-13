#!/usr/bin/env bash
#
# sync-profile.sh — regenerate profile/README.md from README.md.
#
# GitHub renders `profile/README.md` as the ORGANISATION landing page; the root
# `README.md` is merely this repo's own README. They were two hand-maintained
# copies of the same public text, and that is not a hypothetical risk: the
# bootstrap.toml rename updated the root file alone, leaving the actual public
# page advertising `jb`, `jb.toml` and `jb-deps.toml` — verified live before
# this script existed.
#
# Root README = public half + the below-the-fold internal section. The profile
# is exactly the public half, so it is DERIVED: everything above the fold
# marker. One source, one generated copy, and a hook that regenerates it.
#
# Usage:  .github/scripts/sync-profile.sh          # rewrite profile/README.md
#         .github/scripts/sync-profile.sh --check  # exit 1 if it would change
set -euo pipefail

cd "$(dirname "$0")/../.."

SRC="README.md"
DEST="profile/README.md"
# The first line of the below-the-fold section. Everything from the separator
# that precedes it onward belongs to contributors, not to the front page.
FOLD='^# Internal — roadmap & gaps$'

if ! grep -qE "${FOLD}" "${SRC}"; then
	echo "sync-profile: no fold marker in ${SRC}" >&2
	echo "  expected a line matching: ${FOLD}" >&2
	echo "  Without it this script cannot tell public from internal, and a" >&2
	echo "  silent full copy would publish the roadmap. Refusing." >&2
	exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

# Take everything before the fold, then drop the trailing separator and any
# blank lines it leaves behind, so the profile ends on real content.
awk -v fold="${FOLD}" '$0 ~ fold { exit } { print }' "${SRC}" \
	| awk '{ lines[NR] = $0 }
	       END {
	           last = NR
	           while (last > 0 && (lines[last] == "" || lines[last] ~ /^_+$/)) last--
	           for (i = 1; i <= last; i++) print lines[i]
	       }' >"${tmp}"

if [ ! -s "${tmp}" ]; then
	echo "sync-profile: refusing to write an empty ${DEST}" >&2
	exit 1
fi

if [ "${1:-}" = "--check" ]; then
	if ! diff -u "${DEST}" "${tmp}"; then
		echo "" >&2
		echo "sync-profile: ${DEST} is stale — run .github/scripts/sync-profile.sh" >&2
		exit 1
	fi
	echo "sync-profile: ${DEST} matches ${SRC}"
	exit 0
fi

if diff -q "${DEST}" "${tmp}" >/dev/null 2>&1; then
	exit 0
fi
cp "${tmp}" "${DEST}"
echo "sync-profile: regenerated ${DEST} from ${SRC}"
exit 1 # pre-commit contract: a hook that changed a file reports failure
