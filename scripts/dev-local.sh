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
LOG_TAIL_LINES=80

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

ts() { date '+%H:%M:%S'; }
log() { printf '[%s] ==> %s\n' "$(ts)" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$(ts)" "$*" >&2; }
die() { printf '[%s] ERROR: %s\n' "$(ts)" "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# Dump the last N lines of a log file to stderr with a clear header.
dump_log() {
  local label="$1"
  local file="$2"
  local lines="${3:-$LOG_TAIL_LINES}"

  printf '\n---------- %s ----------\n' "$label" >&2
  if [[ ! -f "$file" ]]; then
    printf '(log file missing: %s)\n' "$file" >&2
    return
  fi
  if [[ ! -s "$file" ]]; then
    printf '(log file empty: %s)\n' "$file" >&2
    return
  fi
  printf 'file: %s (last %s lines)\n\n' "$file" "$lines" >&2
  tail -n "$lines" "$file" >&2 || true
  printf '---------- end %s ----------\n\n' "$label" >&2
}

pid_alive() {
  kill -0 "$1" 2>/dev/null
}

# Print status of any background services that have already exited.
# Returns 0 if all still alive, 1 if any are dead.
report_dead_services() {
  local any_dead=0
  local i name pid logfile
  for i in "${!PIDS[@]}"; do
    pid="${PIDS[$i]}"
    name="${PID_NAMES[$i]:-pid-$pid}"
    logfile="${PID_LOGS[$i]:-}"
    if ! pid_alive "$pid"; then
      any_dead=1
      warn "Service '${name}' (pid ${pid}) is not running"
      if [[ -n "$logfile" ]]; then
        dump_log "run-${name}" "$logfile"
      fi
    fi
  done
  return "$any_dead"
}

find_service_index() {
  local name="$1"
  local i
  for i in "${!PID_NAMES[@]}"; do
    if [[ "${PID_NAMES[$i]}" == "$name" ]]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}

require_cmd pnpm
require_cmd node
require_cmd curl

for repo in "${REPOS[@]}"; do
  [[ -d "${ROOT}/${repo}" ]] || die "Missing sibling repo: ${ROOT}/${repo}"
done

mkdir -p "${LOG_DIR}"

PIDS=()
PID_NAMES=()
PID_LOGS=()

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
  local repo pids=() names=() status=0 i pid
  for repo in "${REPOS[@]}"; do
    (
      log "[install] ${repo}"
      run_in_repo "$repo" pnpm install
    ) >"${LOG_DIR}/install-${repo}.log" 2>&1 &
    pids+=($!)
    names+=("$repo")
  done
  for i in "${!pids[@]}"; do
    pid="${pids[$i]}"
    if ! wait "$pid"; then
      status=1
      warn "Install failed: ${names[$i]} (see ${LOG_DIR}/install-${names[$i]}.log)"
      dump_log "install-${names[$i]}" "${LOG_DIR}/install-${names[$i]}.log"
    fi
  done
  if ((status != 0)); then
    die "Install failed — failed repo logs dumped above (full set in ${LOG_DIR}/install-*.log)"
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
  local repo pids=() names=() status=0 i pid
  for repo in "${REPOS[@]}"; do
    (
      build_one "$repo"
    ) >"${LOG_DIR}/build-${repo}.log" 2>&1 &
    pids+=($!)
    names+=("$repo")
  done
  for i in "${!pids[@]}"; do
    pid="${pids[$i]}"
    if ! wait "$pid"; then
      status=1
      warn "Build failed: ${names[$i]} (see ${LOG_DIR}/build-${names[$i]}.log)"
      dump_log "build-${names[$i]}" "${LOG_DIR}/build-${names[$i]}.log"
    fi
  done
  if ((status != 0)); then
    die "Build failed — failed repo logs dumped above (full set in ${LOG_DIR}/build-*.log)"
  fi
  log "Build complete"
}

wait_http() {
  local name="$1" url="$2" attempts="${3:-60}"
  local i logfile="${LOG_DIR}/run-${name}.log"
  local curl_err="" curl_rc=0 idx pid

  for ((i = 1; i <= attempts; i++)); do
    if idx="$(find_service_index "$name")"; then
      pid="${PIDS[$idx]}"
      if ! pid_alive "$pid"; then
        dump_log "run-${name}" "$logfile"
        die "${name} exited before becoming ready at ${url} (pid ${pid})"
      fi
    fi

    curl_err="$(curl -sfS "$url" 2>&1)" && {
      log "${name} ready (${url})"
      return 0
    }
    curl_rc=$?

    sleep 0.5
  done

  warn "${name} did not become ready at ${url} after ~$((attempts / 2))s"
  warn "Last curl exit=${curl_rc}: ${curl_err:-'(no stderr)'}"
  dump_log "run-${name}" "$logfile"
  report_dead_services || true
  die "${name} did not become ready at ${url}"
}

start_service() {
  local repo="$1"
  local name="$2"
  shift 2
  local logfile="${LOG_DIR}/run-${name}.log"
  : >"$logfile"
  log "Starting ${name} (${repo}) → ${logfile}"
  (
    cd "${ROOT}/${repo}"
    exec "$@"
  ) >"${logfile}" 2>&1 &
  PIDS+=($!)
  PID_NAMES+=("$name")
  PID_LOGS+=("$logfile")
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

  wait_http "rag" "http://127.0.0.1:${PORT_RAG}/health"
  wait_http "mcp" "http://127.0.0.1:${PORT_MCP}/health"
  wait_http "backend" "http://127.0.0.1:${PORT_BACKEND}/health"
  wait_http "ui" "http://127.0.0.1:${PORT_UI}"

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
  if ! run_in_repo ai-assistant-backend \
    env BACKEND_BASE_URL="http://127.0.0.1:${PORT_BACKEND}" \
        pnpm smoke:integrated; then
    report_dead_services || true
    die "Integrated smoke failed (services may still be running until exit)"
  fi
  log "Integrated smoke passed"
}

# Poll running services; dump logs and exit if any die (bash 3.2 compatible).
supervise_stack() {
  local i pid name logfile
  while true; do
    sleep 1
    for i in "${!PIDS[@]}"; do
      pid="${PIDS[$i]}"
      name="${PID_NAMES[$i]}"
      logfile="${PID_LOGS[$i]}"
      if ! pid_alive "$pid"; then
        warn "Service '${name}' (pid ${pid}) exited"
        dump_log "run-${name}" "$logfile"
        report_dead_services || true
        die "Local stack stopped because '${name}' exited"
      fi
    done
  done
}

# --- main ---
log "Workspace root: ${ROOT}"
log "Logs directory: ${LOG_DIR}"

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

supervise_stack
