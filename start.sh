#!/usr/bin/env bash
set -e

echo "[CIMS] -> checking dependencies..."
if [ ! -d "node_modules" ]; then
  echo "[CIMS] -> installing npm packages..."
  npm install
else
  echo "[CIMS] -> node_modules found, skipping npm install."
fi

echo "[CIMS] -> starting application..."
npm run start
