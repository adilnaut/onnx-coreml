#!/bin/bash

set -ex

# realpath might not be available on MacOS
script_path=$(python -c "import os; import sys; print(os.path.realpath(sys.argv[1]))" "${BASH_SOURCE[0]}")
top_dir=$(dirname "$script_path")
REPOS_DIR="$top_dir/third_party"
BUILD_DIR="$top_dir/build"

_check_submodule_present() {
    if [ ! -f "$REPOS_DIR/$@/setup.py" ]; then
       echo Didn\'t find $@ submodule. Please run: git submodule update --recursive --init
        exit 1
    fi
}

_check_submodule_present onnx

_check_compilers_use_ccache() {
    COMPILERS_WITHOUT_CCACHE=""
    for compiler in gcc g++ cc c++; do
        if ! readlink $(which $compiler) | grep ccache; then
            COMPILERS_WITHOUT_CCACHE="$COMPILERS_WITHOUT_CCACHE $compiler"
        fi
    done

    if [ "$COMPILERS_WITHOUT_CCACHE" != "" ]; then
        echo Warning: Compilers not set up for ccache: $COMPILERS_WITHOUT_CCACHE. Incremental builds will be slow.
    fi
}
_check_compilers_use_ccache


mkdir -p "$BUILD_DIR"

_pip_install() {
    if [[ -n "$CI" ]]; then
        ccache -z
    fi
    if [[ -n "$CI" ]]; then
        time pip install "$@" --no-binary :all:
    else
        pip install "$@" --no-binary :all:
    fi
    if [[ -n "$CI" ]]; then
        ccache -s
    fi
}

# Install onnx
_pip_install -b "$BUILD_DIR/onnx" "file://$REPOS_DIR/onnx#egg=onnx"

# Install onnx-coreml
_pip_install .
