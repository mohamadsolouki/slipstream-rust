#!/bin/bash

# Slipstream-Rust Client Build Script for Linux/macOS
# Builds the client binary with all dependencies

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt &> /dev/null; then
            PKG_MANAGER="apt"
        elif command -v dnf &> /dev/null; then
            PKG_MANAGER="dnf"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
        elif command -v pacman &> /dev/null; then
            PKG_MANAGER="pacman"
        else
            PKG_MANAGER="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PKG_MANAGER="brew"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_status "Detected OS: $OS"
    print_status "Package manager: $PKG_MANAGER"
}

# Install dependencies
install_dependencies() {
    print_status "Installing build dependencies..."
    
    case $PKG_MANAGER in
        apt)
            sudo apt update
            sudo apt install -y cmake pkg-config libssl-dev build-essential git curl
            ;;
        dnf|yum)
            sudo $PKG_MANAGER install -y cmake pkg-config openssl-devel gcc gcc-c++ make git curl
            ;;
        pacman)
            sudo pacman -Sy --noconfirm cmake pkg-config openssl base-devel git curl
            ;;
        brew)
            brew install cmake pkg-config openssl@3 git
            export OPENSSL_DIR=$(brew --prefix openssl@3)
            export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
            ;;
        *)
            print_warning "Unknown package manager. Please install cmake, pkg-config, openssl-dev manually."
            ;;
    esac
}

# Install Rust if needed
install_rust() {
    if ! command -v rustc &> /dev/null; then
        print_status "Installing Rust toolchain..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        print_status "Rust is already installed: $(rustc --version)"
    fi
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_OUTPUT_DIR="$ROOT_DIR/build"

# Parse arguments
RELEASE_BUILD=true
TARGET=""
CROSS_COMPILE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            RELEASE_BUILD=false
            shift
            ;;
        --target)
            TARGET="$2"
            CROSS_COMPILE=true
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --debug         Build in debug mode (default: release)"
            echo "  --target TARGET Cross-compile for TARGET (e.g., x86_64-unknown-linux-musl)"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main build process
main() {
    print_status "Starting slipstream-client build..."
    
    detect_os
    install_dependencies
    install_rust
    
    # Navigate to root source
    cd "$ROOT_DIR"
    
    # Initialize submodules
    print_status "Initializing submodules..."
    git submodule update --init --recursive
    
    # Build picoquic if needed
    if [[ -f "scripts/build/build_picoquic.sh" ]]; then
        print_status "Building picoquic dependencies..."
        bash scripts/build/build_picoquic.sh
    fi
    
    # Set build mode
    BUILD_FLAGS=""
    if [[ "$RELEASE_BUILD" == true ]]; then
        BUILD_FLAGS="--release"
        print_status "Building in RELEASE mode..."
    else
        print_status "Building in DEBUG mode..."
    fi
    
    # Cross-compile if target specified
    if [[ "$CROSS_COMPILE" == true ]]; then
        print_status "Cross-compiling for target: $TARGET"
        rustup target add "$TARGET"
        BUILD_FLAGS="$BUILD_FLAGS --target $TARGET"
    fi
    
    # Build client
    print_status "Building slipstream-client..."
    cargo build -p slipstream-client $BUILD_FLAGS
    
    # Copy binary to output directory
    mkdir -p "$BUILD_OUTPUT_DIR"
    
    if [[ "$RELEASE_BUILD" == true ]]; then
        if [[ "$CROSS_COMPILE" == true ]]; then
            BINARY_PATH="target/$TARGET/release/slipstream-client"
        else
            BINARY_PATH="target/release/slipstream-client"
        fi
    else
        if [[ "$CROSS_COMPILE" == true ]]; then
            BINARY_PATH="target/$TARGET/debug/slipstream-client"
        else
            BINARY_PATH="target/debug/slipstream-client"
        fi
    fi
    
    if [[ -f "$BINARY_PATH" ]]; then
        cp "$BINARY_PATH" "$BUILD_OUTPUT_DIR/"
        print_status "Build successful!"
        print_status "Binary location: $BUILD_OUTPUT_DIR/slipstream-client"
        
        # Show binary info
        file "$BUILD_OUTPUT_DIR/slipstream-client"
        ls -lh "$BUILD_OUTPUT_DIR/slipstream-client"
    else
        print_error "Build failed: binary not found at $BINARY_PATH"
        exit 1
    fi
}

main "$@"
