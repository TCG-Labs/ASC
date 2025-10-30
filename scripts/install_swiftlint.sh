#!/bin/bash

VER=0.62.2
echo "Installing SwiftLint by downloading a pre-compiled binary"
curl -L https://github.com/realm/SwiftLint/releases/download/${VER}/portable_swiftlint.zip -o swiftlint.zip
unzip swiftlint.zip -d swiftlint
rm -f swiftlint.zip
sudo cp swiftlint/swiftlint /usr/local/bin/
swiftlint version