#!/bin/bash
set -e
echo "Building Bootstrap Wrapper..."
./bin/fasm src/bootstrap/wrapper.asm bin/morph-bootstrap
chmod +x bin/morph-bootstrap
echo "Build complete: bin/morph-bootstrap"
