#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PICOQUIC_DIR="${PICOQUIC_DIR:-"${ROOT_DIR}/vendor/picoquic"}"
BUILD_DIR="${PICOQUIC_BUILD_DIR:-"${ROOT_DIR}/.picoquic-build"}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
FETCH_PTLS="${PICOQUIC_FETCH_PTLS:-ON}"

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
cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}"
