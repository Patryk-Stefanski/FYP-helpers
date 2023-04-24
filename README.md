# FYP Helpers
This repository contains various manifests and scripts to aid in the deployment of tools necessary for the GitOps implementation of the Covid-19 Statistics web application. These tools include ArgoCD, Prometheus, Grafana, and NGINX Ingress Controllers.

## Manifests
The manifests directory contains the Kubernetes manifests necessary to deploy the various tools required for the GitOps implementation. The following manifests are included:

argocd: Contains the manifests necessary to deploy ArgoCD.
kuber-prometheus: Contains the manifests necessary to deploy Grafana and Prometheus.
nginx: Contains the manifests necessary to deploy an NGINX Ingress Controller.

## Configuration
The argo directory contains a YAML file used to configure ArgoCD. This file specifies the Git repository source and target revision, as well as the Helm chart values and parameters. The manifest also includes the Kubernetes cluster and namespace to deploy the application to, and specifies the synchronization options for the deployment.

## Deployment Script
The prepare-cluster.sh script automates the deployment of the GitOps stack. This script will create a KinD cluster and deploy ArgoCD, Prometheus and Grafana to your Kubernetes cluster while also port forwarding them.
Tis script also retrieves the necessary passwords for different services and prints the links for accessing them.

To use the script, simply run the command `.scripts/prepare-cluster.sh` from the root directory of the project.

