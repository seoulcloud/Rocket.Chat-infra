# k3s 설치를 위한 Ansible Playbook (선택사항)
resource "local_file" "k3s_ansible_playbook" {
  content = templatefile("${path.module}/k3s-install.yml", {
    master_ip = var.k3s_master_ip
  })
  filename = "${path.module}/k3s-install.yml"
}

# k3s 클러스터 상태 확인을 위한 스크립트
resource "local_file" "k3s_status_check" {
  content = templatefile("${path.module}/k3s-status-check.sh", {
    master_ip = var.k3s_master_ip
  })
  filename = "${path.module}/k3s-status-check.sh"
}

# Rocket.Chat Helm Chart Values
resource "local_file" "rocketchat_helm_values" {
  content = templatefile("${path.module}/rocketchat-values.yaml", {
    mongodb_url = var.mongodb_url
    redis_url   = var.redis_url
  })
  filename = "${path.module}/rocketchat-values.yaml"
}

# Prometheus Helm Chart Values
resource "local_file" "prometheus_helm_values" {
  content = templatefile("${path.module}/prometheus-values.yaml", {})
  filename = "${path.module}/prometheus-values.yaml"
}

# Grafana Helm Chart Values
resource "local_file" "grafana_helm_values" {
  content = templatefile("${path.module}/grafana-values.yaml", {})
  filename = "${path.module}/grafana-values.yaml"
} 