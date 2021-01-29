provider "helm" {
	kubernetes {
	host     = google_container_cluster.primary.endpoint
        username = var.gke_username
        password = var.gke_password
        client_certificate     = base64decode(google_container_cluster.primary.master_auth.0.client_certificate)
        client_key             = base64decode(google_container_cluster.primary.master_auth.0.client_key)
        cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}
}

resource "helm_release" "grafana" {
	name = "grafana"
	chart = "./grafana"
	depends_on =[kubernetes_namespace.monitoring]
}
