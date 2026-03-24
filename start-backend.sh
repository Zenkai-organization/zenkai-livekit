#!/bin/bash

# start-backend.sh
# This script starts the local AI services (Docker) and the LiveKit Python agent.

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
    if curl -s http://localhost:7880 > /dev/null 2>&1; then
        log "✅ LiveKit server is ready"
        break
    else
        retry_count=$((retry_count + 1))
        log "⏳ LiveKit not ready, retrying in 5 seconds... ($retry_count/$max_retries)"
        sleep 5
    fi
done

if [ $retry_count -eq $max_retries ]; then
    log "❌ LiveKit failed to start after 1 minute"
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

log "🔧 Environment variables loaded from .env.local"
log "🎯 Starting agent in development mode (noise cancellation disabled for stability)..."
python -m src.agent dev 2>&1 | tee -a "$LOG_FILE"
