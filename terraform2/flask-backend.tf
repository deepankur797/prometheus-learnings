# flask-backend deployment
resource "kubernetes_deployment" "flask_deployment" {
  metadata {
    name = "flask-deployment"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "flask"
      }
    }

    template {
      metadata {
        labels = {
          app = "flask"
        }
      }

      spec {
        container {
          name  = "flask"
          image = "deepankur797/flask-backend:v1"

          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

# flask-backend service 

resource "kubernetes_service" "flask_service" {
  metadata {
    name = "flask-service"

    labels = {
      app = "flask"

      name = "flask-service"
    }

    annotations = {
      "prometheus.io/scrape" = "true"
    }
  }

  spec {
    port {
      name        = "custom-scrape"
      protocol    = "TCP"
      port        = 5000
      target_port = "5000"
      node_port   = 32000
    }

    selector = {
      app = "flask"
    }

    type = "NodePort"
  }
}

