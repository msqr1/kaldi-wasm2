# Compiling Kaldi to WebAssembly 

## Overview

- There is [an older guide](https://gitlab.inria.fr/multispeech/kaldi.web/kaldi-wasm/-/wikis/build_details.md) for this that compiled Kaldi with [CLAPACK](https://www.netlib.org/clapack) (not properly tested) and Netlib's Reference BLAS, which was not optimized for performance, but rather as a way for implementers of the BLAS standard to verify the correctness of their own implementation.

- This newer guide compile Kaldi using [OpenBLAS](https://github.com/OpenMathLib/OpenBLAS), a high-performance, optimized, actively maintained BLAS library officially supported by Kaldi. It also includes both BLAS and LAPACK. This was profiled to speed up Kaldi by around 20% compared to the build with Netlib's Reference BLAS and CLAPACK.

- This guide compiles Kaldi's "online decoding" target ```online2``` More info: https://kaldi-asr.org/doc/online_decoding.html

- For simplicity's sake:

    -  Everything will be installed in the same folder with the path ```~/kaldi-wasm2```
    
    mkdir ~/kaldi-wasm2
    cd ~/kaldi-wasm2

    -  Compilation optimization level is -O3

## Versions
- Emscripten: 3.1.69
- OpenFST: 1.8.3
- OpenBLAS: 0.3.28
- Kaldi: ???

## Step 1: Emscripten

- As of writing, Emscripten 3.1.6x is known to work

- Reference [this guide](https://emscripten.org/docs/getting_started/downloads.html) to setup Emscripten, the WASM compiler`

```
git clone https://github.com/emscripten-core/emsdk.git
source ./emsdk_env.sh

```



## Step 2: OpenFST

```
cd ~/kaldi-wasm2
wget https://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.8.3.tar.gz
tar -xzf openfst-1.8.3.tar.gz
cd openfst-1.8.3
echo '690,691c690,691
<     isymbols_ = impl.isymbols_ ? impl.isymbols_->Copy() : nullptr;
<     osymbols_ = impl.osymbols_ ? impl.osymbols_->Copy() : nullptr;
---
>     isymbols_.reset(impl.isymbols_ ? impl.isymbols_->Copy() : nullptr);
>     osymbols_.reset(impl.osymbols_ ? impl.osymbols_->Copy() : nullptr);
" > /tmp/patch
patch -i /tmp/patch ./src/include/fst/fst.h
echo "690,691c690,691
<     isymbols_ = impl.isymbols_ ? impl.isymbols_->Copy() : nullptr;
<     osymbols_ = impl.osymbols_ ? impl.osymbols_->Copy() : nullptr;
---
>     isymbols_.reset(impl.isymbols_ ? impl.isymbols_->Copy() : nullptr);
>     osymbols_.reset(impl.osymbols_ ? impl.osymbols_->Copy() : nullptr);
' > /tmp/patch
patch -i /tmp/patch ./src/include/fst/fst.h
echo '333c333
<       : selector_(table.s_),
---
>       : selector_(table.selector_),'
patch -i /tmp/patch ./src/include/fst/bi-table.h

CXXFLAGS="-O3 -fno-rtti" emconfigure ./configure --prefix="~/kaldi-wasm2/openfst-build" --enable-static --disable-shared --enable-ngram-fsts --disable-bin


```



## Step 3: OpenBLAS

- The most crucial step of the build, some hacks are required for this to work

```

git clone

```



## Step 4: Kaldi

```




Show drafts


