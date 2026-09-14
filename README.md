[![Native Multi-Arch Build](https://github.com/riscv/riscv-docs-base-container-image/actions/workflows/native-multiarch-build.yaml/badge.svg)](https://github.com/riscv/riscv-docs-base-container-image/actions/workflows/native-multiarch-build.yaml)

# RISC-V Base Container Images for Building Documentation

Container images with everything needed to build RISC-V specifications written in AsciiDoc (PDF, HTML, EPUB and normative rule files), such as the [RISC-V ISA manual](https://github.com/riscv/riscv-isa-manual). They are built with Docker in mind, but any OCI container runtime (for example Podman) works.

## Images

Images are published to the GitHub Container Registry as multi-arch images for **linux/amd64** and **linux/arm64**, so they run natively on x86 machines, Apple silicon and Arm servers.

| Tag          | Base                   | Contents                                                               |
| ------------ | ---------------------- | ---------------------------------------------------------------------- |
| **`latest`** | Ubuntu 22.04           | Full toolchain, including TeX Live with extra fonts and LaTeX packages |
| **`small`**  | Debian bookworm (slim) | Same toolchain, with a smaller TeX Live selection                      |

Every published image also gets tags you can pin to:

| Tag                     | Example                 | Use                                                         |
| ----------------------- | ----------------------- | ----------------------------------------------------------- |
| `<variant>-<date>`      | `ubuntu2204-2026-09-14` | The image published on a given day                          |
| `<variant>-<short-sha>` | `ubuntu2204-f3fc241`    | The image built from a given commit of this repository      |
| `native-<variant>`      | `native-ubuntu2204`     | Transitional alias of `latest` / `small`                    |
| `pr-<number>-<variant>` | `pr-23-ubuntu2204`      | Preview built from a pull request, for testing before merge |

`<variant>` is `ubuntu2204` (the `latest` image) or `debian` (the `small` image).

```bash
docker pull ghcr.io/riscv/riscv-docs-base-container-image:latest
```

## What is inside

| Area     | Tools                                                                                                                                                                                                       |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AsciiDoc | `asciidoctor`, `asciidoctor-pdf`, `asciidoctor-epub3`, `asciidoctor-bibtex`, `asciidoctor-lists`, `asciidoctor-sail`, `asciidoctor-kroki`, `citeproc-ruby`, `csl-styles`, `rouge`, `coderay`, `pygments.rb` |
| Diagrams | `asciidoctor-diagram` with WaveDrom (`wavedrom-cli`), bytefield (`bytefield-svg`), Graphviz, PlantUML and ditaa                                                                                             |
| Math     | `asciidoctor-mathematical` and `mathematical`, linked against lasem 0.4.3 built from source                                                                                                                 |
| Other    | Pandoc, Ghostscript, TeX Live, Java runtime, Node.js, Python 3 (`sympy`, `pyyaml`, `jsonschema`), Git, Make, CMake                                                                                          |

Some versions are pinned on purpose. The comments in the [Dockerfiles](Dockerfiles/) explain why, for example `json` is kept at 2.x because asciidoctor-diagram does not work with json 3.0.

## Building documentation with the image

### From a specification repository

Most RISC-V specification repositories, including the ISA manual, have a Makefile that runs the build inside this image. With Docker installed:

```bash
git clone --recurse-submodules https://github.com/riscv/riscv-isa-manual.git
cd riscv-isa-manual
make
```

The outputs are written to `build/`:

```text
build/
├── norm-rules.html
├── norm-rules.json
├── riscv-spec-norm-tags.json
├── riscv-spec.epub
├── riscv-spec.html
└── riscv-spec.pdf
```

To build with a different image, for example a pinned date tag or a pull request preview, override `DOCKER_IMG`:

```bash
make DOCKER_IMG=ghcr.io/riscv/riscv-docs-base-container-image:ubuntu2204-2026-09-14
```

### From a shell inside the container

```bash
cd riscv-isa-manual
docker run -it --rm -v "$(pwd)":/build ghcr.io/riscv/riscv-docs-base-container-image:latest /bin/bash

# inside the container
# asciidoctor-epub3 needs a UTF-8 locale to parse its SCSS files
export LANG=C.utf8
make
```

Inside the container there is no `docker` command, so the Makefile runs the tools directly.

## How the images are built and published

The [Native Multi-Arch Build](.github/workflows/native-multiarch-build.yaml) workflow builds both variants on native amd64 and arm64 runners, in parallel, using a registry layer cache. Each image must pass two tests before anything is published:

1. **Smoke test** ([`tests/smoke`](tests/smoke/)): renders a document with math, bytefield, WaveDrom, Graphviz, PlantUML and ditaa to PDF and then HTML.
2. **ISA manual build**: builds the full [riscv-isa-manual](https://github.com/riscv/riscv-isa-manual) (`main`) with the image, the same way its own CI does, and checks that all six output files are produced.

| Trigger                                                                 | Result                                                                                |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Push to `main` changing the Dockerfiles, the smoke test or the workflow | Publishes `latest` and `small` (plus the date, commit and `native-*` tags)            |
| Weekly, Monday 00:00 UTC                                                | Rebuilds to pick up upstream package updates, publishes, and creates a GitHub Release |
| Manual run with **publish** enabled                                     | Same as the weekly run                                                                |
| Pull request from a branch of this repository                           | Builds, tests and publishes `pr-<number>-<variant>` preview tags only                 |
| Pull request from a fork                                                | Builds and tests only                                                                 |

`latest` and `small` never move unless both tests pass on both architectures.

### Rolling back

Every release keeps its `<variant>-<date>` and `<variant>-<short-sha>` tags, so an earlier image can be restored by pointing the tag back at it:

```bash
docker buildx imagetools create \
  -t ghcr.io/riscv/riscv-docs-base-container-image:latest \
  ghcr.io/riscv/riscv-docs-base-container-image:ubuntu2204-2026-09-14
```

## Building the images locally

```bash
git clone https://github.com/riscv/riscv-docs-base-container-image.git
cd riscv-docs-base-container-image

# Ubuntu 22.04 (latest)
docker build -t riscv-docs-base:ubuntu2204 -f Dockerfiles/ubuntu2204 .

# Debian bookworm (small)
docker build -t riscv-docs-base:debian -f Dockerfiles/debian .
```

The Dockerfiles are multi-stage: a builder stage compiles lasem and the native Ruby gems, and the final stage contains only the runtime packages and the built tools. To build for the other architecture, add `--platform linux/amd64` or `--platform linux/arm64` (this uses emulation and is much slower than a native build).

Run the smoke test against your image:

```bash
tests/smoke/run.sh riscv-docs-base:ubuntu2204
```

It ends with `smoke-ok: PDF and HTML rendered` when it passes.

## Contributing

1. Change the Dockerfiles in [`Dockerfiles/`](Dockerfiles/). Keep `ubuntu2204` and `debian` in sync unless a difference is intended.
2. Build locally and run the smoke test.
3. Open a pull request. CI builds both variants on both architectures, runs the smoke test and the ISA manual build, and (for branches of this repository) publishes `pr-<number>-<variant>` images you can pull and test with your own specification repository.

Commits must be signed and include a DCO `Signed-off-by:` line.
