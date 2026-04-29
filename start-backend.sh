#!/bin/bash

# start-backend.sh
# This script starts the local AI services (Docker) and the LiveKit Python agent.
#
# Code changes:
#   - Interview API (api_server.py): set API_RELOAD=1 below — uvicorn auto-reloads on save.
#     Without reload, you must stop this script (Ctrl+C) and run again to pick up API edits.
#   - LiveKit agent (src.agent): started in background — no auto-reload. After editing agent
#     code, run: pkill -f "src.agent dev"  then re-run this script, or restart only the agent.
#   - If port 8001 is already in use, stop the old api_server first.

set -e  # Exit on error

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="$SCRIPT_DIR/backend-startup.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Starting backend services..."

# 1. Start Docker containers (Whisper & Kokoro)
log "📦 Starting Docker containers (Whisper, Kokoro)..."
if docker compose -f "$SCRIPT_DIR/docker-compose.yaml" up -d >> "$LOG_FILE" 2>&1; then
    log "✅ Docker containers started successfully"
else
    log "❌ Failed to start Docker containers"
    exit 1
fi

# 2. Check Docker container status
log "🔍 Checking Docker container status..."
docker compose -f "$SCRIPT_DIR/docker-compose.yaml" ps >> "$LOG_FILE" 2>&1

# 3. Wait for services to be ready with retry logic
log "⏳ Waiting for local AI services to initialize..."
max_retries=12
retry_count=0

# Test Whisper endpoint with retries
log "🧪 Testing Whisper endpoint..."
while [ $retry_count -lt $max_retries ]; do
    if curl -s http://localhost:8080/v1/models > /dev/null 2>&1; then
        log "✅ Whisper API is ready"
        break
    else
        retry_count=$((retry_count + 1))
        log "⏳ Whisper not ready, retrying in 5 seconds... ($retry_count/$max_retries)"
        sleep 5
    fi
done

if [ $retry_count -eq $max_retries ]; then
    log "❌ Whisper failed to start after 1 minute"
    exit 1
fi

# Test Kokoro endpoint with retries
retry_count=0
log "🧪 Testing Kokoro endpoint..."
while [ $retry_count -lt $max_retries ]; do
    if curl -s http://localhost:8888/v1/models > /dev/null 2>&1; then
        log "✅ Kokoro API is ready"
        break
    else
        retry_count=$((retry_count + 1))
        log "⏳ Kokoro not ready, retrying in 5 seconds... ($retry_count/$max_retries)"
        sleep 5
    fi
done

if [ $retry_count -eq $max_retries ]; then
    log "❌ Kokoro failed to start after 1 minute"
    exit 1
fi

# Test LiveKit endpoint with retries
retry_count=0
log "🧪 Testing LiveKit endpoint..."
while [ $retry_count -lt $max_retries ]; do
    if curl -s --connect-timeout 3 "http://127.0.0.1:7880/" > /dev/null 2>&1; then
        log "✅ LiveKit server is ready"
        break
    else
        retry_count=$((retry_count + 1))
        log "⏳ LiveKit not ready, retrying in 5 seconds... ($retry_count/$max_retries)"
        sleep 5
    fi
done

if [ $retry_count -eq $max_retries ]; then
    log "❌ LiveKit failed to start after 1 minute (nothing answered on http://127.0.0.1:7880/)"
    log "   See docker logs for the livekit container — common fixes: API secret >=32 chars in livekit.yaml; rtc.node_ip (not external_ip) for newer livekit-server"
    exit 1
fi

# 6. Start the LiveKit Python Agent
log "🤖 Starting LiveKit Python agent..."
cd "$SCRIPT_DIR/agent-starter-python"

if [ ! -d ".venv" ]; then
    log "❌ Virtual environment not found at $SCRIPT_DIR/agent-starter-python/.venv"
    exit 1
fi

log "📂 Activating virtual environment..."
source .venv/bin/activate

log "🔧 Agent reads .env.local via Python (see api_server / agent entrypoint)"
log "🎯 Starting agent in development mode (noise cancellation disabled for stability)..."
python -m src.agent dev 2>&1 | tee -a "$LOG_FILE" &
log "   Agent running in background (stop: pkill -f \"src.agent dev\")"

# 7. Start the FastAPI Interview API Server
log "📡 Starting FastAPI Interview API Server..."
cd "$SCRIPT_DIR/agent-starter-python"

if [ ! -d ".venv" ]; then
    log "❌ Virtual environment not found at $SCRIPT_DIR/agent-starter-python/.venv"
    exit 1
fi

log "📂 Activating virtual environment..."
source .venv/bin/activate

log "🚀 Starting API server (production mode: reload disabled)..."
export API_RELOAD=0
# Honor API_PORT from .env.local (loaded inside Python); default in api_server is 8000 if unset
python api_server.py 2>&1 | tee -a "$LOG_FILE"
