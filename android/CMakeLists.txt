cmake_minimum_required(VERSION 3.10.2)

set (CMAKE_VERBOSE_MAKEFILE ON)
set (CMAKE_CXX_STANDARD 14)
MESSAGE(STATUS "==== GCC detected - Adding compiler flags")
#set (CMAKE_CXX_FLAGS "-DFOLLY_NO_CONFIG=1 -DFOLLY_HAVE_CLOCK_GETTIME=1 -DFOLLY_HAVE_MEMRCHR=1 -DFOLLY_USE_LIBCPP=1 -DFOLLY_MOBILE=1 -DON_ANDROID -DONANDROID -DFOR_HERMES=${FOR_HERMES}")

set (PACKAGE_NAME "react-native-quick-sqlite")
set (BUILD_DIR ${CMAKE_SOURCE_DIR}/build)
set (RN_SO_DIR ${NODE_MODULES_DIR}/react-native/ReactAndroid/src/main/jni/first-party/react/jni)

if("${USE_SQLCIPHER}" STREQUAL "1")
  SET(OPENSSL_USE_STATIC_LIBS TRUE)
  SET(OPENSSL_ROOT_DIR ../openssl/${ANDROID_ABI})
  SET(OPENSSL_LIBRARIES_DIR ${OPENSSL_ROOT_DIR}/lib)
  SET(OPENSSL_INCLUDE_DIR ${OPENSSL_ROOT_DIR}/include)
  SET(OPENSSL_LIBRARIES "crypto")

  LINK_DIRECTORIES(${OPENSSL_LIBRARIES_DIR})
  
  SET(SQLITE_PATH ../cpp/sqlcipher/android)
  SET(SQLITE_FILES ../cpp/sqlcipher/android/sqlite3ext.h)
  SET(SQLCIPHER_FLAGS -DSQLITE_HAS_CODEC -DSQLITE_SOUNDEX -DHAVE_USLEEP=1 -DSQLITE_MAX_VARIABLE_NUMBER=99999 -DSQLITE_TEMP_STORE=3 -DSQLITE_THREADSAFE=1 -DSQLITE_DEFAULT_JOURNAL_SIZE_LIMIT=1048576 -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1 -DSQLITE_ENABLE_LOAD_EXTENSION -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_UNLOCK_NOTIFY -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_STAT3 -DSQLITE_ENABLE_STAT4 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_FTS5 -DSQLCIPHER_CRYPTO_OPENSSL -DSQLITE_ENABLE_DBSTAT_VTAB -DNDEBUG=1)
else()
  SET(OPENSSL_INCLUDE_DIR "")
  SET(SQLITE_PATH ../cpp/sqlite)
  SET(SQLITE_FILES "")
  SET(SQLCIPHER_FLAGS "")
endif()

if(${REACT_NATIVE_VERSION} LESS 66)
        set (
                INCLUDE_JSI_CPP
                "${NODE_MODULES_DIR}/react-native/ReactCommon/jsi/jsi/jsi.cpp"
        )
        set (
                INCLUDE_JSIDYNAMIC_CPP
                "${NODE_MODULES_DIR}/react-native/ReactCommon/jsi/jsi/JSIDynamic.cpp"
        )
endif()

file (GLOB LIBFBJNI_INCLUDE_DIR "${BUILD_DIR}/fbjni-*-headers.jar/")

include_directories(
  ../cpp
  ${SQLITE_PATH}
  "${NODE_MODULES_DIR}/react-native/React"
  "${NODE_MODULES_DIR}/react-native/React/Base"
  "${NODE_MODULES_DIR}/react-native/ReactCommon/jsi"
  "${NODE_MODULES_DIR}/react-native/ReactCommon/callinvoker"
  "${NODE_MODULES_DIR}/react-native/ReactAndroid/src/main/java/com/facebook/react/turbomodule/core/jni"
  "${NODE_MODULES_DIR}/react-native/ReactCommon"
  "${NODE_MODULES_DIR}/react-native/ReactCommon/callinvoker"
  "${NODE_MODULES_DIR}/react-native/ReactCommon/jsi"
  "${NODE_MODULES_DIR}/hermes-engine/android/include/"
  ${INCLUDE_JSI_CPP} # only on older RN versions
  ${INCLUDE_JSIDYNAMIC_CPP} # only on older RN versions
  ${OPENSSL_INCLUDE_DIR} # required for SQLCipher
)

add_library(
  ${PACKAGE_NAME}
  SHARED
  ../cpp/sqliteBridge.cpp
  ../cpp/sqliteBridge.h
  ../cpp/bindings.cpp
  ../cpp/bindings.h
  "${SQLITE_PATH}/sqlite3.h"
  "${SQLITE_PATH}/sqlite3.c"
  ${SQLITE_FILES}
  ../cpp/JSIHelper.h
  ../cpp/JSIHelper.cpp
  ../cpp/ThreadPool.h
  ../cpp/ThreadPool.cpp
  ../cpp/sqlfileloader.h
  ../cpp/sqlfileloader.cpp
  ../cpp/sqlbatchexecutor.h
  ../cpp/sqlbatchexecutor.cpp
  ../cpp/macros.h
  cpp-adapter.cpp
)

add_definitions(
  ${SQLCIPHER_FLAGS}
  ${SQLITE_FLAGS}
)

# find fbjni package
file (GLOB LIBFBJNI_INCLUDE_DIR "${BUILD_DIR}/fbjni-*-headers.jar/")

target_compile_definitions(${PACKAGE_NAME} PRIVATE USE_SQLCIPHER=${USE_SQLCIPHER})

target_include_directories(
        ${PACKAGE_NAME}
        PRIVATE
        # --- fbjni ---
        "${LIBFBJNI_INCLUDE_DIR}"
        # --- React Native ---
        "${NODE_MODULES_DIR}/react-native/React"
        "${NODE_MODULES_DIR}/react-native/React/Base"
        "${NODE_MODULES_DIR}/react-native/ReactAndroid/src/main/jni"
        "${NODE_MODULES_DIR}/react-native/ReactAndroid/src/main/java/com/facebook/react/turbomodule/core/jni"
        "${NODE_MODULES_DIR}/react-native/ReactCommon"
        "${NODE_MODULES_DIR}/react-native/ReactCommon/callinvoker"
        "${NODE_MODULES_DIR}/react-native/ReactCommon/jsi"
        "${NODE_MODULES_DIR}/hermes-engine/android/include/"
        ${INCLUDE_JSI_CPP} # only on older RN versions
        ${INCLUDE_JSIDYNAMIC_CPP} # only on older RN versions
        ${OPENSSL_INCLUDE_DIR} # required for SQLCipher
)


file (GLOB LIBRN_DIR "${BUILD_DIR}/react-native-0*/jni/${ANDROID_ABI}")

find_library(
        FBJNI_LIB
        fbjni
        PATHS ${LIBRN_DIR}
        NO_CMAKE_FIND_ROOT_PATH
)

find_library(
        REACT_NATIVE_JNI_LIB
        reactnativejni
        PATHS ${LIBRN_DIR}
        NO_CMAKE_FIND_ROOT_PATH
)
if(${REACT_NATIVE_VERSION} LESS 66)
        # JSI lib didn't exist on RN 0.65 and before. Simply omit it.
        set (JSI_LIB "")
else()
        # RN 0.66 distributes libjsi.so, can be used instead of compiling jsi.cpp manually.
        find_library(
                JSI_LIB
                jsi
                PATHS ${LIBRN_DIR}
                NO_CMAKE_FIND_ROOT_PATH
        )
endif()

find_library(
        LOG_LIB
        log
)

# target_link_libraries(sequel fbjni::fbjni android log)
target_link_libraries(
        ${PACKAGE_NAME}
        ${LOG_LIB}
        ${JSI_LIB}
        ${REACT_NATIVE_JNI_LIB}
        ${FBJNI_LIB}
        android
        ${OPENSSL_LIBRARIES} # required for SQLCipher
)
