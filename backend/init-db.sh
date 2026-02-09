#!/bin/bash
# Database initialization script for telemetry backend
# Run this after fresh clone or when resetting database

set -e

echo "================================================"
echo "Telemetry Backend - Database Initialization"
echo "================================================"

cd "$(dirname "$0")"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    echo "   Please create .env file with required configuration"
    echo "   See README.md for details"
    exit 1
fi

# Check if DATABASE_URL is set
if ! grep -q "^DATABASE_URL=" .env; then
    echo "❌ Error: DATABASE_URL not set in .env"
    exit 1
fi

echo ""
echo "📦 Installing dependencies..."
if command -v uv &> /dev/null; then
    uv sync
else
    pip install -r requirements.txt
fi

echo ""
echo "🗄️  Applying database migrations..."
alembic upgrade head

echo ""
echo "✅ Verifying database schema..."
DATABASE_FILE=$(grep "^DATABASE_URL=" .env | cut -d'/' -f4)

if [ -f "$DATABASE_FILE" ]; then
    echo "   Database file: $DATABASE_FILE"
    echo "   Tables:"
    sqlite3 "$DATABASE_FILE" ".tables" | sed 's/^/   - /'
else
    echo "   ℹ️  Using non-SQLite database (PostgreSQL?)"
fi

echo ""
echo "✅ Database initialization complete!"
echo ""
echo "Next steps:"
echo "  1. Start the server: uvicorn app.main:app --reload"
echo "  2. Access API docs: http://localhost:8000/docs"
echo "  3. Register a device using admin API key"
echo ""
echo "For more information, see:"
echo "  - README.md for quick start"
echo "  - MIGRATIONS.md for database workflow"
echo ""

