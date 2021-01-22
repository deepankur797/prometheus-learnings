variable "project_id"{
	description = "Project Id for resources"
}

variable "region"{
	description = "Region in which you want to deploy"
}

variable "gke_username" {

	description ="Google username"
}

variable "gke_password" {

	description ="Google account password"
}

variable "gke_num_nodes" {
	default = 1
	description = " number of GKE nodes"
}


