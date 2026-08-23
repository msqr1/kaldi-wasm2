include("Exec.cmake")

find_package(Python 3.8)
if(NOT Python_FOUND)
  message(FATAL_ERROR "Python 3.8 not found")
endif()

find_package(Git)
if(NOT Git_FOUND)
  message(FATAL_ERROR "Git not found")
endif()

if(NOT IS_READABLE emsdk)
  exec(git clone https://github.com/emscripten-core/emsdk.git emsdk)
endif()

exec(./emsdk install 6.0.8 WORKING_DIRECTORY emsdk)
exec(./emsdk activate 6.0.8 WORKING_DIRECTORY emsdk)
