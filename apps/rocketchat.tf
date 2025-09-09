# Rocket.Chat Kubernetes Resources

# Rocket.Chat Namespace
resource "kubernetes_namespace" "rocketchat" {
  metadata {
    name = "rocketchat"
  }
}

# Rocket.Chat Service Account with IRSA
resource "kubernetes_service_account" "rocketchat" {
  metadata {
    name      = "rocketchat-sa"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.rocketchat_service_account_role_arn
    }
  }
}

# Rocket.Chat ConfigMap
resource "kubernetes_config_map" "rocketchat_config" {
  metadata {
    name      = "rocketchat-config"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
  }

  data = {
    MONGODB_URL = var.mongodb_url
    REDIS_URL   = var.redis_url
    ROOT_URL    = "https://${var.cloudfront_domain_name}"
    PORT        = "3000"
  }
}

# Rocket.Chat Deployment
resource "kubernetes_deployment" "rocketchat" {
  metadata {
    name      = "rocketchat"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
  }

  spec {
    replicas = var.rocketchat_replicas

    selector {
      match_labels = {
        app = "rocketchat"
      }
    }

    template {
      metadata {
        labels = {
          app = "rocketchat"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.rocketchat.metadata[0].name
        
        container {
          name  = "rocketchat"
          image = "rocketchat/rocket.chat:${var.rocketchat_version}"

          port {
            container_port = 3000
          }

          env {
            name = "MONGO_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.rocketchat_config.metadata[0].name
                key  = "MONGODB_URL"
              }
            }
          }

          env {
            name = "REDIS_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.rocketchat_config.metadata[0].name
                key  = "REDIS_URL"
              }
            }
          }

          env {
            name = "ROOT_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.rocketchat_config.metadata[0].name
                key  = "ROOT_URL"
              }
            }
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.rocketchat_config.metadata[0].name
                key  = "PORT"
              }
            }
          }

          resources {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/api/v1/info"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/api/v1/info"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Rocket.Chat Service
resource "kubernetes_service" "rocketchat" {
  metadata {
    name      = "rocketchat-service"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
  }

  spec {
    selector = {
      app = "rocketchat"
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "NodePort"
  }
}

# Rocket.Chat HPA (Horizontal Pod Autoscaler)
resource "kubernetes_horizontal_pod_autoscaler" "rocketchat" {
  metadata {
    name      = "rocketchat-hpa"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
  }

  spec {
    max_replicas = var.rocketchat_max_replicas
    min_replicas = var.rocketchat_min_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.rocketchat.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
} 