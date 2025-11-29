#!/bin/bash

# ==========================================
# JTX Deployment Script
# ==========================================

echo "Starting JTX Deployment..."

# 1. Check Environment
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed."
    exit 1
fi

# 2. Create Directories
echo "Creating data directories..."
mkdir -p data/mysql
mkdir -p data/redis
mkdir -p data/rocketmq/logs
mkdir -p data/rocketmq/store
mkdir -p logs/mct
mkdir -p logs/pms
mkdir -p logs/erp
mkdir -p logs/srm
mkdir -p logs/mdm
mkdir -p logs/oa
mkdir -p logs/sso
mkdir -p logs/nginx
mkdir -p html/portal
mkdir -p html/mct
mkdir -p html/pms
mkdir -p html/erp
mkdir -p html/srm
mkdir -p html/mdm
mkdir -p html/oa

# 3. Build Backend (Optional - if source code is present)
# echo "Building Backend Services..."
# mvn clean package -DskipTests

# 4. Build Frontend (Optional - if source code is present)
# echo "Building Frontend Applications..."
# cd IdeaProjects/jtx_mct_ui && npm install && npm run build:prod && cp -r dist/* ../../html/mct/ && cd ../..
# cd IdeaProjects/jtx-pms-ui && npm install && npm run build:prod && cp -r dist/* ../../html/pms/ && cd ../..
# ... repeat for other UIs

# 5. Start Services
echo "Starting Docker Services..."
docker-compose up -d

echo "Deployment Complete!"
echo "Please visit http://47.92.96.143 to access the system."
