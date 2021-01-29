# Resources for Prometheus and Node exporter
#namespace creation
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# cluster Role for prometheus
resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }

  rule {
    verbs             = ["get"]
    non_resource_urls = ["/metrics"]
  }
	depends_on =[kubernetes_namespace.monitoring]
}

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "monitoring"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "prometheus"
  }
        depends_on =[kubernetes_namespace.monitoring]
}

# config map for creating configuration of prometheus deployment
resource "kubernetes_config_map" "prometheus_server_conf" {
  metadata {
    name      = "prometheus-server-conf"
    namespace = "monitoring"

    labels = {
      name = "prometheus-server-conf"
    }
  }

  data = {
    "prometheus.yml" = "global:\n  scrape_interval: 5s\n  evaluation_interval: 5s\nrule_files:\n  # Rules are empty for now \n\nscrape_configs:\n  - job_name: 'prometheus'\n    static_configs:\n      - targets: ['localhost:9090']\n  - job_name: 'kubernetes-apiservers'\n\n    kubernetes_sd_configs:\n    - role: endpoints\n    scheme: https\n\n    tls_config:\n      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n\n    relabel_configs:\n    - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]\n      action: keep\n      regex: default;kubernetes;https\n\n  - job_name: 'kubernetes-nodes'\n\n    scheme: https\n\n    tls_config:\n      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n\n    kubernetes_sd_configs:\n    - role: node\n\n    relabel_configs:\n    - action: labelmap\n      regex: __meta_kubernetes_node_label_(.+)\n    - target_label: __address__\n      replacement: kubernetes.default.svc:443\n    - source_labels: [__meta_kubernetes_node_name]\n      regex: (.+)\n      target_label: __metrics_path__\n      replacement: /api/v1/nodes/$${1}/proxy/metrics\n\n  \n  - job_name: 'kubernetes-pods'\n\n    kubernetes_sd_configs:\n    - role: pod\n\n    relabel_configs:\n    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]\n      action: keep\n      regex: true\n    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]\n      action: replace\n      target_label: __metrics_path__\n      regex: (.+)\n    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]\n      action: replace\n      regex: ([^:]+)(?::\\d+)?;(\\d+)\n      replacement: $1:$2\n      target_label: __address__\n    - action: labelmap\n      regex: __meta_kubernetes_pod_label_(.+)\n    - source_labels: [__meta_kubernetes_namespace]\n      action: replace\n      target_label: kubernetes_namespace\n    - source_labels: [__meta_kubernetes_pod_name]\n      action: replace\n      target_label: kubernetes_pod_name\n\n  - job_name: 'kube-state-metrics'\n    static_configs:\n      - targets: ['kube-state-metrics.kube-system.svc.cluster.local:8080']      \n  - job_name: 'kubernetes-cadvisor'\n\n    scheme: https\n\n    tls_config:\n      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n\n    kubernetes_sd_configs:\n    - role: node\n\n    relabel_configs:\n    - action: labelmap\n      regex: __meta_kubernetes_node_label_(.+)\n    - target_label: __address__\n      replacement: kubernetes.default.svc:443\n    - source_labels: [__meta_kubernetes_node_name]\n      regex: (.+)\n      target_label: __metrics_path__\n      replacement: /api/v1/nodes/$${1}/proxy/metrics/cadvisor\n  \n  - job_name: 'kubernetes-service-endpoints'\n\n    kubernetes_sd_configs:\n    - role: endpoints\n\n    relabel_configs:\n    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]\n      action: keep\n      regex: true\n    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]\n      action: replace\n      target_label: __scheme__\n      regex: (https?)\n    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]\n      action: replace\n      target_label: __metrics_path__\n      regex: (.+)\n    - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]\n      action: replace\n      target_label: __address__\n      regex: ([^:]+)(?::\\d+)?;(\\d+)\n      replacement: $1:$2\n    - action: labelmap\n      regex: __meta_kubernetes_service_label_(.+)\n    - source_labels: [__meta_kubernetes_namespace]\n      action: replace\n      target_label: kubernetes_namespace\n    - source_labels: [__meta_kubernetes_service_name]\n      action: replace\n      target_label: kubernetes_name"
  }
        depends_on =[kubernetes_namespace.monitoring]
}

# prometheus-deployment

resource "kubernetes_deployment" "prometheus_deployment" {
  metadata {
    name      = "prometheus-deployment"
    namespace = "monitoring"

    labels = {
      app = "prometheus-server"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus-server"
        }
      }

      spec {
        volume {
          name = "prometheus-config-volume"

          config_map {
            name         = "prometheus-server-conf"
            default_mode = "0644"
          }
        }

        volume {
          name = "prometheus-storage-volume"
        }

        container {
          name  = "prometheus"
          image = "prom/prometheus"
          args  = ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus/"]

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "prometheus-config-volume"
            mount_path = "/etc/prometheus/"
          }

          volume_mount {
            name       = "prometheus-storage-volume"
            mount_path = "/prometheus/"
          }
        }
      }
    }
  }
        depends_on =[kubernetes_namespace.monitoring]

}


#PRometheus service 

resource "kubernetes_service" "prometheus_service" {
  metadata {
    name      = "prometheus-service"
    namespace = "monitoring"

    annotations = {
      "prometheus.io/port" = "9090"

      "prometheus.io/scrape" = "true"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 9090
      target_port = "9090"
      node_port   = 30001
    }

    selector = {
      app = "prometheus-server"
    }

    type = "NodePort"
  }
        depends_on =[kubernetes_namespace.monitoring]

}

# Adding node-exporter

resource "kubernetes_service" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = "monitoring"

    labels = {
      app = "node-exporter"

      name = "node-exporter"
    }

    annotations = {
      "prometheus.io/scrape" = "true"
    }
  }

  spec {
    port {
      name     = "scrape"
      protocol = "TCP"
      port     = 9100
    }

    selector = {
      app = "node-exporter"
    }

    cluster_ip = "None"
    type       = "ClusterIP"
  }
        depends_on =[kubernetes_namespace.monitoring]
}

resource "kubernetes_daemonset" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = "monitoring"
  }

  spec {
    selector {
      match_labels = {
        app = "node-exporter"
      }
    }

    template {
      metadata {
        name = "node-exporter"

        labels = {
          app = "node-exporter"
        }
      }

      spec {
        container {
          name  = "node-exporter"
          image = "prom/node-exporter"

          port {
            name           = "scrape"
            host_port      = 9100
            container_port = 9100
          }
        }

        host_network = true
        host_pid     = true
      }
    }
  }
        depends_on = [
		kubernetes_namespace.monitoring
		]

}



