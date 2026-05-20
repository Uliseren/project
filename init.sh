#!/usr/bin/env bash
# Bootstrap a fresh Uliseren dev environment.
# Clones the back-end and front-end repos as siblings inside this project.
# Re-runnable: skips repos that already exist.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACK_REPO="https://github.com/Uliseren/back.git"
FRONT_REPO="https://github.com/Uliseren/front.git"

clone_if_missing() {
    local url="$1"
    local dir="$2"
    if [ -d "$ROOT/$dir/.git" ]; then
        echo "[=] $dir already cloned, skipping"
    else
        echo "[+] Cloning $dir from $url"
        git clone "$url" "$ROOT/$dir"
    fi
}

echo "==> Cloning repositories"
clone_if_missing "$BACK_REPO" "back"
clone_if_missing "$FRONT_REPO" "front"

echo
echo "==> Back-end setup (Django + uv)"
if command -v uv >/dev/null 2>&1; then
    (cd "$ROOT/back" && uv sync && uv run python manage.py migrate)
else
    echo "[!] 'uv' not installed. Install it: https://docs.astral.sh/uv/  then re-run this script."
fi

echo
echo "==> Front-end setup (Next.js)"
if command -v npm >/dev/null 2>&1; then
    (cd "$ROOT/front" && npm install)
else
    echo "[!] 'npm' not installed. Install Node.js >= 20 and re-run this script."
fi

echo
echo "==> Done. Next steps:"
echo "    Back  : cd back  && uv run python manage.py runserver"
echo "    Front : cd front && npm run dev"
echo "    See README.md for more."
