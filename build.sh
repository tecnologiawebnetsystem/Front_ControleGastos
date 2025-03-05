#!/bin/bash

# Instalar Flutter
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"
flutter precache
flutter doctor

# Construir para web
flutter build web --release

