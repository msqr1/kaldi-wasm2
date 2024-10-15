# Compiling Kaldi to WebAssembly 



### Overview

- There is [an older guide](https://gitlab.inria.fr/multispeech/kaldi.web/kaldi-wasm/-/wikis/build_details.md) for this that compiled Kaldi with [CLAPACK](https://www.netlib.org/clapack) (not properly tested) and Netlib's Reference BLAS, which was not optimized for performance, but rather as a way for implementers of the BLAS standard to verify the correctness of their own implementation. 



- This newer guide compile Kaldi using [OpenBLAS](https://github.com/OpenMathLib/OpenBLAS), a high-performance, optimized, actively maintained BLAS library officially supported by Kaldi. It also includes both BLAS and LAPACK. This was profiled to speed up Kaldi by around 20% compared to the build with Netlib's Reference BLAS and CLAPACK.



- This guide compiles Kaldi's "online decoding" target ```online2``` More info: https://kaldi-asr.org/doc/online_decoding.html



- For simplicity's sake:

    -  Everything will be installed in the same folder called ```BUILD_DIR```

    -  Compilation optimization level is -O3



### Step 1: Emscripten

- As of writing, Emscripten 3.1.6x is known to work

- Follow [this guide](https://emscripten.org/docs/getting_started/downloads.html) to download and install Emscripten, the WASM compiler into ```BUILD_DIR```

- Place Emscripten tools into PATH for current terminal

```

cd BUILD_DIR/emsdk &&

source ./emsdk_env.sh

```



### Step 2: OpenFST

```



```



### Step 3: OpenBLAS

- The most crucial step of the build

```

git clone

```



### Step 4: Kaldi

```




Show drafts


