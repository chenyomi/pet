#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/flutter_env.sh"

MODE="${1:-server}"

if [[ "${MODE}" == "chrome" ]]; then
  run_flutter run -d chrome
else
  run_flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
fi
