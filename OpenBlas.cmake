include_guard(GLOBAL)
include("Util.cmake")
include("Emscripten.cmake")

set(arFile OpenBlas.tgz)
set(sha 3a98ec8feabb97e067df07de9aee4301b920e6f3)
file(DOWNLOAD
  "https://github.com/OpenMathLib/OpenBLAS/archive/${sha}.tar.gz"
  "${arFile}"
)
file(ARCHIVE_EXTRACT INPUT "${arFile}" DESTINATION .)
exec("${emDir}/emcmake" "${CMAKE_COMMAND}"
  -DCMAKE_BUILD_TYPE=Release
  -DC_LAPACK=on
  -DBUILD_TESTING=off
  -DBUILD_SINGLE=on
  -DBUILD_DOUBLE=on
  -DBUILD_COMPLEX=off
  -DBUILD_COMPLEX16=off
  -DUSE_THREAD=off
  -DTARGET=WASM128_GENERIC
  "-DCMAKE_C_FLAGS=${emFlags} -Wno-unused-function"
  -S "${topDir}/OpenBLAS-${sha}"
  -B "${topDir}/openblas-build"
  -G Ninja
)
exec("${CMAKE_COMMAND}" --build "${topDir}/openblas-build")
exec("${CMAKE_COMMAND}"
  --install "${topDir}/openblas-build"
  --prefix "${topDir}/openblas"
)
