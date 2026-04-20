#!/usr/bin/env bash
# MaterialFiles' signing.gradle reads signing.properties instead of the
# default keystore.properties. Same key/value shape — just the filename
# differs — so hand off to the shared default with an override.
here="$(dirname "$0")"
exec "$here/../../common/default-build.sh" "$here/source" signing.properties
