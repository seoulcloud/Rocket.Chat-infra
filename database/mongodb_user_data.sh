#!/bin/bash

# MongoDB 설치 및 설정 스크립트
set -e

# 시스템 업데이트
apt-get update
apt-get upgrade -y

# MongoDB GPG 키 추가
wget -qO - https://www.mongodb.org/static/pgp/server-${mongodb_version}.asc | apt-key add -

# MongoDB 저장소 추가
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/${mongodb_version} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${mongodb_version}.list

# MongoDB 설치
apt-get update
apt-get install -y mongodb-org

# MongoDB 서비스 시작 및 활성화
systemctl start mongod
systemctl enable mongod

# 데이터 볼륨 마운트 (EBS 볼륨이 /dev/sdf로 연결됨)
mkfs.ext4 /dev/sdf
mkdir -p /data
mount /dev/sdf /data
echo '/dev/sdf /data ext4 defaults,nofail 0 2' >> /etc/fstab

# MongoDB 데이터 디렉토리 변경
systemctl stop mongod
mkdir -p /data/mongodb
chown -R mongodb:mongodb /data/mongodb

# MongoDB 설정 파일 수정
cat > /etc/mongod.conf << EOF
storage:
  dbPath: /data/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled

replication:
  replSetName: "rs0"
EOF

# MongoDB 서비스 재시작
systemctl start mongod

# MongoDB 복제본 세트 초기화
sleep 30
mongo --eval "rs.initiate()"

# Rocket.Chat용 사용자 생성
mongo --eval "
use admin;
db.createUser({
  user: 'rocketchat',
  pwd: 'rocketchat123',
  roles: [
    { role: 'readWrite', db: 'rocketchat' },
    { role: 'dbAdmin', db: 'rocketchat' }
  ]
});
"

# 로그 정리
echo "MongoDB installation and configuration completed" > /var/log/mongodb-setup.log