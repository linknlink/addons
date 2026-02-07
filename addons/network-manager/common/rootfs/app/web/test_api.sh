#!/bin/bash
echo "Testing /api/status..."
curl -s http://localhost:8201/api/status | jq .

echo -e "\nTesting /api/wifi/scan..."
curl -s http://localhost:8201/api/wifi/scan | jq .

echo -e "\nTesting / (Index)..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8201/
echo ""
