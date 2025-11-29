#!/bin/bash

# ==========================================
# JTX Quick Deployment Script (Minimal Version)
# ==========================================

echo "=========================================="
echo "JTX System Quick Deployment"
echo "=========================================="

# 1. Create necessary directories
echo "[1/6] Creating directories..."
mkdir -p data/mysql data/redis data/rocketmq/{logs,store}
mkdir -p logs/{mct,pms,erp,srm,mdm,oa,sso,nginx}
mkdir -p html/{portal,mct,pms,erp,srm,mdm,oa}
mkdir -p conf

# 2. Download sample frontend (placeholder)
echo "[2/6] Preparing frontend files..."
cat > html/portal/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>焦甜香企业管理平台</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        h1 { font-size: 48px; margin-bottom: 20px; }
        .modules { display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; margin-top: 40px; }
        .module { background: rgba(255,255,255,0.2); padding: 30px; border-radius: 10px; width: 200px; cursor: pointer; transition: 0.3s; }
        .module:hover { background: rgba(255,255,255,0.3); transform: translateY(-5px); }
    </style>
</head>
<body>
    <h1>🏭 焦甜香企业管理平台</h1>
    <p>欢迎使用焦甜香企业集成管理系统</p>
    <div class="modules">
        <div class="module" onclick="alert('MCT模块开发中')"><h3>📊 MCT</h3><p>实验室管理</p></div>
        <div class="module" onclick="alert('PMS模块开发中')"><h3>🏭 PMS</h3><p>生产制造</p></div>
        <div class="module" onclick="alert('ERP模块开发中')"><h3>💼 ERP</h3><p>企业资源</p></div>
        <div class="module" onclick="alert('SRM模块开发中')"><h3>🤝 SRM</h3><p>供应商管理</p></div>
        <div class="module" onclick="alert('MDM模块开发中')"><h3>📁 MDM</h3><p>主数据</p></div>
        <div class="module" onclick="alert('OA模块开发中')"><h3>📝 OA</h3><p>办公自动化</p></div>
    </div>
    <p style="margin-top: 50px; opacity: 0.8;">系统部署成功 ✓</p>
</body>
</html>
EOF

# 3. Create Nginx config
echo "[3/6] Creating Nginx configuration..."
cat > conf/nginx.conf <<'EOF'
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
    client_max_body_size 500m;

    server {
        listen       80;
        server_name  localhost;
        
        location / {
            root   /usr/share/nginx/html/portal;
            index  index.html;
        }
        
        location /api/ {
            return 200 '{"status":"ok","message":"Backend services will be available after full deployment"}';
            add_header Content-Type application/json;
        }
    }
}
EOF

# 4. Create RocketMQ config
echo "[4/6] Creating RocketMQ configuration..."
cat > conf/broker.conf <<'EOF'
brokerClusterName = DefaultCluster
brokerName = broker-a
brokerId = 0
deleteWhen = 04
fileReservedTime = 48
brokerRole = ASYNC_MASTER
flushDiskType = ASYNC_FLUSH
EOF

# 5. Create docker-compose (minimal version)
echo "[5/6] Creating docker-compose configuration..."
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:5.7
    container_name: jtx-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: jtx@2024
      MYSQL_DATABASE: jtx_mct
    ports:
      - "3306:3306"
    volumes:
      - ./data/mysql:/var/lib/mysql
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

  redis:
    image: redis:6.2
    container_name: jtx-redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - ./data/redis:/data
    command: redis-server --appendonly yes

  nginx:
    image: nginx:1.21
    container_name: jtx-nginx
    restart: always
    ports:
      - "80:80"
    volumes:
      - ./conf/nginx.conf:/etc/nginx/nginx.conf
      - ./html:/usr/share/nginx/html
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - mysql
      - redis
EOF

# 6. Start services
echo "[6/6] Starting services..."
docker-compose up -d

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "🌐 Access URL: http://47.92.96.143"
echo ""
echo "📊 Service Status:"
docker-compose ps
echo ""
echo "💡 Next Steps:"
echo "   - Visit http://47.92.96.143 to verify deployment"
echo "   - Check logs: docker-compose logs -f"
echo "   - Stop services: docker-compose down"
echo ""
