#!/bin/bash
# =============================================================================
# Migration Management Web UI Startup Script
# Starts the FastAPI web application for migration management
# =============================================================================

set -e

echo "🚀 Starting Migration Management Web UI..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run:"
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
    echo "   pip install -r web/requirements.txt"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Install web requirements if not already installed
pip install -r web/requirements.txt > /dev/null 2>&1

# Load environment variables
if [ -f "env.local" ]; then
    export $(cat env.local | grep -v '^#' | xargs)
    echo "✅ Loaded environment from env.local"
else
    echo "⚠️ No env.local found, using defaults"
    export DB_HOST=127.0.0.1
    export DB_PORT=3307
    export DB_USER=root
    export DB_PASSWORD=testpw
    export DB_NAME=migration_db
fi

# Check database connection
echo "🔍 Checking database connection..."
python -c "
import sys
sys.path.append('.')
from src.db import get_conn
try:
    conn = get_conn()
    conn.close()
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    sys.exit(1)
"

# Start the web application
echo "🌐 Starting web server on http://localhost:8000"
echo "📊 Migration Management UI will be available at http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

cd web && python app.py