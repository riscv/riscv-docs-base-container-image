#!/bin/sh
# Renders smoke.adoc to PDF and then HTML inside the docs base image.
# Usage: tests/smoke/run.sh <image> [platform]
set -eu

image="$1"
platform="${2:-}"
root="$(cd "$(dirname "$0")" && pwd)"

set -- --rm -v "$root:/work" -w /work
if [ -n "$platform" ]; then
    set -- "$@" --platform "$platform"
fi

docker run "$@" "$image" /bin/sh -euc '
    rm -rf build .asciidoctor
    opts="--failure-level=WARN -a mathematical-format=svg -a imagesoutdir=build -r asciidoctor-diagram -r asciidoctor-mathematical -D build"
    ruby -e "require \"json\"; puts \"json #{JSON::VERSION}\""
    asciidoctor-pdf $opts smoke.adoc
    asciidoctor $opts smoke.adoc
    test -s build/smoke.pdf
    test -s build/smoke.html
    echo "smoke-ok: PDF and HTML rendered"
'
