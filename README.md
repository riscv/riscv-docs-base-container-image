[![Weekly Build and Release](https://github.com/riscv/riscv-docs-base-container-image/actions/workflows/weekly_build.yaml/badge.svg)](https://github.com/riscv/riscv-docs-base-container-image/actions/workflows/weekly_build.yaml)

# RISC-V Base Container Images for Building Documentation

This is the source code for putting together a base container image populated with the dependencies to build the RISC-V Documentation. It was built with Docker in mind given its popularity, but you should be able to execute it with other container runtimes.

> **The current version builds the base container image based on Ubuntu 22.04.**

## Requirements

### Install Docker

Docker provides straightforward steps to install it on Linux, MacOS and Windows. You can find the installation steps [here](https://docs.docker.com/engine/install/).

## Building the Base Container Image

### Getting the Source Code

First clone the source code from the upstream repository:

```bash
git clone https://github.com/riscv/riscv-docs-base-container-image.git
```

### Building the Base Image

Once cloned, jump into the source-code directory and build the base container image.

```bash
cd ./riscv-docs-base-container-image
docker build -t riscv-docs-base-container-image -f ./Dockerfiles/ubuntu2204 .
```

## Building the Docs

### Using a pre-built container image

If if want to save time, you can easily [pull the latest image built from Docker Hub](https://hub.docker.com/repository/docker/riscvintl/riscv-docs-base-container-image/general) and skip the image building process. This is a multi-arch image (available for x86_64 and arm - so you can run on Apple silicon for instance). Execute the following step to complete this task:

> NOTE: this step assumes you already have Docker installed and configured.

```bash
docker pull docker.io/riscvintl/riscv-docs-base-container-image:latest
```

### Building the Documentation within the container directly

To build the documentation, execute the following steps:

> NOTE: this step assumes you have already built or have pulled the base image following the steps aforementioned.

```bash
# run the build within the container from within the riscv-isa-manual directory
docker run -it -v $(pwd)/riscv-isa-manual:/build riscvintl/riscv-docs-base-container-image:latest /bin/sh -c 'cd ./build; make'
```

The build artifacts will be located within the `riscv-isa-manual` in the `build` directory, for instance:

```bash
$ ls ./riscv-isa-manual/build/ 

.
|-- Makefile
|-- riscv-privileged.aux
|-- riscv-privileged.bbl
|-- riscv-privileged.blg
|-- riscv-privileged.log
|-- riscv-privileged.out
|-- riscv-privileged.pdf
|-- riscv-privileged.toc
|-- riscv-spec.aux
|-- riscv-spec.bbl
|-- riscv-spec.blg
|-- riscv-spec.log
|-- riscv-spec.out
|-- riscv-spec.pdf
|-- riscv-spec.toc

```

or

```bash
$ ls ./riscv-isa-manual/build/
.
├── Makefile
├── images
└── unpriv-isa-asciidoc.pdf
```

### Building the Documentation within the container using its bash terminal

To build the documentation, execute the following steps:

> NOTE: this step assumes you have already built or have pulled the base image following the steps aforementioned.

```bash
# clone the upstream repository of the documentation (see The Branches)

# run the container from within the riscv-isa-manual directory
docker run -it -v $(pwd)/riscv-isa-manual:/build riscvintl/riscv-docs-base-container-image:latest /bin/bash

# within the container
cd ./build
make
```

Once done, you can exit from the container with `exit` or leave it running and get back to the host with `ctrl p + ctrl q`. The build artifacts will be located within the `riscv-isa-manual`, in the `build` directory as shown in the previous step.
