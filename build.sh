#!/bin/bash

# Baixar Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Configurar Flutter
flutter config --enable-web
flutter doctor -v

# Construir para web
flutter build web --release

