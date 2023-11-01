# amdgpu-device-libs
Device library build repository for AMD GPU.

In order to keep build complexity of IREE down, we build AMDGPU device
library bitcode out of tree and include it as binaries by default. This
repository contains the scripts to do this build and it hosts the
release artifacts.

## Building

This assumes that you have an IREE source directory at `../iree` and a
build dir at `../iree-build`. If not the case, set `IREE_SOURCE_DIR` and
`IREE_BUILD_DIR` env vars. IREE must have been built with the `ninja`
generator and support for AMDGPU in its LLVM (typically by enabling
the corresponding HAL target backend).

Run:

```
git submodule update --init
./build.sh
```

This will save a zip file of bitcode binaries like `build/amdgpu-device-libs-llvm-6aaa03a0232b89682e0745433bdfb4d785f64a01.zip` where
the commit hash is the hash of the LLVM which produced them.

## Releasing

We just use GH releases to host artifacts. Go to the website and create a
new release. Upload the zip file to it.
