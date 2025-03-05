#!/bin/bash

# Baixar Flutter
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# Configurar Flutter
flutter precache
flutter doctor -v
flutter config --enable-web

# Construir para web
flutter build web --release

