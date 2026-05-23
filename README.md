<p align="center">
  <img src="https://raw.githubusercontent.com/just-buildit/just-buildit/main/docs/assets/logo-wordmark.png" alt="just-buildit" width="540">
</p>

<p align="center"><em>Complete project infrastructure tooling and automation.</em></p>

---

Stand up a complete project, install its system dependencies, fetch
and run its tools, build it into a wheel — all from small primitives
that don't own your project. Declare what you need in TOML; the
tooling pulls the rest on demand.

## Tools

| Name | Role | Get it |
|---|---|---|
| [**just-runit**](https://github.com/just-buildit/just-bashit/blob/main/src/just-runit) (`jb`) | Fast ephemeral script runner | `. <(curl -sSL https://just-buildit.github.io/get-jb.sh)` |
| [**just-bashit**](https://github.com/just-buildit/just-bashit) | Proven bash scripts & tools | `jbx just-bashit:logging log "hello"` |
| [**just-makeit**](https://github.com/just-buildit/just-makeit) (`jm`) | Python C extensions out-of-the-box | `jbx get-just-makeit` |
| [**just-buildit**](https://github.com/just-buildit/just-buildit) | Zero-dep PEP 517 build backend for C extensions | `jbx get-just-buildit` |

Each tool stands alone. They also compose.

## How they fit together

**Greenfield Python+C extension** — `just-makeit new` stands up a
complete project: C source, headers, CMakeLists, Python bindings, type
stubs, tests, benchmarks, and CI — all green on the first `make test`.
The build backend is `just-buildit`; the system-dep and tool manifests
(`jb-deps.toml`, `jb.toml`) are dropped in pre-populated so the next
contributor lands running. You write the algorithm; nothing else.

**Any project, anywhere** — drop a `jb-deps.toml` at the repo root and
run `jbx install-deps`. System packages for apt/pacman/brew/dnf/zypper/msys2
are detected and installed. No Python, no Docker, no setup.

**One-off scripts** — `jbx <name>` fetches, runs, and discards. Detects
bash or Python from shebang/extension; Python scripts pick up PEP 723
inline dependencies through `uv run`. Cache TTL, checksum verification,
function dispatch, sandboxed env — all there.

**Namespaces** — `jbx [NAMESPACE:]NAME`. A namespace resolves to a base
URL. The default is `just-buildit`, served from the org-pages root with
a curated `aliases.toml`. `jbx install-deps` just works; `jbx
gh:user/repo/tool` hits GitHub raw directly.

## Get started

```sh
# Get the universal entrypoint (installs jb + jbx) — only curl line you need
. <(curl -sSL https://just-buildit.github.io/get-jb.sh)

# Stand up a Python+C extension (drops jb-deps.toml + jb.toml with sane defaults)
jbx get-just-makeit
just-makeit new my_project --object engine --state gain:double:1.0
cd my_project

# Install those build deps for your platform (apt/pacman/brew/dnf/...)
jbx install-deps

# Build and test — green on first run
make && make test
```

## License

MIT across all repos.

---
---

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
- **`install-deps.sh`** — thin per-project shim that delegates to `jbx
  install-deps`. Optional — `jbx install-deps` works directly when
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
install-deps   = "https://raw.githubusercontent.com/just-buildit/just-bashit/main/src/install-deps.sh"
get-just-runit = "https://raw.githubusercontent.com/just-buildit/just-bashit/main/src/get-just-runit.sh"
# Third-party tools welcomed via PR.
```

### Resolution precedence for `jbx NAME`

1. **Explicit `NS:` prefix** — `jbx gh:user/repo/x`, `jbx https://...`:
   skip everything below, resolve directly.
2. **`[tools.NAME]` in `jb.toml`** (walking up from CWD) — use declared source.
3. **Default namespace `aliases.toml`** — fetch (cached), look up `NAME`.
4. **Default namespace direct hit** — HEAD `${NS_URL}/NAME.sh`, then `.py`.
5. **Error** — name not found.

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
- [ ] **Rename `jbs-deps.toml` → `jb-deps.toml`** across just-bashit source, docs, doppler
- [ ] **`just-makeit new` emits `jb-deps.toml` + `jb.toml`** pre-populated
- [ ] **`jb install`** — read `jb.toml`, pre-fetch every declared tool into cache
- [ ] **User namespace config** — `~/.config/just-runit/namespaces.toml` for custom NS registration

### Gaps
- [ ] **Parity `get-just-*.sh` scripts** — add `get-just-makeit.sh`, `get-just-bashit.sh`, `get-just-buildit.sh`
- [ ] **`just-buildit init [--pep517|--bare|--c]`** — unified scaffold entry point
- [ ] `jb-deps.toml` / `jb.toml` schemas — JSON Schema for editor completion
- [ ] CHANGELOG hygiene across repos is uneven

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
