#!/bin/bash

# monitor-services.sh - Monitor LiveKit services health

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="$SCRIPT_DIR/service-monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_service() {
    local service_name=$1
    local url=$2
    local expected_pattern=$3
    
    if curl -s "$url" | grep -q "$expected_pattern"; then
        log "✅ $service_name: HEALTHY"
        return 0
    else
        log "❌ $service_name: FAILED"
        return 1
    fi
}

log "🔍 Starting service health check..."

# Check Docker containers
log "📦 Checking Docker containers..."
docker compose -f "$SCRIPT_DIR/docker-compose.yaml" ps >> "$LOG_FILE" 2>&1

# Check services
whisper_ok=false
kokoro_ok=false

if check_service "Whisper API" "http://localhost:8080/v1/models" "whisper"; then
    whisper_ok=true
fi

if check_service "Kokoro API" "http://localhost:8888/v1/models" "kokoro"; then
    kokoro_ok=true
fi

# Check system resources
log "💾 System resources:"
echo "Memory: $(free -h | grep Mem)" >> "$LOG_FILE" 2>&1
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% used" >> "$LOG_FILE" 2>&1
echo "Disk: $(df -h / | tail -1 | awk '{print $5}')" >> "$LOG_FILE" 2>&1

if [ "$whisper_ok" = true ] && [ "$kokoro_ok" = true ]; then
    log "🎉 All services healthy"
    exit 0
else
    log "⚠️  Some services are unhealthy"
    exit 1
fi