#!/usr/bin/env bash
# 统计 app 的行覆盖率，本地和 CI 共用，保证口径一致。
#
#   tool/coverage.sh          # 统计并打印
#   MIN_COVERAGE=80 tool/coverage.sh   # 低于门槛时以非零退出
#
# 口径：
# - flutter test 只统计被测试 import 到的文件，完全没测的文件不会出现，覆盖率会虚高。
#   所以先生成一个 import 全部 lib 文件的空测试，把它们都纳入统计。
# - 排除 drift 生成代码（*.g.dart、按版本生成的 schema_versions.dart）、表定义（只给代码生成读，运行时不执行）、
#   Web 专用实现和 main.dart。
set -euo pipefail
cd "$(dirname "$0")/.."

EXCLUDE='(\.g\.dart|lib/data/db/schema_versions\.dart|lib/main\.dart|lib/data/db/tables\.dart|lib/net/http_client_web\.dart)$'
ALL_FILES_TEST=test/_all_files_test.dart

trap 'rm -f "$ALL_FILES_TEST"' EXIT
{
  echo '// 由 tool/coverage.sh 生成，统计完自动删除。'
  echo '// ignore_for_file: unused_import'
  find lib -name '*.dart' | grep -Ev "$EXCLUDE" | sort | sed "s#^lib/\(.*\)#import 'package:jingtouben/\1';#"
  echo 'void main() {}'
} > "$ALL_FILES_TEST"

flutter test --coverage

# 去掉排除的文件后重新汇总
awk -v exclude="$EXCLUDE" '
  /^SF:/ { file = substr($0, 4); skip = (file ~ exclude) }
  !skip { print }
' coverage/lcov.info > coverage/lcov.filtered.info

awk -F: '
  /^SF:/ { file = $2 }
  /^LF:/ { lf[file] = $2; total_lf += $2 }
  /^LH:/ { lh[file] = $2; total_lh += $2 }
  END {
    print "低于 80% 的文件："
    for (f in lf) if (lf[f] > 0 && lh[f] / lf[f] < 0.8) printf "  %5.1f%%  %4d/%-4d %s\n", lh[f] * 100 / lf[f], lh[f], lf[f], f
    printf "Line coverage: %.1f%% (%d/%d)\n", total_lh * 100 / total_lf, total_lh, total_lf
  }
' coverage/lcov.filtered.info | tee coverage/summary.txt

if [[ -n "${MIN_COVERAGE:-}" ]]; then
  actual=$(sed -n 's/^Line coverage: \([0-9.]*\)%.*/\1/p' coverage/summary.txt)
  if awk -v a="$actual" -v m="$MIN_COVERAGE" 'BEGIN { exit !(a < m) }'; then
    echo "覆盖率 ${actual}% 低于门槛 ${MIN_COVERAGE}%" >&2
    exit 1
  fi
  echo "覆盖率 ${actual}% 达到门槛 ${MIN_COVERAGE}%"
fi
