#!/bin/bash

# k3s Worker Node 설치 및 설정 스크립트
set -e

# 시스템 업데이트
apt-get update
apt-get upgrade -y

# k3s worker 설치
curl -sfL https://get.k3s.io | K3S_URL=https://${master_ip}:6443 K3S_TOKEN=PLACEHOLDER sh -

# 로그 정리
echo "k3s worker installation completed" > /var/log/k3s-worker-setup.log