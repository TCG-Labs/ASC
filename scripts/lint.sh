#!/bin/bash

if which swiftlint >/dev/null; then
    cd ..
    swiftlint lint --config .swiftlint.yml
else
    echo "SwiftLint not installed, run `install_swiftlint.sh`"
fi
