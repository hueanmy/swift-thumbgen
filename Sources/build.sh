#!/bin/bash

set -e

SOURCE_FILE="main.swift"
OUTPUT_NAME="gen-thumb"
BUILD_DIR="bin"

mkdir -p "$BUILD_DIR"

echo "🔨 Building for Apple Silicon (arm64)..."
swiftc -target arm64-apple-macos12 -o "$BUILD_DIR/${OUTPUT_NAME}-arm64" "$SOURCE_FILE"

echo "🔨 Building for Intel (x86_64)..."
swiftc -target x86_64-apple-macos12 -o "$BUILD_DIR/${OUTPUT_NAME}-x86_64" "$SOURCE_FILE"

echo "🔗 Creating universal binary..."
lipo -create -output "$BUILD_DIR/${OUTPUT_NAME}-universal" \
  "$BUILD_DIR/${OUTPUT_NAME}-arm64" \
  "$BUILD_DIR/${OUTPUT_NAME}-x86_64"

echo "✅ Done. Built binaries:"
file "$BUILD_DIR"/${OUTPUT_NAME}-*
