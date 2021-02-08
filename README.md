# Prometheus-Learnings

## Introduction

This repo is built for running an demo instance of prometheus and grafana over an local kind cluster or over Google Cloud Provider. 

## Pre-Requisites

For running locally

- Install kind cluster on your machine. Installation Guide can be found [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- Install kubectl command line

For running on GCP

- Terraform CLI must be installed.Installation Guide can be found [here](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- An Google Account with appropriate privilages to create GKE Clusters.
- Gcloud SDK installed on your machine. Installation Guide can be found [here](https://cloud.google.com/sdk/docs/install)


## Running Locally

- Clone this repo in your working directory
```
git clone https://github.com/deepankur797/prometheus-learnings.git
```
- Create a kind cluster
```
kind create cluster --name "your_cluster_name"
```
- Switch context to your cluster using the following
```
kubectl cluster-info --context kind-your_cluster_name
```
- Create a namespace "monitoring"
```
kubectl create ns monitoring
```
- Switch to prometheus-learning/kubeFiles directory
- Apply all files 
```
kubectl apply -f clusterRole.yaml
kubectl apply -f config-map.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-service.yaml
```

This will create the prometheus deployment. You can access it through kubectl port-forward or at http://{ip-of-kind-cluster-node}:30001


- For installation of grafana, switch to prometheus-learning/grafanaFiles directory and apply the following commands
```
kubectl apply -f grafana-datasource-config.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

You can access this also using kubectl port-forward or at http://{ip-of-kind-cluster-node}:32001


## Running the setup over GCP

- First authenticate terraform using gcloud 
```
gcloud init
gcloud auth application-default login
```
- After the successful login, switch to the directory prometheus-learning/terraform2/
```
terraform init
terraform plan
terraform apply
```
- The following variables will be asked
```
1. project_id = "your_project_id"
2. region = "mention the zone name or region name"  # use region name to create a regional cluster and zone name to create a zonal cluster 
3. gke_username = "" # creds will be applied to virtual machines
4. gke_password = "" # Length of 16, aplha-numeric required
5. gke_num_nodes = "number of nodes" # make it one 
```
- After successful completion of terraform plan you can access the services at 

```
1. Prometheus : http://{node-public-ip}:30001
2. Grafana    : http://{node-public-ip}:32001
```
- As this is a demo cluster hence no load-balancing is used and the services are exposed using node-port type of kubernetes cluster. 
- An simple flask appliction is also exposed in the GCP setup with some custom metrics exposed. And a custom dashboard to monitor these custom metrics is also being imported by default by the name of node-info in grafana.

```
Custom app can be visited at
http://{node-public-ip}:32000
```

# La Fin
