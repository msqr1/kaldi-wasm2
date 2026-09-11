include_guard(GLOBAL)
include("Util.cmake")
include("Emscripten.cmake")

set(arFile Abseil.tgz)
set(sha 2065f4ded0558c6f89fee67c8e5228feb4eb960e)
file(DOWNLOAD
  "https://github.com/abseil/abseil-cpp/archive/${sha}.tar.gz"
  "${arFile}"
)
file(ARCHIVE_EXTRACT INPUT "${arFile}" DESTINATION .)
exec("${emDir}/emcmake" "${CMAKE_COMMAND}"
  -DABSL_ENABLE_INSTALL=on
  -DCMAKE_BUILD_TYPE=Release
  "-DCMAKE_CXX_FLAGS=${emFlags}"
  -S "${topDir}/abseil-cpp-${sha}"
  -B "${topDir}/abseil-build"
  -G Ninja
)
exec("${CMAKE_COMMAND}" --build "${topDir}/abseil-build")
exec("${CMAKE_COMMAND}"
  --install "${topDir}/abseil-build"
  --prefix "${topDir}/abseil"
)
