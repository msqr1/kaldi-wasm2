include_guard(GLOBAL)
include("Util.cmake")
include("Emscripten.cmake")

set(arFile Kaldi.tgz)
set(sha e02e35f0254bb033fab73d1df99fc34123e31d56)
#file(DOWNLOAD
#  "https://github.com/kaldi-asr/kaldi/archive/${sha}.tar.gz"
#  "${arFile}"
#)
#file(ARCHIVE_EXTRACT INPUT "${arFile}" DESTINATION .)
# Kaldi's CMake support is nonexistent, so must use Makefile
set(ENV{CXXFLAGS} "${emFlags} -I${topDir}/abseil/include -UHAVE_EXECINFO_H -O3 -DNDEBUG -Wno-unused-variable")
exec("${emDir}/emconfigure" ./configure
  --host=WASM
  --use-cuda=no
  --with-cudadecoder=no
  "--fst-root=${topDir}/openfst"
  --fst-version=1.8.5
  "--openblas-root=${topDir}/openblas"
  WORKING_DIRECTORY "${topDir}/kaldi-${sha}/src"
)
exec(
  "${emDir}/emmake" make -j 32
  WORKING_DIRECTORY "${topDir}/kaldi-${sha}/src"
)
