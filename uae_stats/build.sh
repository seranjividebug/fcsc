#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /opt/flutter
export PATH="$PATH:/opt/flutter/bin"

# Get dependencies
flutter pub get

# Build for web
flutter build web --release
