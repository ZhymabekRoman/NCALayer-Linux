#!/bin/bash
# NCALayer launcher script for system-installed packages

set -e

# Find Java 8
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA="$JAVA_HOME/bin/java"
elif command -v java >/dev/null 2>&1; then
    JAVA="java"
else
    echo "Error: Java 8 runtime not found"
    echo "Please install Java 8 JRE:"
    echo "  Debian/Ubuntu: sudo apt install openjdk-8-jre"
    echo "  Fedora/RHEL:   sudo dnf install java-1.8.0-openjdk"
    echo "  Arch Linux:    sudo pacman -S jre8-openjdk"
    exit 1
fi

# Verify Java version is 8
JAVA_VERSION=$($JAVA -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1-2)
if [ "$JAVA_VERSION" != "1.8" ]; then
    echo "Warning: Java 8 is recommended (found version $JAVA_VERSION)"
    echo "NCALayer may not work correctly with this Java version."
fi

# Auto-detect PCSC library for smart card support
JAVA_ARGS=""
if command -v pkg-config >/dev/null 2>&1; then
    PCSC_LIB=$(pkg-config --variable=libdir libpcsclite 2>/dev/null)/libpcsclite.so.1
    if [ -n "$PCSC_LIB" ] && [ -r "$PCSC_LIB" ]; then
        JAVA_ARGS="-Dsun.security.smartcardio.library=$PCSC_LIB"
    fi
elif [ -f /usr/lib/x86_64-linux-gnu/libpcsclite.so.1 ]; then
    JAVA_ARGS="-Dsun.security.smartcardio.library=/usr/lib/x86_64-linux-gnu/libpcsclite.so.1"
elif [ -f /usr/lib64/libpcsclite.so.1 ]; then
    JAVA_ARGS="-Dsun.security.smartcardio.library=/usr/lib64/libpcsclite.so.1"
fi

# Run NCALayer
exec $JAVA $JAVA_ARGS -jar /usr/share/ncalayer/ncalayer.jar "$@" 2>/dev/null &
