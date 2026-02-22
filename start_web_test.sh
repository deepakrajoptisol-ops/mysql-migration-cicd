#!/bin/bash
# =============================================================================
# Migration Management Web UI Startup Script - TEST ENVIRONMENT
# Starts the FastAPI web application for migration management using test DB
# =============================================================================

export ENVIRONMENT=test
echo "🧪 Starting Migration Management Web UI in TEST environment..."
./start_web.sh