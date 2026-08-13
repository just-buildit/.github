<p align="center">
  <img src="https://raw.githubusercontent.com/just-buildit/just-buildit/main/docs/assets/logo-wordmark.png" alt="just-buildit" width="540">
</p>

<p align="center"><em>Complete project infrastructure tooling and automation.</em></p>

______________________________________________________________________

Stand up a complete project, install its system dependencies, fetch
and run its tools, build it into a wheel — all from small primitives
that don't own your project. Declare what you need in TOML; the
tooling pulls the rest on demand.

## Tools

[![just-bashit CI](https://img.shields.io/github/actions/workflow/status/just-buildit/just-bashit/ci.yml?label=just-bashit%20CI)](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml)
[![just-makeit CI](https://img.shields.io/github/actions/workflow/status/just-buildit/just-makeit/ci.yml?label=just-makeit%20CI)](https://github.com/just-buildit/just-makeit/actions/workflows/ci.yml)
[![just-buildit CI](https://img.shields.io/github/actions/workflow/status/just-buildit/just-buildit/ci.yml?label=just-buildit%20CI)](https://github.com/just-buildit/just-buildit/actions/workflows/ci.yml)
[![just-bashit on PyPI](https://img.shields.io/pypi/v/just-bashit?label=just-bashit&color=blue)](https://pypi.org/project/just-bashit/)
[![just-makeit on PyPI](https://img.shields.io/pypi/v/just-makeit?label=just-makeit&color=blue)](https://pypi.org/project/just-makeit/)
[![just-buildit on PyPI](https://img.shields.io/pypi/v/just-buildit?label=just-buildit&color=blue)](https://pypi.org/project/just-buildit/)

<table>
<tr><td>

### ⚡ `jbx` — start here

**A fast ephemeral script runner: fetches, runs, discards.** One curl line
installs it, and everything else in the org is reachable through it — no
Python, no Docker, no clone.

```sh
. <(curl -sSL https://just-buildit.github.io/get-jb.sh)   # the only curl you need

jbx install-deps                      # system packages, from bootstrap.toml
jbx just-bashit:logging log "hello"   # any script in the org, by name
jbx gh:user/repo/tool                 # or anything on GitHub, by URL
```

Namespaces, PEP 723 inline deps, cache TTL, checksum verification and a
sandboxed env are all built in. [`just-runit`](https://github.com/just-buildit/just-bashit/blob/main/src/just_bashit/just-runit)
is the same runner under its full name, for the subcommand form.

</td></tr>
</table>

**The toolchain** — each piece stands alone, and they compose:

| Name                                                                  | Role                                            | Get it                                |
| --------------------------------------------------------------------- | ----------------------------------------------- | ------------------------------------- |
| [**just-bashit**](https://github.com/just-buildit/just-bashit)        | Proven bash scripts & tools                     | `jbx just-bashit:logging log "hello"` |
| [**just-makeit**](https://github.com/just-buildit/just-makeit) (`jm`) | Python C extensions out-of-the-box              | `pip install just-makeit`             |
| [**just-buildit**](https://github.com/just-buildit/just-buildit)      | Zero-dep PEP 517 build backend for C extensions | `pip install just-buildit`            |

## How they fit together

**Greenfield Python+C extension** — `just-makeit new` stands up a
complete project: C source, headers, CMakeLists, Python bindings, type
stubs, tests, and benchmarks — all green on the first `make test`.
The build backend is `just-buildit`; the bootstrap manifest
(`bootstrap.toml`, carrying the `[tools.*]` table and the system build
deps under `[dev.*]`) is dropped in pre-populated so the next
contributor lands running. You write the algorithm; nothing else.

**Any project, anywhere** — drop a `bootstrap.toml` at the repo root and
run `jbx install-deps`. System packages for apt/pacman/brew/dnf/zypper/msys2
are detected and installed. No Python, no Docker, no setup.

**One-off scripts** — `jbx <name>` fetches, runs, and discards. Detects
bash or Python from shebang/extension; Python scripts pick up PEP 723
inline dependencies through `uv run`. Cache TTL, checksum verification,
function dispatch, sandboxed env — all there.

**Namespaces** — `jbx [NAMESPACE:]NAME`. A namespace resolves to a base
URL. The default is `just-buildit`, served from the org-pages root with
a curated `aliases.toml`. `jbx install-deps` just works; `jbx gh:user/repo/tool` hits GitHub raw directly.

## One `make` interface, everywhere

Every repo in the org answers the same targets, because every repo vendors the
same [`standard.mk`](https://just-buildit.github.io/standard.mk). You do not
have to read a project's Makefile to work on it:

```sh
make help          # every target, generated from the rules — never hand-listed
make setup         # one-time per clone: dependencies + the git hook
make install-deps  # system packages, from bootstrap.toml
make test          # the default suite
make lint          # the gate CI runs — and CI runs nothing else
make format        # auto-fix with every configured formatter
```

Adopting it is one fetch and one include. Vendor the file:

```sh
curl -fsSL https://just-buildit.github.io/standard.mk -o standard.mk
```

…then your Makefile is **configuration only** — feature flags and the commands
behind them, never a copy of the shared rules:

```make
# Makefile
TEST_CMD      = pytest
TEST_FAST_CMD = pytest -x
CLEAN_PATHS   = dist/ build/
include standard.mk
```

That is the whole adoption, and it is enough for `make help`, `test`, `lint`,
`format` and `clean`. Nine feature flags add the rest — `HAS_C`, `HAS_PYTHON`,
`HAS_RUST`, `HAS_DOCS`, `HAS_DOXYGEN`, `HAS_BENCH`, `HAS_COVERAGE`,
`HAS_RELEASE`, `HAS_EXAMPLES` — and each requires the command behind it: a flag
with nothing to run is a parse error, not a target that silently does nothing.

Each file owns one concern: the **Makefile** says *how* a tool runs,
`pyproject.toml` says *which version*, and `.pre-commit-config.yaml` says
*when* — dispatching back in with `make lint-<tool>` so a hook and CI cannot
disagree about what a check means.

Vendoring arms a drift gate: `make lint` re-fetches canonical every time and
fails on any difference, so the copy in your repo cannot quietly become a fork.

## Get started

```sh
# Install jbx (and just-runit, the same runner's full name)
. <(curl -sSL https://just-buildit.github.io/get-jb.sh)

# Install just-makeit, then stand up a Python+C extension
# (drops a bootstrap.toml with build deps pre-populated under [dev.*])
pip install just-makeit
just-makeit new my_project --object engine --state gain:double:1.0
cd my_project

# Install those build deps for your platform (apt/pacman/brew/dnf/...)
jbx install-deps

# Build and test — green on first run
make && make test
```

## License

MIT across all repos.
