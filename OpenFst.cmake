include_guard(GLOBAL)
include("Util.cmake")
include("Emscripten.cmake")

set(arFile OpenFst.tgz)
set(sha 02ef9b32eced889358cdb99b33049629b0f272d3)
file(DOWNLOAD
  "https://github.com/google-research/openfst/archive/${sha}.tar.gz"
  "${arFile}"
)
file(ARCHIVE_EXTRACT INPUT "${arFile}" DESTINATION .)
exec("${emDir}/emcmake" "${CMAKE_COMMAND}"
  -DOPENFST_ENABLE_BIN=off
  -DOPENFST_BUILD_TESTS=off
  -DOPENFST_ENABLE_INSTALL=on
  -DOPENFST_USE_SYSTEM_ABSEIL=on
  "-Dabsl_DIR=${topDir}/abseil/lib/cmake/absl"
  -DCMAKE_BUILD_TYPE=Release
  "-DCMAKE_CXX_FLAGS=${emFlags} -Wno-pedantic"
  -S "${topDir}/openfst-${sha}"
  -B "${topDir}/openfst-build"
  -G Ninja
)
exec("${CMAKE_COMMAND}" --build "${topDir}/openfst-build")
exec("${CMAKE_COMMAND}"
  --install "${topDir}/openfst-build"
  --prefix "${topDir}/openfst"
)

# Linking so Kaldi can use new OpenFST structure
file(CREATE_LINK
  "${topDir}/openfst/include/openfst/lib"
  "${topDir}/openfst/include/fst"
  SYMBOLIC
)
file(CREATE_LINK
  "${topDir}/openfst/include/openfst/script"
  "${topDir}/openfst/include/openfst/lib/script"
  SYMBOLIC
)
