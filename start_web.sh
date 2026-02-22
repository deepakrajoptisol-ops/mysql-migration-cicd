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
ENVIRONMENT=${ENVIRONMENT:-dev}
if [ "$ENVIRONMENT" = "test" ] && [ -f "env.test" ]; then
    export $(cat env.test | grep -v '^#' | xargs)
    echo "✅ Loaded test environment from env.test"
elif [ -f "env.local" ]; then
    export $(cat env.local | grep -v '^#' | xargs)
    echo "✅ Loaded dev environment from env.local"
else
    echo "⚠️ No environment file found, using defaults"
    export DB_HOST=sql12.freesqldatabase.com
    export DB_PORT=3306
    export DB_USER=sql12817767
    export DB_PASSWORD=Ajb7KukR9R
    export DB_NAME=sql12817767
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