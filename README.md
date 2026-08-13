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

______________________________________________________________________

# Internal — roadmap & gaps

> Below the fold: planning notes for contributors. External readers can stop here.

## Design conventions

- **`bootstrap.toml`** — what must exist BEFORE the language ecosystem's
    own package manager can run: system packages, and the `jbx` tools a
    project depends on. Lives at repo root in every project type (Python, C,
    bare). `pyproject.toml` keeps its packaging job; this keeps the bootstrap
    job. Named for what it declares, not for a tool — `jb` reads as
    just-buildit, the PEP 517 backend, which never opens it. It carries
    both halves: the declarative system-package list grouped by purpose
    (`runtime`, `dev`) and package manager (`apt`, `pacman`, `brew`, `dnf`,
    `zypper`, `msys2`), and the `[tools.*]` table. `jb.toml` and
    `jb-deps.toml` are the deprecated former names, still read with a
    warning.
- **Namespaced invocation** — `jbx [NS:]NAME`. A namespace resolves to a
    single base URL. Default namespace = `just-buildit`. Built-in prefixes:
    `just-bashit:`, `gh:`, `https://`.
- **`aliases.toml`** — manifest at the org-pages root mapping short
    names to URLs. `jbx some-tool` consults the alias table when there is
    no script at `${NS_URL}/some-tool[.sh|.py]`.
- **`install-deps.sh`** — thin per-project shim that delegates to `jbx install-deps`. Optional — `jbx install-deps` works directly when
    `bootstrap.toml` is present.

## Schemas

### `bootstrap.toml`

```toml
[project]
name    = "my_project"
version = "0.1.0"

[tools.install-deps]
source = "just-bashit:install-deps"
groups = ["runtime", "dev"]

[tools.just-makeit]
source = "just-bashit:just-makeit"
config = "just-makeit.toml"

[runtime.apt]    packages = ["libzmq3-dev", "libfftw3-dev"]
[runtime.pacman] packages = ["zeromq", "fftw"]
[dev.apt]        packages = ["build-essential", "cmake", "python3-dev"]
[dev.pacman]     packages = ["base-devel", "cmake", "python"]
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
1. **`[tools.NAME]` in `bootstrap.toml`** (walking up from CWD) — use declared source.
1. **Default namespace `aliases.toml`** — fetch (cached), look up `NAME`.
1. **Default namespace direct hit** — HEAD `${NS_URL}/NAME.sh`, then `.py`.
1. **Error** — name not found.

## Status

### Shipped

- [x] `jb` / `jbx` / `just-buildit` naming; conflict detection for `jb`; stale `jr`/`jx` cleanup on reinstall — *superseded by the rename below; `jb` and `just-buildit` are no longer installed as runner names*
- [x] `just-runit` subcommand dispatch (falls through to the SPEC runner; `jbx` never takes subcommands)
- [x] Namespace model: bare NAME → default NS via `aliases.toml` then HEAD probe; `just-bashit:NAME` co-fetch
- [x] Arg parsing: flags not captured as FUNC; FUNC validated via `declare -F`; verbose shadowing diagnostic
- [x] Version-aware installer: fresh/upgrade/already-current; `JB_REINSTALL=1` escape hatch
- [x] Org-pages site: themed, `aliases.toml`, mirror CI, `get-jb.sh` short URL
- [x] `bootstrap.toml` format defined; doppler carries one
- [x] `jbs-deps.toml` auto-discovery in CWD

### In flight

- [x] **Rename `jbs-deps.toml` → `jb-deps.toml`** across just-bashit source, docs, doppler
- [x] **Rename `jb.toml` / `jb-deps.toml` → `bootstrap.toml`**, and `jb` /
    `just-buildit` stop naming the runner — one token had meant the org, the
    PEP 517 backend, and the script runner at once. Old names still read,
    with a warning (removal: just-bashit#30)
- [x] **`just-runit install`** — reads `bootstrap.toml`, walks up from CWD, pre-fetches every declared tool into cache
- [x] **`just-makeit new` emits `bootstrap.toml`** with dev deps pre-populated — shipped in just-makeit **0.57.0** (just-makeit#936, closing #935)
- [ ] **User namespace config** — `~/.config/just-runit/namespaces.toml` for custom NS registration

### Gaps

- [ ] **Parity `get-just-*.sh` scripts** — add `get-just-makeit.sh`, `get-just-bashit.sh`, `get-just-buildit.sh`
- [ ] **`just-buildit init [--pep517|--bare|--c]`** — unified scaffold entry point
- [ ] `bootstrap.toml` schema — JSON Schema for editor completion
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

Universal (9): `all help setup clean test test-fast lint format install-deps`,
plus one `lint-<tool>` dispatch target per configured tool. Feature groups
defined only when flagged — `HAS_DOCS`, `HAS_C`, `HAS_DOXYGEN`, `HAS_PYTHON`, `HAS_RUST`,
`HAS_BENCH`, `HAS_COVERAGE`, `HAS_RELEASE`, `HAS_EXAMPLES` — plus `test-all` / `gates`
aggregates.

**Cap, with every flag on: 35 user-facing + N dispatch + 3 enforcement.** The
three counts are separate because they scale differently — `N` is per-repo (the
tools that repo configures) and the enforcement gates are fixed — and stating
them as one number is how a cap stops being a check. It had already happened
here: this line read "38 targets", the P0 prototype measured 38, and the two
were different sets of 38. The plan was counting `lint-<tool>` and not the
enforcement gates, and P0 counted the reverse, so two offsetting errors agreed.

The 35 is the [#555](https://github.com/doppler-dsp/doppler/issues/555) group
table summed: 9 universal + 2 aggregates + 24 across the nine groups
(`HAS_DOCS` 3, `HAS_C` 3, `HAS_DOXYGEN` 2, `HAS_PYTHON` 3, `HAS_RUST` 1,
`HAS_BENCH` 3, `HAS_COVERAGE` 2, `HAS_RELEASE` 6, `HAS_EXAMPLES` 1). Check a
build against that table **target-for-target, not in total** — summing to the
right number is what hid this. Repo-local targets (`LOCAL_TARGETS`) are outside
the cap by definition: they are what criterion 1 bounds.

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

| File                      | Purpose                                                                                                                                                                                                                                                          |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Makefile`                | Configuration only — feature flags, path and tool overrides, `include standard.mk`, and repo-local targets. Nothing shared lives here.                                                                                                                           |
| `standard.mk`             | The shared targets, vendored verbatim **by fetching canonical** (see below). Never edited in-repo: the drift gate fails `make lint` on any difference from canonical.                                                                                            |
| `local.mk`                | Optional. Included if present; may only *add* targets, never redefine a standard one — otherwise it becomes the fork this prevents.                                                                                                                              |
| `pyproject.toml`          | **Which** tools, at **what** versions (the `dev` group).                                                                                                                                                                                                         |
| `uv.lock`                 | Pins those versions, committed. This is what makes local and CI resolve identically, and so what lets dispatch close the environment-drift class.                                                                                                                |
| `.pre-commit-config.yaml` | **When** a check fires. Dispatches inward (`entry: make -s lint-<tool>`, `language: system`) and resolves no versions for lock-managed tools. Non-Python tools that cannot come from `uv.lock` — `clang-format`, `cmake-format` — keep their pinned `rev:` here. |
| `bootstrap.toml`          | Bootstrap manifest: the `[tools.*]` table, plus system packages under `[dev.<manager>]` consumed by `install-deps`. (`jb.toml` / `jb-deps.toml` are the deprecated former names, still read with a warning.)                                                     |
| `.github/workflows/*.yml` | Calls `make <target>`. Anything else must be provably environment plumbing — runner setup, artifact transport, release packaging.                                                                                                                                |

**Adoption adds exactly one file.** Both repos already carry `Makefile`,
`pyproject.toml`, `uv.lock`, `.pre-commit-config.yaml` and `bootstrap.toml` today;
only `standard.mk` is new, and `local.mk` is optional and so far unneeded.

**Adoption means `curl` canonical — never `cp` a sibling.**

```sh
curl -fsSL -o standard.mk https://just-buildit.github.io/standard.mk
```

That is the whole of it: there is no line to add, because `STANDARD_URL`
defaults to canonical *inside* the file. Vendoring is what arms the drift gate.

The failure mode this rules out is not hypothetical — it is how the second
adopter ended up unguarded on day one. doppler adopted by taking the file from
just-makeit's working tree, which at that moment held the pre-publication copy
where `STANDARD_URL` was still empty and opt-in. The result passed every gate
and reported `standard-check: inert`, which reads like a pass, so nothing went
red anywhere: doppler ran for a day with **no drift protection at all** while
its `make lint` was green. Fixed by re-vendoring
([doppler-dsp/doppler#559](https://github.com/doppler-dsp/doppler/pull/559)).

Two consequences worth stating, since both cost time:

- **Arming-by-default only protects an adopter that vendors the *current*
    canonical.** A copy taken from another repo carries whatever that repo had
    at the time, including an older arming policy — so the copy silently
    reintroduces the fail-open the default exists to prevent.
- **After a change to canonical, adopters do not update themselves.** Their
    gate goes red, which is correct and is the point; the fix is to re-fetch,
    never to edit the vendored copy. An adopter whose gate is *inert* is the
    one case that will not tell you.

### Success criteria

Values are doppler / just-makeit, against the 2026-07-30 baseline above.
**Status as of 2026-07-31**, every number re-measured rather than carried
forward:

| #   | criterion                                                                    | baseline     | target      | now                     |     |
| --- | ---------------------------------------------------------------------------- | ------------ | ----------- | ----------------------- | --- |
| 1   | repo Makefile holds only config + genuinely local targets                    | 50 / 27      | 0 shared    | **0 shared / 0 shared** | ✅  |
| 2   | `make help` lists every target, and every listed target exists               | 60% / 81%    | 100% / 100% | **100% / 100%**         | ✅  |
| 3   | ghost targets (`.PHONY` with no rule)                                        | 1 / 0        | 0 / 0       | **0 / 0**               | ✅  |
| 4   | CI `run:` steps are `make <target>` or environment plumbing                  | 12/83 / 4/71 | 100% / 100% | **6 / 42** unclassified | ⬜  |
| 5   | `zensical build --strict` implementations                                    | 3            | 1           | **1**                   | ✅  |
| 6   | docs site builds per doppler PR                                              | 2            | 1           | **1**                   | ✅  |
| 7   | hand-pinned `additional_dependencies` for lock-managed tools                 | yes          | none        | **none**                | ✅  |
| 8   | editing vendored `standard.mk` fails `make lint`                             | n/a          | both repos  | **both**                | ✅  |
| 9   | `make <standard target>` behaves identically across repos                    | no           | yes         | **byte-identical**      | ✅  |
| 10  | targets shared by two or more adopting repos that sit *outside* the standard | 3            | 0           | **0**                   | ✅  |

Nine of ten met. The one that is not:

**Criterion 4 — P4, and honestly measured for the first time.** doppler is at
6 unclassified of 74 (3 CI-native, 3 release-path deferred on purpose);
just-makeit at 42 of 71, most of them `artifact.yml` scaffold-smoke steps that
drive the jm CLI rather than the repo's own build. See P4 below.

Criterion 1 is met in both repos under its corrected reading (see the
property note below): neither Makefile defines a shared target, and every
local one is declared in `LOCAL_TARGETS` — doppler 26 = 26, reconciliation
enforced by `help-check`.

Criterion 9 is now stronger than "behaves identically": both repos vendor the
**same file, byte for byte** (`77fe8941…`), verified against canonical rather
than against each other.

Criterion 1 is a **property, not a count**: no shared target defined in a repo
Makefile, and every local one declared in `LOCAL_TARGETS`. It was originally
written as "≤18 / ≤1", but a local-target count is not a quality signal — a
repo legitimately grows local targets (doppler added seven binary-hygiene gates
in a single afternoon), and a criterion that goes stale on healthy activity
gets ignored rather than fixed. What must not drift is criterion 10, the
*shared* set.

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

- [x] **P0 — prototype** `standard.mk` in just-makeit; vendored, drift gate
    inert until P1 publishes canonical. Also collapses just-makeit's `install`
    (`uv sync --group dev`) into `setup`, of which it is a strict subset, so a
    fourth deps-ish name never reaches the standard *(just-makeit)* —
    **done**, [just-buildit/just-makeit#636](https://github.com/just-buildit/just-makeit/pull/636).
    Prototyping in one repo before publishing paid for itself twice: the file
    rejected the GNU make 3.81 that macOS ships, and the gates parsed a
    `make -p` database whose wording changed in 3.82. Both would have gone out
    to every adopter at once. **P1 must publish the post-review file**, which also
    carries `coverage-gate`, `HAS_EXAMPLES` reduced to `test-examples`, and
    `all` defaulting to `build` where `HAS_C`.

- [x] **P1 — publish** canonical `standard.mk` in this org; wire the drift gate
    live *(just-buildit)* — **done**,
    [just-buildit.github.io#9](https://github.com/just-buildit/just-buildit.github.io/pull/9)
    serving at <https://just-buildit.github.io/standard.mk>, vendored back into
    just-makeit by
    [just-makeit#637](https://github.com/just-buildit/just-makeit/pull/637).
    The gate is proven against the real remote, in CI as well as locally: a
    matching copy passes, a one-character edit fails with the diff.

    One design change from the plan. `STANDARD_URL` **defaults** to canonical
    inside `standard.mk` rather than being set per adopter, because opt-in
    fails open: a repo that vendors the file and forgets the line has no drift
    protection and reports that as a notice reading like a pass, and nobody
    greps for an absent line. Vendoring the file is what arms it; deliberate
    opt-out is `STANDARD_URL =`, a line that exists and so can be found.

    Consequence, stated because every adopter inherits it: **`make lint` now
    requires network.** That is the RFC's tradeoff for refusing a cache, not a
    side effect — a Pages outage reddens `lint` org-wide rather than silently
    comparing against something older.

- [x] **P2 — doppler port**: `docs-check` first (deletes the three-way
    divergence and the double site build in one commit), then `lint-<tool>`
    dispatch, then ghost/backfill/renames *(doppler)* — **done**,
    [doppler-dsp/doppler#558](https://github.com/doppler-dsp/doppler/pull/558)
    plus four follow-ups (#559 re-vendor, #560 criterion 6, #561 the CI-only
    gates, #562 the binary gates). 50 hand-maintained targets became
    **0 shared plus 25 genuinely doppler's own**; `help` went from 30-of-50
    (advertising two that did not work) to 67-of-67 generated.

    Two things the port could not express, both worked around in the repo
    rather than by editing the vendored copy, and both feeding the next
    canonical change:

    - **`docs-check` cannot accumulate.** The strict build is its own recipe
        line, so a build failure aborts the target — fatal where the gate
        exists to report *every* failure in one pass with a link checker last.
        Worked around with `DOCS_CHECK_BUILD_CMD = :`.
    - **The build step has no flag surface.** `CMAKE_FLAGS` reaches configure
        only, so an adopting C repo silently drops from N jobs to one. doppler
        would have gone 20 → 1. Covered by `export CMAKE_BUILD_PARALLEL_LEVEL`,
        which reaches every `cmake --build` rather than one recipe.

    And a trap worth the plan carrying: doppler adopted by **copying
    just-makeit's working tree**, which held the pre-publication file, so it
    shipped with the gate inert — reporting a notice that reads like a pass —
    and ran a full day unguarded with `make lint` green. See *Adoption means
    `curl` canonical* above; that rule exists because of this.

- [x] **P3 — convention doc** updated to match, landing *with* P2 — until
    `standard.mk` exists, the doc describing the old names is still accurate
    *(doppler)* — **done**, `skills://makefile-convention` rewritten alongside
    #558, plus the four sibling skills that named the renamed targets.

- [ ] **P4 — CI port** per repo: call standard targets, delete each inline
    duplicate in the same commit *(per repo)* — **in progress**, and the
    measured state differs sharply by repo:

    | repo        | `run:` steps | `make` | plumbing | unclassified |
    | ----------- | ------------ | ------ | -------- | ------------ |
    | doppler     | 74           | 29     | 39       | **6**        |
    | just-makeit | 71           | 5      | 24       | **42**       |

    doppler is substantially done: every gate in `ci.yml` and `docs.yml` now
    calls a target, including four that had never been runnable outside CI
    (`abi-check`, `link-check`, `glibc-check`, `specan-check`) and the doc
    gates (`test-stubs`, `test-api-docs`, `test-snippets`). Of its remaining
    6, three are CI-native (apt inside the Debian container, the
    `needs.*.result` aggregator, `cmake --install` packaging) and three are
    release-path — deliberately deferred, because those steps only execute
    during a release, so an error there is invisible until it is expensive.
    Best ported when a release will exercise them immediately.

    just-makeit is largely unstarted. Most of its 42 are `artifact.yml`'s
    scaffold-smoke steps, which drive the **jm CLI** rather than the repo's own
    build — whether those are "plumbing" or want targets is the per-repo
    judgement P4 asks for, not an omission.

    Two duplications P4 surfaced that a target-count audit would have missed,
    both in doppler and both now fixed: `docs.yml` reimplemented
    `make gen-c-api` inline and had already diverged (**`uv run mkdocs` vs
    `uv run --group docs mkdocs`**, and a `cp` that *merged* where the target
    *replaces* — so a deleted C symbol's page survived forever in the deployed
    site while vanishing locally); and `make test-python` selected a different
    set of tests from CI's pytest, which is the RFC's own complaint surviving
    the port that was supposed to end it.

### Non-goals

- Not a rewrite of target semantics — the convention already defines them; this
    implements them once instead of N times.
- Not removing repo-specific targets. doppler keeps `specan`, `gallery`,
    `record-demo`, `blazing` and its bench scripts.
- Not a general fix for environment drift. Dispatch closes it for lock-managed
    Python tools; anything resolved outside the lock is still on its own.

## Decision log

- **`bootstrap.toml` beats stdin** when both are present. TTY detection
    (`[ -t 0 ]`) doesn't survive `bash -c` or CI — file-first is the only
    reliable ordering.
- ~~**Filename prefix is `jb-`**, not `jbs-` — the deps file is an org-level
    convention, not a just-bashit-specific one.~~ **Superseded**: the prefix
    named a tool, which is the mistake `bootstrap.toml` corrects. The reasoning
    survives the reversal — it is why the new name is org-level too.
- ~~**`jb` may conflict** (e.g. Jenkins X used `jx`; `jb` could be taken too).
    Installer detects this and falls back to `just-buildit`, which is always
    installed and unique.~~ **Superseded**: neither name is installed now.
    `get-jb.sh` stopped creating the `jb` and `just-buildit` symlinks and
    prunes them on upgrade, so there is nothing left to collide — and
    `just-buildit` was the worse fallback anyway, being the build backend.
- **`jbx` is the runner** — `just-runit` for the subcommand form,
    `jbx` for fast one-liners. Both always installed.
- **`bootstrap.toml` is standalone**, not a `[tool.*]` table in `pyproject.toml`.
    Uniform across project types; Python packaging metadata stays uncoupled
    from cross-org tooling.
- **`--pep517` delegates** instead of re-implementing scaffolding.
    `just-makeit` already does this well.
- **Templates as files**, not Python heredocs. Diffs against real generated
    projects stay readable.
