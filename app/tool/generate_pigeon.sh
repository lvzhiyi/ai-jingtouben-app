#!/usr/bin/env bash
# 接口定义是唯一来源；格式化到项目约定，避免 dart format 产生额外 diff。
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/share_api.dart
dart format lib/data/share/share_api.g.dart
