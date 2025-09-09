#!/bin/bash

# Redis 설치 및 설정 스크립트
set -e

# 시스템 업데이트
apt-get update
apt-get upgrade -y

# Redis 설치
apt-get install -y redis-server

# Redis 설정 파일 수정
cat > /etc/redis/redis.conf << EOF
# Redis 설정
bind 0.0.0.0
port 6379
timeout 0
tcp-keepalive 300

# 메모리 설정
maxmemory 256mb
maxmemory-policy allkeys-lru

# 로그 설정
loglevel notice
logfile /var/log/redis/redis-server.log

# 데이터 저장 설정
save 900 1
save 300 10
save 60 10000

# 보안 설정
requirepass rocketchat123

# 데이터 디렉토리
dir /var/lib/redis
EOF

# 데이터 볼륨 마운트 (EBS 볼륨이 /dev/sdf로 연결됨)
mkfs.ext4 /dev/sdf
mkdir -p /data
mount /dev/sdf /data
echo '/dev/sdf /data ext4 defaults,nofail 0 2' >> /etc/fstab

# Redis 데이터 디렉토리 변경
systemctl stop redis-server
mkdir -p /data/redis
chown -R redis:redis /data/redis

# Redis 설정 파일에서 데이터 디렉토리 변경
sed -i 's|dir /var/lib/redis|dir /data/redis|g' /etc/redis/redis.conf

# Redis 서비스 시작 및 활성화
systemctl start redis-server
systemctl enable redis-server

# Redis 연결 테스트
redis-cli -a rocketchat123 ping

# 로그 정리
echo "Redis installation and configuration completed" > /var/log/redis-setup.log
