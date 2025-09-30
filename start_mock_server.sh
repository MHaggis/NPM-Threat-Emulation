#!/usr/bin/env bash
# Simple script to start mock server in background
cd "$(dirname "$0")"
python3 mock_server.py --port 8080 >tmp/mock.log 2>&1 &
echo $!
