#!/bin/bash
# NCALayer launcher script for RPM packages with bundled JRE

set -e

# Use bundled Java 8 JRE
JAVA_HOME="/usr/share/ncalayer/jre8_ncalayer"
JAVA="$JAVA_HOME/bin/java"

# Verify bundled Java exists
if [ ! -x "$JAVA" ]; then
    echo "Error: Bundled Java runtime not found at $JAVA"
    echo "Please reinstall the package."
    exit 1
fi

# Auto-detect PCSC library for smart card support
JAVA_ARGS="-Djava.security.manager=allow"
if command -v pkg-config >/dev/null 2>&1; then
    PCSC_LIB=$(pkg-config --variable=libdir libpcsclite 2>/dev/null)/libpcsclite.so.1
    if [ -n "$PCSC_LIB" ] && [ -r "$PCSC_LIB" ]; then
        JAVA_ARGS="$JAVA_ARGS -Dsun.security.smartcardio.library=$PCSC_LIB"
    fi
elif [ -f /usr/lib64/libpcsclite.so.1 ]; then
    JAVA_ARGS="$JAVA_ARGS -Dsun.security.smartcardio.library=/usr/lib64/libpcsclite.so.1"
elif [ -f /usr/lib/libpcsclite.so.1 ]; then
    JAVA_ARGS="$JAVA_ARGS -Dsun.security.smartcardio.library=/usr/lib/libpcsclite.so.1"
fi

# Run NCALayer in the foreground so JVM startup errors are visible to the user
exec "$JAVA" $JAVA_ARGS -jar /usr/share/ncalayer/ncalayer.jar "$@"
