# Compiling Kaldi to WebAssembly 

## Overview

- There is [an older guide](https://gitlab.inria.fr/multispeech/kaldi.web/kaldi-wasm/-/wikis/build_details.md) for this that compiled Kaldi with [CLAPACK](https://www.netlib.org/clapack) (not properly tested) and [Netlib's Reference BLAS](https://www.netlib.org/blas), which exists solely for implementers of the BLAS standard to verify the correctness of their own implementation, and thus, not optimized for performance.

- This newer guide compile Kaldi using [OpenBLAS](https://github.com/OpenMathLib/OpenBLAS), a high-performance, optimized, actively maintained BLAS library officially supported by Kaldi. It also includes both BLAS and LAPACK. This was profiled to speed up Kaldi by around 20% compared to the build with Netlib's Reference BLAS and CLAPACK.

- This guide compiles Kaldi's "online decoding" target ```online2``` More info: https://kaldi-asr.org/doc/online_decoding.html

## Versions
- Emscripten: 3.1.69
- OpenFST: 1.8.3
- OpenBLAS: 0.3.28
- Kaldi: ???

## Step 1: Prepare
- Execute all commands in one terminal
- Make a directory and change into it before starting
- Compilation optimization level is -O3 by default througout this guide
```
# Our build root, exported so that we can refer to it in this terminal
export ROOT="$PWD"

# Clone this repository
git clone --depth 1 https://github.com/msqr1/kaldi-wasm2 "$ROOT"

# Enter that directory
cd "$ROOT"
```
- **Optional**: WASM-specific compilation flags that can boost performance, selected by me with careful condsideration on browser support:
  - Chrome ≥ 75 (2019)
  - Firefox ≥ 79 (2020)
  - Safari ≥ 15 (2021)
  - Edge ≥ 79 (2020)
- [Wasm features support table](https://webassembly.org/features/) 
- [Wasm flags list](https://clang.llvm.org/docs/ClangCommandLineReference.html#webassembly)
```
export WAFLAGS="-mbulk-memory -mnontrapping-fptoint -mmutable-globals -msign-ext"
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
cd "$ROOT"

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
CXXFLAGS="$WAFLAGS -O3 -fno-rtti" emconfigure ./configure --prefix="$ROOT/openfst-build" --enable-static --disable-shared --enable-ngram-fsts --disable-bin

# Compile and install into prefix
emmake make -j$(nproc) install > /dev/null
```

## Step 4: OpenBLAS
- The most crucial step of the build, some hacks are required for this to work
```
# Go to build root
cd "$ROOT"

# Get OpenBLAS
git clone -b v0.3.28 --depth=1 https://github.com/OpenMathLib/OpenBLAS openblas

# Enter that directory
cd openblas

# OpenBLAS hacks: remove march'es, fPIC, etc.
patch -i "$ROOT"/patches/openblas/Makefile.riscv64.patch Makefile.riscv64
patch -i "$ROOT"/patches/openblas/Makefile.prebuild.patch Makefile.prebuild
patch -i "$ROOT"/patches/openblas/Makefile.system.patch Makefile.system

# Make single-threaded static OpenBLAS with just single and double precision
# Change HOSTCC to the C compiler on your machine. Mine is gcc-12 from Debian 12
CC=emcc HOSTCC=gcc-12 TARGET=RISCV64_GENERIC USE_THREAD=0 NO_SHARED=1 BINARY=32 BUILD_SINGLE=1 BUILD_DOUBLE=1 BUILD_BFLOAT16=0 BUILD_COMPLEX16=0 BUILD_COMPLEX=0 CFLAGS="$WAFLAGS -fno-exceptions -fno-rtti" make -j$(nproc) > /dev/null

# Install into prefix
PREFIX="$ROOT/openblas-build" NO_SHARED=1 make install
```

## Step 5: Kaldi
```
# Go to build root
cd "$ROOT"

# Get Kaldi
git clone --depth 1 https://github.com/msqr1/new-kaldi-wasm

# Enter Kaldi source
cd kaldi/src

# Configuring static Kaldi with static installed dependencies
CXXFLAGS="$WAFLAGS -UHAVE_EXECINFO_H -g0 -O3 -msimd128" emconfigure ./configure --use-cuda=no --with-cudadecoder=no --static --static-math --static-fst --fst-root="$ROOT/openfst-build" --fst-version='1.8.3' --openblas-root="$ROOT/openblas-build" --host=WASM

# Compile our target
make -j$(nproc) online2 > /dev/null
```

## Step 6: Clean up
```
# Go to build root
cd "$ROOT"

# Clean up
rm -rf openfst.tgz openfst openblas
```

## Full command
```
export ROOT="$PWD"
git clone --depth 1 https://github.com/msqr1/kaldi-wasm2 "$ROOT"
cd "$ROOT"
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 3.1.69
./emsdk activate 3.1.69
source emsdk_env.sh
cd "$ROOT"
export WAFLAGS="-mbulk-memory -mnontrapping-fptoint -mmutable-globals -msign-ext"
wget https://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.8.3.tar.gz -O openfst.tgz
mkdir openfst
tar -xzf openfst.tgz -C openfst --strip-component 1
cd openfst
patch -i "$ROOT"/patches/openfst/fst.h.patch ./src/include/fst/fst.h
patch -i "$ROOT"/patches/openfst/bi-table.h.patch ./src/include/fst/bi-table.h
CXXFLAGS="$WAFLAGS -O3 -fno-rtti" emconfigure ./configure --prefix="$ROOT/openfst-build" --enable-static --disable-shared --enable-ngram-fsts --disable-bin
emmake make -j$(nproc) install > /dev/null
cd "$ROOT"
git clone -b v0.3.28 --depth=1 https://github.com/OpenMathLib/OpenBLAS openblas
cd openblas
patch -i "$ROOT"/patches/openblas/Makefile.riscv64.patch Makefile.riscv64
patch -i "$ROOT"/patches/openblas/Makefile.prebuild.patch Makefile.prebuild
patch -i "$ROOT"/patches/openblas/Makefile.system.patch Makefile.system
CC=emcc HOSTCC=gcc-12 TARGET=RISCV64_GENERIC USE_THREAD=0 NO_SHARED=1 BINARY=32 BUILD_SINGLE=1 BUILD_DOUBLE=1 BUILD_BFLOAT16=0 BUILD_COMPLEX16=0 BUILD_COMPLEX=0 CFLAGS="$WAFLAGS -fno-exceptions -fno-rtti" make -j$(nproc) > /dev/null
PREFIX="$ROOT/openblas-build" NO_SHARED=1 make install
cd "$ROOT"
git clone --depth 1 https://github.com/msqr1/new-kaldi-wasm kaldi
cd kaldi/src
CXXFLAGS="$WAFLAGS -UHAVE_EXECINFO_H -g0 -O3 -msimd128" emconfigure ./configure --use-cuda=no --with-cudadecoder=no --static --static-math --static-fst --fst-root="$ROOT/openfst-build" --fst-version='1.8.3' --openblas-root="$ROOT/openblas-build" --host=WASM
make -j$(nproc) online2 > /dev/null
cd "$ROOT"
rm -rf openfst.tgz openfst openblas
```
# Linking and running example
- We're going to run ```nnet2/am-nnet-test.cc```
```
# Compiler flags
export CXXFLAGS="
-DOPENFST_VER=10803
-I$ROOT/kaldi/src
-I$ROOT/openfst-build/include
-I$ROOT/openblas-build/include"

# Linker flags
export LDFLAGS="
-L$ROOT/kaldi/src 
-l:online2/kaldi-online2.a        -l:decoder/kaldi-decoder.a
-l:ivector/kaldi-ivector.a        -l:gmm/kaldi-gmm.a
-l:tree/kaldi-tree.a              -l:feat/kaldi-feat.a
-l:cudamatrix/kaldi-cudamatrix.a  -l:lat/kaldi-lat.a
-l:hmm/kaldi-hmm.a                -l:nnet3/kaldi-nnet3.a
-l:transform/kaldi-transform.a    -l:matrix/kaldi-matrix.a
-l:fstext/kaldi-fstext.a          -l:util/kaldi-util.a
-l:base/kaldi-base.a              -l:nnet2/kaldi-nnet2.a
-L$ROOT/openfst-build/lib         -l:libfst.a 
-L$ROOT/openblas-build/lib        -l:libopenblas.a"

# Go to build root
cd "$ROOT"

# Generate .html, .js, and .wasm
em++ $WAFLAGS -O3 $CXXFLAGS $LDFLAGS kaldi/src/nnet2/am-nnet-test.cc -o index.html
```
- Open the ```index.html``` in a browser, check the console for logs from the test.