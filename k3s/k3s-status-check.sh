#!/bin/bash

# k3s 클러스터 상태 확인 스크립트
set -e

MASTER_IP="10.0.1.54"

echo "Checking k3s cluster status..."

# k3s 서비스 상태 확인
ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "sudo systemctl status k3s"

# kubectl 노드 상태 확인
ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "kubectl get nodes"

# kubectl 파드 상태 확인
ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "kubectl get pods --all-namespaces"

# Rocket.Chat 파드 상태 확인
ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "kubectl get pods -n rocketchat"

echo "k3s cluster status check completed" 