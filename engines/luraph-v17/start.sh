#!/bin/bash
set -e

echo "Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "Installing Lua 5.1..."
apt-get update
apt-get install -y lua5.1

echo "Installing Node dependencies..."
npm ci --only=production

echo "Starting Node.js server..."
exec node server.js
