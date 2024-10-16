# Compiling Kaldi to WebAssembly 

## Overview

- There is [an older guide](https://gitlab.inria.fr/multispeech/kaldi.web/kaldi-wasm/-/wikis/build_details.md) for this that compiled Kaldi with [CLAPACK](https://www.netlib.org/clapack) (not properly tested) and Netlib's Reference BLAS, which was not optimized for performance, but rather as a way for implementers of the BLAS standard to verify the correctness of their own implementation.

- This newer guide compile Kaldi using [OpenBLAS](https://github.com/OpenMathLib/OpenBLAS), a high-performance, optimized, actively maintained BLAS library officially supported by Kaldi. It also includes both BLAS and LAPACK. This was profiled to speed up Kaldi by around 20% compared to the build with Netlib's Reference BLAS and CLAPACK.

- This guide compiles Kaldi's "online decoding" target ```online2``` More info: https://kaldi-asr.org/doc/online_decoding.html

-  Compilation optimization level is -O3 by default

## Versions
- Emscripten: 3.1.69
- OpenFST: 1.8.3
- OpenBLAS: 0.3.28
- Kaldi: ???

## Step 1: Prepare
- Execute all commands in one terminal
```
# Our build root, exported so that we can refer to it in this terminal
export ROOT=$(realpath .)

# Clone this repository
git clone --depth 1 https://github.com/msqr1/kaldi-wasm2 $ROOT

# Enter that directory
cd $ROOT
```

## Step 2: Emscripten
- As of writing, Emscripten 3.1.6x is known to work
- Reference [this guide](https://emscripten.org/docs/getting_started/downloads.html) to setup Emscripten, the WASM compiler
```
# Get EMSDK
git clone https://github.com/emscripten-core/emsdk.git

# Enter that directory
cd emsdk

# Install Emscripten
./emsdk install 3.1.69

# Activate Emcripten
./emsdk activate 3.1.69

# Add Emscripten tools to current terminal
source ./emsdk_env.sh
```

## Step 3: OpenFST
```
# Go to build root
cd $ROOT

# Get OpenFST
wget https://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.8.3.tar.gz -O openfst.tgz

# Decompress
mkdir openfst
tar -xzf openfst.tgz -C openfst --strip-component 1

# Enter that directory
cd openfst

# OpenFST bug fixes
# Invalid assignment
patch -i "$ROOT"/patches/openfst/fst.h.patch ./src/include/fst/fst.h

# Undefined member variable
patch -i "$ROOT"/patches/openfst/bi-table.h.patch ./src/include/fst/bi-table.h

# Configuring static OpenFST with Ngram fsts
CXXFLAGS="-O3 -fno-rtti" emconfigure ./configure --prefix="$ROOT/openfst-build" --enable-static --disable-shared --enable-ngram-fsts --disable-bin

# Compile and install into prefix
emmake make -j$(nproc) install > /dev/null
```

## Step 4: OpenBLAS
- The most crucial step of the build, some hacks are required for this to work
```
# Go to build root
cd $ROOT

# Get OpenBLAS
git clone -b v0.3.28 --depth=1 https://github.com/OpenMathLib/OpenBLAS openblas

# Enter that directory
cd openblas

# OpenBLAS hacks
# Remove march'es, fPIC, etc.
patch -i "$ROOT"/patches/openblas/Makefile.riscv64.patch Makefile.riscv64
patch -i "$ROOT"/patches/openblas/Makefile.prebuild.patch Makefile.prebuild
patch -i "$ROOT"/patches/openblas/Makefile.system.patch Makefile.system

# Make single-threaded static OpenBLAS with just single and double precision
CC=emcc HOSTCC=clang-20 TARGET=RISCV64_GENERIC USE_THREAD=0 NO_SHARED=1 BINARY=32 BUILD_SINGLE=1 BUILD_DOUBLE=1 BUILD_BFLOAT16=0 BUILD_COMPLEX16=0 BUILD_COMPLEX=0 CFLAGS='-fno-exceptions -fno-rtti' make -j$(nproc) > /dev/null

# Install into prefix
PREFIX="$ROOT/openblas-build" NO_SHARED=1 make install
```

## Step 5: Kaldi
```
# Go to build root
cd $ROOT

# Get Kaldi
git clone --depth 1 https://github.com/kaldi-asr/kaldi

# Enter Kaldi source
cd kaldi/src

# Configuring static Kaldi with static installed dependencies
CXXFLAGS='-UHAVE_EXECINFO_H -g0 -O3 -msimd128' emconfigure ./configure --use-cuda=no --with-cudadecoder=no --static --static-math --static-fst --fst-root='$ROOT/openfst-build' --fst-version='1.8.3' --openblas-root='$ROOT/openblas-build' --host=WASM

# Compile our target
make -j$(nproc) online2 > /dev/null
```

## Step 6: Clean up
```
# Go to build root
cd $ROOT

# Clean up
rm -rf openfst.tgz openfst openblas
```

## Full command
```
export ROOT=$(realpath .)
git clone --depth 1 https://github.com/msqr1/kaldi-wasm2 $ROOT
cd $ROOT
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 3.1.69
./emsdk activate 3.1.69
source ./emsdk_env.sh
cd $ROOT
wget https://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.8.3.tar.gz -O openfst.tgz
mkdir openfst
tar -xzf openfst.tgz -C openfst --strip-component 1
cd openfst
patch -i "$ROOT"/patches/openfst/fst.h.patch ./src/include/fst/fst.h
patch -i "$ROOT"/patches/openfst/bi-table.h.patch ./src/include/fst/bi-table.h
CXXFLAGS="-O3 -fno-rtti" emconfigure ./configure --prefix="$ROOT/openfst-build" --enable-static --disable-shared --enable-ngram-fsts --disable-bin
emmake make -j$(nproc) install > /dev/null
cd $ROOT
git clone -b v0.3.28 --depth=1 https://github.com/OpenMathLib/OpenBLAS openblas
cd openblas
patch -i "$ROOT"/patches/openblas/Makefile.riscv64.patch Makefile.riscv64
patch -i "$ROOT"/patches/openblas/Makefile.prebuild.patch Makefile.prebuild
patch -i "$ROOT"/patches/openblas/Makefile.system.patch Makefile.system
CC=emcc HOSTCC=clang-20 TARGET=RISCV64_GENERIC USE_THREAD=0 NO_SHARED=1 BINARY=32 BUILD_SINGLE=1 BUILD_DOUBLE=1 BUILD_BFLOAT16=0 BUILD_COMPLEX16=0 BUILD_COMPLEX=0 CFLAGS='-fno-exceptions -fno-rtti' make -j$(nproc) > /dev/null
PREFIX="$ROOT/openblas-build" NO_SHARED=1 make install
cd $ROOT
git clone --depth 1 https://github.com/kaldi-asr/kaldi
cd kaldi/src
CXXFLAGS='-UHAVE_EXECINFO_H -g0 -O3 -msimd128' emconfigure ./configure --use-cuda=no --with-cudadecoder=no --static --static-math --static-fst --fst-root='$ROOT/openfst-build' --fst-version='1.8.3' --openblas-root='$ROOT/openblas-build' --host=WASM
make -j$(nproc) online2 > /dev/null
cd $ROOT
rm -rf openfst.tgz openfst openblas
```

## Bonus