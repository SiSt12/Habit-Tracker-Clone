#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter config --no-analytics
flutter build web --release --base-href "/habit/" --web-renderer html --no-tree-shake-icons