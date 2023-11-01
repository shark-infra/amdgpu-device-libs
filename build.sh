#!/bin/bash
# This script uses an IREE build directory, which has been configured
# with an AMDGPU compiler backend to build standalone device libraries
# with the LLVM tools in the IREE build.
set -euo pipefail

TD="$(cd $(dirname $0) && pwd)"
IREE_SOURCE_DIR="$(cd ${IREE_SOURCE_DIR:-$TD/../iree} && pwd)"
IREE_BUILD_DIR="$(cd ${IREE_BUILD_DIR:-$TD/../iree-build} && pwd)"

DEVICE_LIBS=("amdgcn/bitcode/opencl.bc amdgcn/bitcode/ocml.bc amdgcn/bitcode/ockl.bc")

echo "Using IREE source directory: $IREE_SOURCE_DIR"
LLVM_COMMIT="$(cd $IREE_SOURCE_DIR && git submodule status third_party/llvm-project | awk '{print $1}')"
echo "Building against LLVM: $LLVM_COMMIT"

echo "Using IREE build directory: $IREE_BUILD_DIR"
echo "Building required tools..."
(cd $IREE_BUILD_DIR &&
    ninja \
        llvm-project/bin/opt \
        llvm-project/bin/clang \
        llvm-project/bin/llvm-link
)

echo "Configuring CMake project..."
cmake -GNinja \
    -S $TD/third_party/ROCm-Device-Libs \
    -B $TD/build \
    -DLLVM_ROOT=$IREE_BUILD_DIR/llvm-project/lib/cmake/llvm \
    -DClang_ROOT=$IREE_BUILD_DIR/lib/cmake/clang

echo "Building..."
(cd $TD/build && ninja)

echo "Packaging..."
STAGE_DIR="$TD/build/stage"
rm -Rf $STAGE_DIR
mkdir -p $STAGE_DIR
for BC_SRC_FILE in ${DEVICE_LIBS[@]}; do
    BC_SRC_FILE="$TD/build/$BC_SRC_FILE"
    BC_DST_FILE="$STAGE_DIR/$(basename $BC_SRC_FILE)"
    echo "Copy $BC_SRC_FILE -> $BC_DST_FILE"
    if [ -f "$BC_DST_FILE" ]; then
        echo "Destination file exists"
        exit 1
    fi
    cp $BC_SRC_FILE $BC_DST_FILE
done

ZIP_FILE="$TD/build/amdgpu-device-libs-llvm-${LLVM_COMMIT}.zip"
rm -f "$ZIP_FILE"
(cd $STAGE_DIR && zip $ZIP_FILE *)
echo "Saved zip file to $ZIP_FILE"
