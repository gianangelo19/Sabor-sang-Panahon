#!/usr/bin/env bash

set -u

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
failures=0
test_count=0

while IFS= read -r test_file; do
  test_count=$((test_count + 1))
  relative_test="${test_file#"$project_root"/}"
  printf '\n==> %s\n' "$relative_test"

  if ! "$godot_bin" --headless --path "$project_root" --script "$test_file"; then
    failures=$((failures + 1))
  fi
done < <(find "$project_root/tests" -type f -name 'test_*.gd' | sort)

printf '\nRan %d test scripts; %d failed.\n' "$test_count" "$failures"
exit "$failures"
