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

# 3. Wait for services to be ready
log "⏳ Waiting for local AI services to initialize..."
sleep 5

# 4. Test Whisper endpoint
log "🧪 Testing Whisper endpoint..."
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    log "✅ Whisper is responding"
else
    log "⚠️  Whisper health check failed (may still be starting)"
fi

# 5. Test Kokoro endpoint
log "🧪 Testing Kokoro endpoint..."
if curl -s http://localhost:8888/ > /dev/null 2>&1; then
    log "✅ Kokoro is responding"
else
    log "⚠️  Kokoro health check failed (may still be starting)"
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
log "🎯 Starting agent in development mode..."
python src/agent.py dev 2>&1 | tee -a "$LOG_FILE"
