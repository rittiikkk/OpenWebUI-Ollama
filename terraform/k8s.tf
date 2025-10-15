# terraform/k8s.tf
# Kubernetes provider config that talks to the EKS cluster created earlier.
provider "kubernetes" {
  host                   = aws_eks_cluster.openwebui.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.openwebui.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.openwebui.token

  # optional: add timeouts if cluster creation takes long
  # experiments {
  #   manifest_resource = true
  # }
}
data "aws_eks_cluster_auth" "openwebui" {
  name = aws_eks_cluster.openwebui.name
}
resource "kubernetes_secret" "openwebui_secret" {
  metadata {
    name      = "openwebui-secret"
    namespace = "default"
  }

  data = {
    WEBUI_SECRET_KEY = random_password.webui_secret.result
  }

  type = "Opaque"
}

# Random password generator for the secret
resource "random_password" "webui_secret" {
  length           = 32
  special          = true
  override_special = "_-"
}
# Create ConfigMap (replaces openwebui-config.yaml)
resource "kubernetes_config_map" "openwebui_config" {
  metadata {
    name = "openwebui-config"
  }

  data = {
    ollama_url = "http://${aws_instance.ollama.private_ip}:11434"
  }

  depends_on = [
    aws_eks_node_group.default,
    aws_eks_cluster.openwebui
  ]
}

# Deployment (replaces openwebui-deployment.yaml)
resource "kubernetes_deployment" "openwebui" {
  metadata {
    name = "openwebui"
    labels = {
      app = "openwebui"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "openwebui"
      }
    }
    template {
      metadata {
        labels = {
          app = "openwebui"
          secret_version = random_password.webui_secret.result
        }
      }
      spec {
        container {
          name  = "openwebui"
          image = "ghcr.io/open-webui/open-webui:latest"
          port {
            container_port = 3000
          }

          env {
            name  = "OLLAMA_API_BASE_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.openwebui_config.metadata[0].name
                key  = "ollama_url"
              }
            }
          }
          env {
            name  = "WEBUI_SECRET_KEY"
            value_from {
                secret_key_ref {
                  name = kubernetes_secret.openwebui_secret.metadata[0].name
                  key  = "WEBUI_SECRET_KEY"
                }
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 90
            period_seconds        = 15
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }
      }
    }
  }

  wait_for_rollout = true

  depends_on = [
  kubernetes_config_map.openwebui_config,
  kubernetes_secret.openwebui_secret,
  aws_eks_node_group.default
]
}

# Service (replaces openwebui-service.yaml)
resource "kubernetes_service" "openwebui" {
  metadata {
    name = "openwebui"
    labels = {
      app = "openwebui"
    }
    # Optional annotations for LB type (NLB/ALB). For simple tests you can omit.
    # annotations = {
    #   "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    # }
  }

  spec {
    selector = {
      app = kubernetes_deployment.openwebui.spec[0].template[0].metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [
    kubernetes_deployment.openwebui
  ]
}
