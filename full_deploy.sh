#!/bin/bash

# ==========================================
# JTX Full System Deployment Script
# ==========================================

set -e # Exit on error
trap "" HUP # Ignore SIGHUP to prevent Hangup when SSH disconnects

WORK_DIR="/opt/jtx"
SOURCE_ZIP="source_code.zip"
SOURCE_DIR="IdeaProjects"

echo "=========================================="
echo "Starting JTX Full System Deployment"
echo "=========================================="

# 0. Free up Memory
echo "[0/6] Cleaning up system memory..."
sync
echo 3 > /proc/sys/vm/drop_caches
# Kill any lingering Maven builds
pkill -f "plexus-classworlds" || true

# 0.1 Create Swap (Critical for low memory servers)
if ! swapon -s | grep -q "/swapfile"; then
    echo "[0.1/6] Creating 4GB Swap file to prevent OOM..."
    dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
else
    echo "[0.1/6] Swap file already exists."
fi

# 1. Prepare Directories
echo "[1/6] Preparing directories..."
mkdir -p $WORK_DIR/logs
mkdir -p $WORK_DIR/data
mkdir -p $WORK_DIR/html
cd $WORK_DIR

# 2. Extract Source Code
if [ -f "$SOURCE_ZIP" ]; then
    echo "[2/6] Extracting source code..."
    # Install unzip if not present
    if ! command -v unzip &> /dev/null; then
        yum install -y unzip
    fi
    unzip -o $SOURCE_ZIP
    rm $SOURCE_ZIP
else
    echo "Warning: $SOURCE_ZIP not found. Assuming source code is already in $SOURCE_DIR"
fi

# 2.1 Extract Local Repository
REPO_ZIP="repo.zip"
if [ -d "$WORK_DIR/repo" ]; then
    echo "[2.1/6] Local repository 'repo' already exists. Skipping extraction."
elif [ -f "$REPO_ZIP" ]; then
    echo "[2.1/6] Extracting local repository..."
    unzip -q -o $REPO_ZIP
    
    # FIX: Remove _remote.repositories and .lastUpdated to force Maven to use local artifacts
    echo "[Fix] Cleaning up local repository metadata..."
    find $WORK_DIR/repo -name "_remote.repositories" -type f -delete
    find $WORK_DIR/repo -name "*.lastUpdated" -type f -delete
else
    echo "Warning: $REPO_ZIP not found. Build might fail if private dependencies are missing."
fi

# 2.2 Extract Local Frontend Dependency
FRAMEWORK_ZIP="hyida-element-framework.zip"
if [ -d "$WORK_DIR/hyida-element-framework" ]; then
    echo "[2.2/6] Local frontend framework already exists. Skipping extraction."
elif [ -f "$FRAMEWORK_ZIP" ]; then
    echo "[2.2/6] Extracting local frontend framework..."
    unzip -q -o $FRAMEWORK_ZIP -d $WORK_DIR/hyida-element-framework
else
    echo "Warning: $FRAMEWORK_ZIP not found. Frontend build might fail."
fi

# 3. Setup Environment (Maven & Node)
echo "[3/6] Checking build environment..."

# Install screen for persistent sessions
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    yum install -y screen
fi

# Limit Maven Memory to prevent OOM (Reduced to 512m + SerialGC)
export MAVEN_OPTS="-Xmx512m -Xms256m -XX:+UseSerialGC"

# ... (keep existing Maven/Node install checks) ...

# 4. Compile Backend
echo "[4/6] Compiling Backend Services..."
cd $SOURCE_DIR

modules=("jtx_mct" "jtx-pms" "jtx-erp" "jtx-srm" "jtx-mdm" "jtx-oa" "jtx-sso")

# Debug: Check if repo exists and specific jar is there
echo "[Debug] Checking local repository content..."
if [ -d "$WORK_DIR/repo" ]; then
    echo "Repo directory exists."
    echo "Checking for critical dependency:"
    find "$WORK_DIR/repo" -name "hyida-mct-plugin-interface-1.18.7.jar"
else
    echo "ERROR: Repo directory $WORK_DIR/repo does NOT exist!"
fi

# for mod in "${modules[@]}"; do
#     # Aggressive memory cleanup before each module
#     sync && echo 3 > /proc/sys/vm/drop_caches
#     
#     if [ -d "$mod" ]; then
#         echo "Building $mod..."
#         cd $mod
#         # Use single thread (-T 1) and skip test compilation to save memory
#         mvn clean package -Dmaven.test.skip=true -Dmaven.repo.local=$WORK_DIR/repo -U -T 1
#         cd ..
#     else
#         echo "Warning: Module $mod not found!"
#     fi
# done

# 5. Build Frontend
echo "[5/6] Building Frontend Applications..."

frontend_modules=("jtx_mct_ui" "jtx-pms-ui" "jtx-erp-ui" "jtx-srm-ui" "jtx-mdm-ui" "jtx-oa-ui")
target_html_dirs=("mct" "pms" "erp" "srm" "mdm" "oa")

for i in "${!frontend_modules[@]}"; do
    mod="${frontend_modules[$i]}"
    target="${target_html_dirs[$i]}"
    
    if [ -d "$mod" ]; then
        echo "Building $mod..."
        cd $mod
        
        # Clean install to avoid conflicts
        echo "Cleaning node_modules..."
        rm -rf node_modules package-lock.json

        # Fix: Modify package.json to point to local framework path
        # This ensures 'npm install' installs BOTH the local package AND devDependencies (like vue-cli-service)
        if [ -d "$WORK_DIR/hyida-element-framework" ]; then
            echo "Updating package.json to use local hyida-element-framework..."
            sed -i 's|"hyida-element-framework":.*|"hyida-element-framework": "file:/opt/jtx/hyida-element-framework",|g' package.json
        fi
        
        echo "Installing all dependencies..."
        # Use --no-progress to reduce output and load, and redirect stdin to prevent Hangup
        npm install --registry=https://registry.npmmirror.com --unsafe-perm --no-progress < /dev/null
        
        # Increase Node memory to prevent OOM
        echo "Building production build..."
        NODE_OPTIONS="--max_old_space_size=4096" npm run build:prod < /dev/null
        
        echo "Deploying to html/$target..."
        mkdir -p $WORK_DIR/html/$target
        cp -r dist/* $WORK_DIR/html/$target/
        cd ..
    else
        echo "Warning: Frontend module $mod not found!"
    fi
done

# 6. Start Docker Services
echo "[6/6] Starting Docker Services..."
cd $WORK_DIR
docker compose down
docker compose up -d --build

echo "=========================================="
echo "Deployment Complete!"
echo "Access the system at http://47.92.96.143"
echo "=========================================="
