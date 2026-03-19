#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRADLE_INIT_SOURCE="${PROJECT_DIR}/tool/gradle-init/repo_mirrors.gradle"

resolve_flutter_bin() {
  if [[ -n "${FLUTTER_BIN:-}" && -x "${FLUTTER_BIN}" ]]; then
    printf '%s\n' "${FLUTTER_BIN}"
    return
  fi

  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi

  if [[ -x "${HOME}/fvm/cache.git/bin/flutter" ]]; then
    printf '%s\n' "${HOME}/fvm/cache.git/bin/flutter"
    return
  fi

  if [[ -x "${HOME}/fvm/default/bin/flutter" ]]; then
    printf '%s\n' "${HOME}/fvm/default/bin/flutter"
    return
  fi

  echo "Flutter not found. Please install Flutter or set FLUTTER_BIN." >&2
  exit 1
}

FLUTTER_CMD="$(resolve_flutter_bin)"

prepare_gradle_home() {
  export GRADLE_USER_HOME="${GRADLE_USER_HOME:-${PROJECT_DIR}/.gradle-user-home}"
  mkdir -p "${GRADLE_USER_HOME}/init.d"
  cp "${GRADLE_INIT_SOURCE}" "${GRADLE_USER_HOME}/init.d/repo_mirrors.gradle"
}

run_flutter() {
  (
    cd "${PROJECT_DIR}"
    prepare_gradle_home
    "${FLUTTER_CMD}" "$@"
  )
}
