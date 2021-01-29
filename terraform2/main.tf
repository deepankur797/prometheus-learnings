provider "google" {

	project = var.project_id
	region = var.region
}

#creating the GKE Cluster

resource "google_container_cluster" "primary" {
	name= "experimental-k8s-cluster"
	location = var.region
	
	remove_default_node_pool = true
	initial_node_count = 1

	network = "default"
	subnetwork = "default"
	
	master_auth {
		username = var.gke_username
		password = var.gke_password
		
		client_certificate_config {
			issue_client_certificate = false
		}
	}
}

#Node pool for our cluster

resource "google_container_node_pool" "primary_nodes" {
	name = "${google_container_cluster.primary.name}-node-pool"
	location = var.region
	cluster = google_container_cluster.primary.name
	node_count = var.gke_num_nodes

	node_config {
	
	 oauth_scopes = [ "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring",]
	
	 labels = {
      		env = var.project_id
    	 }

	#preemptible  = true
	machine_type = "n1-standard-1"
	tags         = ["gke-node", "${var.project_id}-gke"]
	metadata = {
      		disable-legacy-endpoints = "true"
    	}
  	}
}

provider "kubernetes" {
	#load_config_file = "false"

	host     = google_container_cluster.primary.endpoint
	username = var.gke_username
	password = var.gke_password
	client_certificate     = base64decode(google_container_cluster.primary.master_auth.0.client_certificate)
	client_key             = base64decode(google_container_cluster.primary.master_auth.0.client_key)
	cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

