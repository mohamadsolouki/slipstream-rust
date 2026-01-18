#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PICOQUIC_DIR="${PICOQUIC_DIR:-"${ROOT_DIR}/vendor/picoquic"}"
BUILD_DIR="${PICOQUIC_BUILD_DIR:-"${ROOT_DIR}/.picoquic-build"}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
FETCH_PTLS="${PICOQUIC_FETCH_PTLS:-ON}"

# Detect Windows
IS_WINDOWS=false
if [[ "${OSTYPE:-}" == "msys" ]] || [[ "${OSTYPE:-}" == "cygwin" ]] || [[ -n "${WINDIR:-}" ]]; then
  IS_WINDOWS=true
fi

if [[ ! -d "${PICOQUIC_DIR}" ]]; then
  echo "picoquic not found at ${PICOQUIC_DIR}. Run: git submodule update --init --recursive" >&2
  exit 1
fi

# Build cmake args
CMAKE_ARGS=(
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
  -DPICOQUIC_FETCH_PTLS="${FETCH_PTLS}"
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  -Dpicoquic_BUILD_TESTS=OFF
  -DBUILD_DEMO=OFF
  -DBUILD_HTTP=OFF
  -DBUILD_LOGLIB=OFF
  -DBUILD_LOGREADER=OFF
)

# Pass OpenSSL paths if set
if [[ -n "${OPENSSL_ROOT_DIR:-}" ]]; then
  CMAKE_ARGS+=(-DOPENSSL_ROOT_DIR="${OPENSSL_ROOT_DIR}")
fi

# Explicitly set OpenSSL paths if provided (needed for Windows)
if [[ -n "${OPENSSL_INCLUDE_DIR:-}" ]]; then
  CMAKE_ARGS+=(-DOPENSSL_INCLUDE_DIR="${OPENSSL_INCLUDE_DIR}")
fi
if [[ -n "${OPENSSL_CRYPTO_LIBRARY:-}" ]]; then
  CMAKE_ARGS+=(-DOPENSSL_CRYPTO_LIBRARY="${OPENSSL_CRYPTO_LIBRARY}")
fi
if [[ -n "${OPENSSL_SSL_LIBRARY:-}" ]]; then
  CMAKE_ARGS+=(-DOPENSSL_SSL_LIBRARY="${OPENSSL_SSL_LIBRARY}")
fi

cmake -S "${PICOQUIC_DIR}" -B "${BUILD_DIR}" "${CMAKE_ARGS[@]}"

# On Windows, copy our enhanced wincompat.h to picotls include directory after CMake configure
if [[ "${IS_WINDOWS}" == "true" ]]; then
  # Use our patched wincompat.h that includes ws2tcpip.h for IPv6 support
  WINCOMPAT_SRC="${ROOT_DIR}/scripts/patches/wincompat.h"
  PICOTLS_INCLUDE="${BUILD_DIR}/_deps/picotls-src/include"
  if [[ -f "${WINCOMPAT_SRC}" ]] && [[ -d "${PICOTLS_INCLUDE}" ]]; then
    echo "Copying enhanced wincompat.h to picotls include directory..."
    cp "${WINCOMPAT_SRC}" "${PICOTLS_INCLUDE}/"
  else
    # Fall back to picoquic's wincompat.h
    WINCOMPAT_FALLBACK="${PICOQUIC_DIR}/picoquic/wincompat.h"
    if [[ -f "${WINCOMPAT_FALLBACK}" ]] && [[ -d "${PICOTLS_INCLUDE}" ]]; then
      echo "Copying picoquic wincompat.h to picotls include directory..."
      cp "${WINCOMPAT_FALLBACK}" "${PICOTLS_INCLUDE}/"
    else
      echo "Warning: Could not copy wincompat.h - source: ${WINCOMPAT_SRC}, dest: ${PICOTLS_INCLUDE}"
    fi
  fi
fi

cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}"
