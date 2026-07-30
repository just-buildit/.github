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

| Name                                                                                                      | Role                                            | Get it                                                    | Status                                                                                                                                                                                                                                                        |
| --------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**just-runit**](https://github.com/just-buildit/just-bashit/blob/main/src/just_bashit/just-runit) (`jb`) | Fast ephemeral script runner                    | `. <(curl -sSL https://just-buildit.github.io/get-jb.sh)` | [![CI](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml)                                                                                                 |
| [**just-bashit**](https://github.com/just-buildit/just-bashit)                                            | Proven bash scripts & tools                     | `jbx just-bashit:logging log "hello"`                     | [![CI](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml)                                                                                                 |
| [**just-makeit**](https://github.com/just-buildit/just-makeit) (`jm`)                                     | Python C extensions out-of-the-box              | `pip install just-makeit`                                 | [![PyPI](https://img.shields.io/pypi/v/just-makeit)](https://pypi.org/project/just-makeit/) [![CI](https://github.com/just-buildit/just-makeit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-makeit/actions/workflows/ci.yml)     |
| [**just-buildit**](https://github.com/just-buildit/just-buildit)                                          | Zero-dep PEP 517 build backend for C extensions | `pip install just-buildit`                                | [![PyPI](https://img.shields.io/pypi/v/just-buildit)](https://pypi.org/project/just-buildit/) [![CI](https://github.com/just-buildit/just-buildit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-buildit/actions/workflows/ci.yml) |

Each tool stands alone. They also compose.

## How they fit together

**Greenfield Python+C extension** — `just-makeit new` stands up a
complete project: C source, headers, CMakeLists, Python bindings, type
stubs, tests, and benchmarks — all green on the first `make test`.
The build backend is `just-buildit`; the tool manifest (`jb.toml`, with
system build deps folded in under `[dev.*]`) is dropped in pre-populated
so the next contributor lands running. You write the algorithm; nothing
else.

**Any project, anywhere** — drop a `jb-deps.toml` at the repo root and
run `jbx install-deps`. System packages for apt/pacman/brew/dnf/zypper/msys2
are detected and installed. No Python, no Docker, no setup.

**One-off scripts** — `jbx <name>` fetches, runs, and discards. Detects
bash or Python from shebang/extension; Python scripts pick up PEP 723
inline dependencies through `uv run`. Cache TTL, checksum verification,
function dispatch, sandboxed env — all there.

**Namespaces** — `jbx [NAMESPACE:]NAME`. A namespace resolves to a base
URL. The default is `just-buildit`, served from the org-pages root with
a curated `aliases.toml`. `jbx install-deps` just works; `jbx gh:user/repo/tool` hits GitHub raw directly.

## Get started

```sh
# Get the universal entrypoint (installs jb + jbx) — only curl line you need
. <(curl -sSL https://just-buildit.github.io/get-jb.sh)

# Install just-makeit, then stand up a Python+C extension
# (drops a jb.toml with build deps pre-populated under [dev.*])
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

______________________________________________________________________

______________________________________________________________________

# Internal — roadmap & gaps

> Below the fold: planning notes for contributors. External readers can stop here.

## Design conventions

- **`jb-deps.toml`** — declarative system-package list grouped by purpose
    (`runtime`, `dev`) and package manager (`apt`, `pacman`, `brew`,
    `dnf`, `zypper`, `msys2`). Lives at repo root; auto-discovered by
    `jbx install-deps`.
- **`jb.toml`** — explicit list of `jb`/`jbx` tools a project depends on,
    analogous to `[project.dependencies]`. Lives at repo root in every
    project type (Python, C, bare). `pyproject.toml` keeps its packaging
    job, `jb.toml` keeps its tool job.
- **Namespaced invocation** — `jbx [NS:]NAME`. A namespace resolves to a
    single base URL. Default namespace = `just-buildit`. Built-in prefixes:
    `just-bashit:`, `gh:`, `https://`.
- **`aliases.toml`** — manifest at the org-pages root mapping short
    names to URLs. `jbx some-tool` consults the alias table when there is
    no script at `${NS_URL}/some-tool[.sh|.py]`.
- **`install-deps.sh`** — thin per-project shim that delegates to `jbx install-deps`. Optional — `jbx install-deps` works directly when
    `jb-deps.toml` is present.

## Schemas

### `jb-deps.toml`

```toml
[runtime.apt]    packages = ["libzmq3-dev", "libfftw3-dev"]
[runtime.pacman] packages = ["zeromq", "fftw"]
[dev.apt]        packages = ["build-essential", "cmake", "python3-dev"]
[dev.pacman]     packages = ["base-devel", "cmake", "python"]
```

### `jb.toml`

```toml
[project]
name    = "my_project"
version = "0.1.0"

[tools.install-deps]
source    = "just-bashit:install-deps"
deps_file = "jb-deps.toml"
groups    = ["runtime", "dev"]

[tools.just-makeit]
source = "just-bashit:just-makeit"
config = "just-makeit.toml"
```

### `aliases.toml` (hosted at org-pages root)

```toml
[aliases]
install-deps = "https://just-buildit.github.io/jbs/install-deps.sh"
get-jb       = "https://just-buildit.github.io/get-jb.sh"
# Third-party tools welcomed via PR.
```

### Resolution precedence for `jbx NAME`

1. **Explicit `NS:` prefix** — `jbx gh:user/repo/x`, `jbx https://...`:
    skip everything below, resolve directly.
1. **`[tools.NAME]` in `jb.toml`** (walking up from CWD) — use declared source.
1. **Default namespace `aliases.toml`** — fetch (cached), look up `NAME`.
1. **Default namespace direct hit** — HEAD `${NS_URL}/NAME.sh`, then `.py`.
1. **Error** — name not found.

## Status

### Shipped

- [x] `jb` / `jbx` / `just-buildit` naming; conflict detection for `jb`; stale `jr`/`jx` cleanup on reinstall
- [x] `jb` top-level subcommand dispatch (`jb run` → runner; extensible for `jb install` etc.)
- [x] Namespace model: bare NAME → default NS via `aliases.toml` then HEAD probe; `just-bashit:NAME` co-fetch
- [x] Arg parsing: flags not captured as FUNC; FUNC validated via `declare -F`; verbose shadowing diagnostic
- [x] Version-aware installer: fresh/upgrade/already-current; `JB_REINSTALL=1` escape hatch
- [x] Org-pages site: themed, `aliases.toml`, mirror CI, `get-jb.sh` short URL
- [x] `jb.toml` format defined; doppler carries one
- [x] `jbs-deps.toml` auto-discovery in CWD

### In flight

- [x] **Rename `jbs-deps.toml` → `jb-deps.toml`** across just-bashit source, docs, doppler
- [x] **`jb install`** — reads `jb.toml`, walks up from CWD, pre-fetches every declared tool into cache
- [x] **`just-makeit new` emits `jb.toml`** with dev deps pre-populated; `jbx install-deps -g dev` works immediately
- [ ] **User namespace config** — `~/.config/just-runit/namespaces.toml` for custom NS registration

### Gaps

- [ ] **Parity `get-just-*.sh` scripts** — add `get-just-makeit.sh`, `get-just-bashit.sh`, `get-just-buildit.sh`
- [ ] **`just-buildit init [--pep517|--bare|--c]`** — unified scaffold entry point
- [ ] `jb-deps.toml` / `jb.toml` schemas — JSON Schema for editor completion
- [ ] CHANGELOG hygiene across repos is uneven

______________________________________________________________________

## Makefile standard — cross-org plan

One `standard.mk` every repo includes, with per-repo variation expressed as
configuration rather than as a fork. Design RFC and full rationale:
[doppler-dsp/doppler#555](https://github.com/doppler-dsp/doppler/issues/555).

**Scope:** all repos in `just-buildit` and `doppler-dsp`.

**Canonical home:** `just-buildit.github.io`, served at
<https://just-buildit.github.io/standard.mk> and hand-edited beside
`aliases.toml`. It must not live in a repo that *consumes* the standard, which
rules out doppler, just-makeit **and `just-buildit/just-buildit`** — the last
of those has a `Makefile` of its own, so it is an adopter like any other. The
org-pages root is a non-consumer whose stated charter is already "the small
static resources the toolchain depends on", and serving from the CDN keeps the
drift gate to a single `curl` with no clone, no auth, and no raw.githubusercontent
rate limit — the same reason the `jbs/` libs were moved there.

### Problem

A written convention exists (`skills://makefile-convention`) and every repo
hand-implements it, so they drift. Measured 2026-07-30:

|                                 | doppler | just-makeit |
| ------------------------------- | ------- | ----------- |
| targets defined                 | 50      | 27          |
| targets shared between the two  | 18      | 18          |
| listed by `make help`           | 30      | 22          |
| CI `run:` steps invoking `make` | 12 / 83 | 4 / 71      |

Concrete consequences, all live: doppler has no `format` target; the same
benchmark concepts are named `bench-baseline`/`bench-check` in one repo and
`bench-save`/`bench-compare` in the other; `zensical build --strict` is
implemented in three places that disagree, and every doppler PR builds the docs
site twice; `make wheel` is in `.PHONY` and in `help` with no rule, so it exits
0 having done nothing.

### The standard

Universal (8): `all help setup clean test test-fast lint format`, plus one
`lint-<tool>` dispatch target per configured tool. Feature groups defined only
when flagged — `HAS_DOCS`, `HAS_C`, `HAS_DOXYGEN`, `HAS_PYTHON`, `HAS_RUST`,
`HAS_BENCH`, `HAS_COVERAGE`, `HAS_RELEASE`, `HAS_EXAMPLES` — plus `test-all` / `gates`
aggregates. **Cap: 38 targets with every flag on.**

`install-deps` is universal (system packages via `jbx install-deps`; a no-op
where a repo declares none) and is distinct from `setup`, which installs
*project* deps. `test-examples` sits in `HAS_EXAMPLES`. Both were added after
the list was checked against the measured union rather than assembled from
memory — see criterion 10.

- **Dispatch is required, not optional.** `.pre-commit-config.yaml` calls
    `make -s lint-<tool>`; the Makefile invokes `$(DEV_RUN) <tool>`; `uv.lock`
    pins the version. This is what makes local and CI resolve identically, so a
    hand-pinned `additional_dependencies` list becomes unnecessary.
- **`help` is generated** from `##` comments, never hand-maintained.
- **`release` is reserved** for the C build type (`clean` + `build   BUILD_TYPE=Release`). The release *workflow* is `ship` / `tag-release`.
- **Naming is `<noun>-<qualifier>`**, making the noun a namespace:
    `test-python`, `test-rust`, `version-check`. `make test-<TAB>` then completes
    the whole family.
- **`local.mk`** is included if present and may only *add* targets, never
    redefine a standard one — otherwise it becomes the fork this prevents.
- **The drift gate fetches canonical every time, and a failed fetch fails the
    gate.** `make lint` compares the vendored copy against
    <https://just-buildit.github.io/standard.mk>. There is no cache: a cache
    would mean the most likely failure — the fetch failing while the network is
    fine (CDN outage, a bad deploy, a 404 after a rename) — silently degrades
    into "compared against something older", and one bad deploy would disable
    the drift gate across every repo at once with nothing going red. A gate that
    cannot reach its reference has not passed; it has not run, and it says so by
    failing. That is the same reason the gate fails rather than warns.

### Required files

Each file owns exactly one concern; nothing states a tool's invocation twice.

| File                      | Purpose                                                                                                                                                                        |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Makefile`                | Configuration only — feature flags, path and tool overrides, `include standard.mk`, and repo-local targets. Nothing shared lives here.                                         |
| `standard.mk`             | The shared targets, vendored verbatim. Never edited in-repo: the drift gate fails `make lint` on any difference from canonical.                                                |
| `local.mk`                | Optional. Included if present; may only *add* targets, never redefine a standard one — otherwise it becomes the fork this prevents.                                            |
| `pyproject.toml`          | **Which** tools, at **what** versions (the `dev` group).                                                                                                                       |
| `uv.lock`                 | Pins those versions, committed. This is what makes local and CI resolve identically, and so what lets dispatch close the environment-drift class.                              |
| `.pre-commit-config.yaml` | **When** a check fires. Dispatches inward (`entry: make -s lint-<tool>`, `language: system`) and resolves no tool versions itself.                                             |
| `jb.toml`                 | Tool manifest, with system packages folded in under `[dev.<manager>]` and consumed by `install-deps`. (`jb-deps.toml` is the standalone alternative for repos that prefer it.) |
| `.github/workflows/*.yml` | Calls `make <target>`. Anything else must be provably environment plumbing — runner setup, artifact transport, release packaging.                                              |

**Adoption adds exactly one file.** Both repos already carry `Makefile`,
`pyproject.toml`, `uv.lock`, `.pre-commit-config.yaml` and `jb.toml` today;
only `standard.mk` is new, and `local.mk` is optional and so far unneeded.

### Success criteria

Measured against the 2026-07-30 baseline above:

| #   | criterion                                                                    | today        | target      |
| --- | ---------------------------------------------------------------------------- | ------------ | ----------- |
| 1   | repo Makefile holds only config + genuinely local targets                    | 50 / 27      | ≤18 / ≤1    |
| 2   | `make help` lists every target, and every listed target exists               | 60% / 81%    | 100% / 100% |
| 3   | ghost targets (`.PHONY` with no rule)                                        | 1 / 0        | 0 / 0       |
| 4   | CI `run:` steps are `make <target>` or environment plumbing                  | 12/83 / 4/71 | 100% / 100% |
| 5   | `zensical build --strict` implementations                                    | 3            | 1           |
| 6   | docs site builds per doppler PR                                              | 2            | 1           |
| 7   | hand-pinned `additional_dependencies` for lock-managed tools                 | yes          | none        |
| 8   | editing vendored `standard.mk` fails `make lint`                             | n/a          | both repos  |
| 9   | `make <standard target>` behaves identically across repos                    | no           | yes         |
| 10  | targets shared by two or more adopting repos that sit *outside* the standard | 3            | 0           |

Criteria 2, 3 and 8 are enforced by gates rather than by review, so they cannot
regress silently — which is the point, since none of the problems above were
decided, they accumulated. `make wheel` had been exiting 0 with no rule behind
it in a repo that already had a `make lint` gate, CI on every PR, and a `help`
entry advertising it: every human control was in place, and none of them caught
it.

Criterion 10 applies the same lesson to the standard's own scope. Three targets
shared by both repos — `release-branch`, `test-examples`, `install-deps` — were
each missed while the list was written from memory, and each was found by
recomputing the union from the two Makefiles. The list is therefore **derived by
script from the measured union of adopting repos**, and the invariant "no target
shared by two or more repos sits outside the standard" is checked rather than
reasoned about.

### Phases

- [ ] **P0 — prototype** `standard.mk` in just-makeit; vendored, drift gate
    inert until P1 publishes canonical. Also collapses just-makeit's `install`
    (`uv sync --group dev`) into `setup`, of which it is a strict subset, so a
    fourth deps-ish name never reaches the standard *(just-makeit)*
- [ ] **P1 — publish** canonical `standard.mk` in this org; wire the drift gate
    live *(just-buildit)*
- [ ] **P2 — doppler port**: `docs-check` first (deletes the three-way
    divergence and the double site build in one commit), then `lint-<tool>`
    dispatch, then ghost/backfill/renames *(doppler)*
- [ ] **P3 — convention doc** updated to match, landing *with* P2 — until
    `standard.mk` exists, the doc describing the old names is still accurate
    *(doppler)*
- [ ] **P4 — CI port** per repo: call standard targets, delete each inline
    duplicate in the same commit *(per repo)*

### Non-goals

- Not a rewrite of target semantics — the convention already defines them; this
    implements them once instead of N times.
- Not removing repo-specific targets. doppler keeps `specan`, `gallery`,
    `record-demo`, `blazing` and its bench scripts.
- Not a general fix for environment drift. Dispatch closes it for lock-managed
    Python tools; anything resolved outside the lock is still on its own.

## Decision log

- **`jb-deps.toml` beats stdin** when both are present. TTY detection
    (`[ -t 0 ]`) doesn't survive `bash -c` or CI — file-first is the only
    reliable ordering.
- **Filename prefix is `jb-`**, not `jbs-` — the deps file is an org-level
    convention, not a just-bashit-specific one.
- **`jb` may conflict** (e.g. Jenkins X used `jx`; `jb` could be taken too).
    Installer detects this and falls back to `just-buildit`, which is always
    installed and unique.
- **`jbx` is the runner shorthand** — `jb run` for the subcommand form,
    `jbx` for fast one-liners. Both always installed.
- **`jb.toml` is standalone**, not a `[tool.jb]` table in `pyproject.toml`.
    Uniform across project types; Python packaging metadata stays uncoupled
    from cross-org tooling.
- **`--pep517` delegates** instead of re-implementing scaffolding.
    `just-makeit` already does this well.
- **Templates as files**, not Python heredocs. Diffs against real generated
    projects stay readable.
