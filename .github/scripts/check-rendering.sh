#!/usr/bin/env bash
# Verify the page RENDERS, not merely that its links resolve.
#
# check-readme-content.sh asks whether every URL answers. That is a different
# question, and it cannot see the failure this guards: a page whose markup is
# broken renders as garbage while every link in it still resolves perfectly.
# The same blind spot let a stale org page through — the checker was aimed at
# the wrong property.
#
# The concrete risk is the `jbx` card. Markdown nested inside an HTML block is
# only parsed as markdown when blank lines separate it from the tags; get that
# wrong and GitHub escapes the whole thing, so the card shows literal
# backticks and `<td>` as text. Nothing else here would notice.
#
# Rendered through GitHub's own markdown API in `markdown` mode, which is how a
# README renders. NOT `gfm` mode — that is comment semantics, where every
# single newline becomes a <br>, so a hard-wrapped paragraph reads as broken
# and the check would fail on a page that is perfectly fine.
#
# Expectations are DERIVED from the source, never a hardcoded checklist, so
# adding a code block or a badge does not require editing this file.
#
# Usage:  .github/scripts/check-rendering.sh [file ...]
set -uo pipefail

FAIL=0
ok() { echo "  OK   $*"; }
bad() {
	echo "::error::$*"
	FAIL=1
}

check_file() {
	local file="$1" html
	echo "--- rendering ${file} ---"

	if ! html=$(gh api -X POST /markdown -f mode=markdown -F text=@"${file}" 2>&1); then
		bad "${file}: the markdown API refused to render it: ${html}"
		return
	fi
	if [ -z "${html}" ]; then
		bad "${file}: rendered to nothing"
		return
	fi

	# 1. Every fence became a highlighted code block. Opening and closing
	#    fences both match, hence the halving.
	local src_fences out_blocks
	src_fences=$(($(grep -c '^```' "${file}") / 2))
	out_blocks=$(grep -o 'class="highlight' <<<"${html}" | wc -l)
	if [ "${src_fences}" -eq "${out_blocks}" ]; then
		ok "${src_fences} code fence(s) rendered as code blocks"
	else
		bad "${file}: ${src_fences} fence(s) in source but ${out_blocks} rendered
  A fence inside an HTML block needs a blank line after the opening tag,
  or GitHub escapes it and the page shows literal backticks."
	fi

	# 2. No fence survived as literal text.
	if grep -q '```' <<<"${html}"; then
		bad "${file}: literal \`\`\` in the rendered output — a fence did not render"
	else
		ok "no unrendered fences"
	fi

	# 3. Raw HTML block tags were honoured, not escaped into visible text.
	if grep -qE '&lt;/?(table|tr|td)&gt;' <<<"${html}"; then
		bad "${file}: escaped <table>/<tr>/<td> in the output — the HTML block
  was treated as text. The card will render as markup on the page."
	else
		ok "HTML blocks honoured, not escaped"
	fi

	# 4. Every heading became a heading element.
	#
	#    This is the one that actually catches the card breaking. Measured: with
	#    no blank line after `<tr><td>`, GitHub keeps the FIRST line inside the
	#    HTML block raw and parses the rest as markdown — so the fence and the
	#    bold text still render perfectly and only the heading comes out as
	#    literal "### ...". Every other assertion here stays green. Without this
	#    one the check was decorative, which the sabotage proved.
	#
	#    Headings are counted OUTSIDE fenced regions: this page has `# comment`
	#    lines inside its shell blocks, and they are not headings.
	local src_heads out_heads
	src_heads=$(awk '
		/^```/ { infence = !infence; next }
		!infence && /^#{1,6} / { n++ }
		END { print n + 0 }' "${file}")
	out_heads=$(grep -oE '<h[1-6][ >]' <<<"${html}" | wc -l)
	if [ "${out_heads}" -ge "${src_heads}" ]; then
		ok "${out_heads} heading(s) rendered (source has ${src_heads})"
	else
		bad "${file}: ${src_heads} heading(s) in source but only ${out_heads} rendered
  A heading on the line straight after an HTML tag stays literal text.
  Put a blank line between the tag and the markdown."
	fi

	# 5. Every image reference produced an <img>. Markdown images and raw HTML
	#    <img> both count, since this page uses both.
	local src_imgs out_imgs
	src_imgs=$(($(grep -o '!\[' "${file}" | wc -l) + $(grep -o '<img' "${file}" | wc -l)))
	out_imgs=$(grep -o '<img' <<<"${html}" | wc -l)
	if [ "${out_imgs}" -ge "${src_imgs}" ]; then
		ok "${out_imgs} image(s) rendered (source references ${src_imgs})"
	else
		bad "${file}: ${src_imgs} image reference(s) but only ${out_imgs} rendered"
	fi

	# 6. Every pipe table became a real table.
	local src_tables out_tables
	src_tables=$(grep -cE '^\| *-+' "${file}")
	out_tables=$(grep -o '<table' <<<"${html}" | wc -l)
	if [ "${out_tables}" -ge "${src_tables}" ]; then
		ok "${out_tables} table(s) rendered (source has ${src_tables} pipe table(s))"
	else
		bad "${file}: ${src_tables} pipe table(s) but only ${out_tables} rendered"
	fi
}

if [ "$#" -eq 0 ]; then
	set -- profile/README.md README.md
fi
for f in "$@"; do
	if [ ! -f "${f}" ]; then
		bad "${f}: no such file"
		continue
	fi
	check_file "${f}"
done

if [ "${FAIL}" -ne 0 ]; then
	echo "Rendering check FAILED."
	exit 1
fi
echo "Every page renders."
