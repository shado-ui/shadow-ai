cmake_minimum_required(VERSION 3.22.1)
project("llama_jni")

# ── llama.cpp submodule ──────────────────────────────────────────────────────
# Clone with:
#   cd android/app/src/main/cpp
#   git clone https://github.com/ggerganov/llama.cpp
#
# Then run:
#   cd llama.cpp && git checkout b3447   # stable tag

set(LLAMA_DIR ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp)

# Build llama.cpp as a static library
set(LLAMA_BUILD_TESTS     OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES  OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER    OFF CACHE BOOL "" FORCE)
set(LLAMA_NATIVE          OFF CACHE BOOL "" FORCE)  # no host-specific opts

# Mobile-friendly flags
set(GGML_OPENMP   OFF CACHE BOOL "" FORCE)
set(GGML_BLAS     OFF CACHE BOOL "" FORCE)
set(GGML_CUDA     OFF CACHE BOOL "" FORCE)
set(GGML_METAL    OFF CACHE BOOL "" FORCE)

add_subdirectory(${LLAMA_DIR} llama_build)

# ── Our JNI bridge ───────────────────────────────────────────────────────────
add_library(llama_jni SHARED llama_jni.cpp)

target_include_directories(llama_jni PRIVATE
    ${LLAMA_DIR}
    ${LLAMA_DIR}/common
    ${LLAMA_DIR}/ggml/include
)

target_link_libraries(llama_jni
    llama
    ggml
    android
    log
)

# ARM optimizations (safe defaults for most Android phones)
if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(llama_jni PRIVATE -march=armv8-a+dotprod)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(llama_jni PRIVATE -mfpu=neon-fp-armv8)
endif()
