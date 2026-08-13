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

| Name                                                                                                       | Role                                            | Get it                                                    | Status                                                                                                                                                                                                                                                        |
| ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**just-runit**](https://github.com/just-buildit/just-bashit/blob/main/src/just_bashit/just-runit) (`jbx`) | Fast ephemeral script runner                    | `. <(curl -sSL https://just-buildit.github.io/get-jb.sh)` | [![CI](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml)                                                                                                 |
| [**just-bashit**](https://github.com/just-buildit/just-bashit)                                             | Proven bash scripts & tools                     | `jbx just-bashit:logging log "hello"`                     | [![CI](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-bashit/actions/workflows/ci.yml)                                                                                                 |
| [**just-makeit**](https://github.com/just-buildit/just-makeit) (`jm`)                                      | Python C extensions out-of-the-box              | `pip install just-makeit`                                 | [![PyPI](https://img.shields.io/pypi/v/just-makeit)](https://pypi.org/project/just-makeit/) [![CI](https://github.com/just-buildit/just-makeit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-makeit/actions/workflows/ci.yml)     |
| [**just-buildit**](https://github.com/just-buildit/just-buildit)                                           | Zero-dep PEP 517 build backend for C extensions | `pip install just-buildit`                                | [![PyPI](https://img.shields.io/pypi/v/just-buildit)](https://pypi.org/project/just-buildit/) [![CI](https://github.com/just-buildit/just-buildit/actions/workflows/ci.yml/badge.svg)](https://github.com/just-buildit/just-buildit/actions/workflows/ci.yml) |

Each tool stands alone. They also compose.

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
# Get the universal entrypoint (installs just-runit + jbx) — only curl line you need
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
