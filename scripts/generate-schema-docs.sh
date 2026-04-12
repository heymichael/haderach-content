#!/usr/bin/env bash
set -euo pipefail

# Regenerate SchemaSpy database documentation.
#
# Prerequisites:
#   - Cloud SQL Proxy running on localhost:5432
#   - PGPASSWORD environment variable set
#
# Usage:
#   export PGPASSWORD="<password>"
#   ./scripts/generate-schema-docs.sh

cd "$(dirname "$0")/.."

: "${PGPASSWORD:?Set PGPASSWORD environment variable}"
PGUSER="${PGUSER:-haderach-app}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-5432}"
PGDATABASE="${PGDATABASE:-haderach}"

echo "Generating SchemaSpy docs..."
echo "  Host: $PGHOST:$PGPORT"
echo "  Database: $PGDATABASE"
echo "  User: $PGUSER"
echo "  Output: public/db-schema/"

docker run --rm --network host \
  -v "$(pwd)/public/db-schema:/output" \
  schemaspy/schemaspy:latest \
  -t pgsql11 \
  -host "$PGHOST" \
  -port "$PGPORT" \
  -db "$PGDATABASE" \
  -s public \
  -u "$PGUSER" \
  -p "$PGPASSWORD" \
  -desc "Transformation Platform" \
  -o /output

echo "Done. Output written to public/db-schema/"
