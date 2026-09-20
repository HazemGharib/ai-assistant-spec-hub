#!/usr/bin/env bash
# Build all platform repos in parallel, then start the local integrated stack.
#
# Usage (from anywhere):
#   ./ai-assistant-spec-hub/scripts/dev-local.sh
#   ./ai-assistant-spec-hub/scripts/dev-local.sh --dev          # watch mode (pnpm dev)
#   ./ai-assistant-spec-hub/scripts/dev-local.sh --build-only
#   ./ai-assistant-spec-hub/scripts/dev-local.sh --no-build     # start without rebuilding
#   ./ai-assistant-spec-hub/scripts/dev-local.sh --smoke        # run integrated smoke after ready
#   ./ai-assistant-spec-hub/scripts/dev-local.sh --install      # pnpm install in each repo first
#
# Ports: UI 5173 | backend 3001 | RAG 3002 | MCP 3003
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPOS=(ai-assistant-contracts ai-assistant-backend ai-assistant-rag ai-assistant-mcp ai-assistant-ui)

PORT_BACKEND=3001
PORT_RAG=3002
PORT_MCP=3003
PORT_UI=5173

MODE="start" # start | dev
DO_BUILD=1
BUILD_ONLY=0
DO_SMOKE=0
DO_INSTALL=0
LOG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/.dev-logs"

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev) MODE="dev"; shift ;;
    --build-only) BUILD_ONLY=1; shift ;;
    --no-build) DO_BUILD=0; shift ;;
    --smoke) DO_SMOKE=1; shift ;;
    --install) DO_INSTALL=1; shift ;;
    -h|--help) usage 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
  esac
done

log() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

require_cmd pnpm
require_cmd node
require_cmd curl

for repo in "${REPOS[@]}"; do
  [[ -d "${ROOT}/${repo}" ]] || die "Missing sibling repo: ${ROOT}/${repo}"
done

mkdir -p "${LOG_DIR}"

PIDS=()
cleanup() {
  local pid
  if ((${#PIDS[@]})); then
    log "Stopping local services (pids: ${PIDS[*]})..."
    for pid in "${PIDS[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
    for pid in "${PIDS[@]}"; do
      wait "$pid" 2>/dev/null || true
    done
  fi
}
trap cleanup EXIT INT TERM

run_in_repo() {
  local repo="$1"
  shift
  (
    cd "${ROOT}/${repo}"
    "$@"
  )
}

install_all() {
  log "Installing dependencies in parallel..."
  local repo pids=() status=0
  for repo in "${REPOS[@]}"; do
    (
      log "[install] ${repo}"
      run_in_repo "$repo" pnpm install
    ) >"${LOG_DIR}/install-${repo}.log" 2>&1 &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do
    wait "$pid" || status=1
  done
  if ((status != 0)); then
    log "Install failed — see ${LOG_DIR}/install-*.log"
    exit 1
  fi
  log "Install complete"
}

build_one() {
  local repo="$1"
  log "[build] ${repo}"
  if [[ "$repo" == "ai-assistant-ui" ]]; then
    # Vite inlines VITE_* at build time (needed for `vite preview`).
    run_in_repo "$repo" \
      env VITE_BACKEND_BASE_URL="http://127.0.0.1:${PORT_BACKEND}" \
          pnpm build
  else
    run_in_repo "$repo" pnpm build
  fi
  log "[build] ${repo} ok"
}

build_all() {
  log "Building all repos in parallel..."
  local repo pids=() status=0
  for repo in "${REPOS[@]}"; do
    (
      build_one "$repo"
    ) >"${LOG_DIR}/build-${repo}.log" 2>&1 &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      status=1
    fi
  done
  if ((status != 0)); then
    log "Build failed — dumping logs:"
    for repo in "${REPOS[@]}"; do
      echo "----- ${repo} -----"
      cat "${LOG_DIR}/build-${repo}.log" || true
    done
    exit 1
  fi
  log "Build complete"
}

wait_http() {
  local name="$1" url="$2" attempts="${3:-60}"
  local i
  for ((i = 1; i <= attempts; i++)); do
    if curl -sf "$url" >/dev/null 2>&1; then
      log "${name} ready (${url})"
      return 0
    fi
    sleep 0.5
  done
  die "${name} did not become ready at ${url} (see ${LOG_DIR}/)"
}

start_service() {
  local repo="$1"
  local name="$2"
  shift 2
  local logfile="${LOG_DIR}/run-${name}.log"
  log "Starting ${name} (${repo}) → ${logfile}"
  (
    cd "${ROOT}/${repo}"
    exec "$@"
  ) >"${logfile}" 2>&1 &
  PIDS+=($!)
}

start_stack() {
  if [[ "$MODE" == "dev" ]]; then
    start_service ai-assistant-rag rag \
      env PORT="${PORT_RAG}" pnpm dev
    start_service ai-assistant-mcp mcp \
      env PORT="${PORT_MCP}" pnpm dev
    start_service ai-assistant-backend backend \
      env PORT="${PORT_BACKEND}" \
          RAG_BASE_URL="http://127.0.0.1:${PORT_RAG}" \
          MCP_SERVER_URL="http://127.0.0.1:${PORT_MCP}" \
          pnpm dev
    start_service ai-assistant-ui ui \
      env VITE_BACKEND_BASE_URL="http://127.0.0.1:${PORT_BACKEND}" \
          pnpm dev -- --host 127.0.0.1 --port "${PORT_UI}"
  else
    start_service ai-assistant-rag rag \
      env PORT="${PORT_RAG}" pnpm start
    start_service ai-assistant-mcp mcp \
      env PORT="${PORT_MCP}" pnpm start
    start_service ai-assistant-backend backend \
      env PORT="${PORT_BACKEND}" \
          RAG_BASE_URL="http://127.0.0.1:${PORT_RAG}" \
          MCP_SERVER_URL="http://127.0.0.1:${PORT_MCP}" \
          pnpm start
    start_service ai-assistant-ui ui \
      env VITE_BACKEND_BASE_URL="http://127.0.0.1:${PORT_BACKEND}" \
          pnpm exec vite preview --host 127.0.0.1 --port "${PORT_UI}"
  fi

  wait_http "RAG" "http://127.0.0.1:${PORT_RAG}/health"
  wait_http "MCP" "http://127.0.0.1:${PORT_MCP}/health"
  wait_http "backend" "http://127.0.0.1:${PORT_BACKEND}/health"
  wait_http "UI" "http://127.0.0.1:${PORT_UI}"

  cat <<EOF

Local stack is up:
  UI       http://127.0.0.1:${PORT_UI}
  Backend  http://127.0.0.1:${PORT_BACKEND}/health
  RAG      http://127.0.0.1:${PORT_RAG}/health
  MCP      http://127.0.0.1:${PORT_MCP}/health

Logs: ${LOG_DIR}/run-*.log
Ctrl+C to stop all services.
EOF
}

run_smoke() {
  log "Running integrated smoke..."
  run_in_repo ai-assistant-backend \
    env BACKEND_BASE_URL="http://127.0.0.1:${PORT_BACKEND}" \
        pnpm smoke:integrated
  log "Integrated smoke passed"
}

# --- main ---
log "Workspace root: ${ROOT}"

if ((DO_INSTALL)); then
  install_all
fi

if ((DO_BUILD)); then
  build_all
fi

if ((BUILD_ONLY)); then
  log "Build-only requested; exiting"
  trap - EXIT INT TERM
  exit 0
fi

start_stack

if ((DO_SMOKE)); then
  run_smoke
fi

# Keep running until interrupted
wait
