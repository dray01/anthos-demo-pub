#!/bin/bash

#Variables

PROJECT_ID=bd-terra04
CLUSTER_NAME=bd-gke-base
CLUSTER_LOCATION=australia-southeast1
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
MESH_ID="proj-${PROJECT_NUMBER}"

# Set default project for gcloud
echo "Setting Project id"
gcloud config set project ${PROJECT_ID}

# Set default location of cluster
echo "set default location for gcloud"
gcloud config set compute/zone ${CLUSTER_LOCATION}

# enable api services on project defined in $PROJECT_ID
gcloud services enable \
	    container.googleapis.com \
	    compute.googleapis.com \
	    monitoring.googleapis.com \
	    logging.googleapis.com \
	    meshca.googleapis.com \
	    meshtelemetry.googleapis.com \
	    meshconfig.googleapis.com \
	    iamcredentials.googleapis.com \
	    anthos.googleapis.com

# Apply mesh-id label
echo "updating gke cluster with mesh label"
gcloud container clusters update ${CLUSTER_NAME} \
	  --region ${CLUSTER_LOCATION} \
	  --update-labels=mesh_id=${MESH_ID} 

# Enable Workload Identity 
echo "update cluster with workload ID"
gcloud container clusters update ${CLUSTER_NAME} \
	  --region ${CLUSTER_LOCATION} \
	  --workload-pool=${WORKLOAD_POOL}

# enable Monitoring
echo "enable stackdriver"
gcloud container clusters update ${CLUSTER_NAME} \
	  --region ${CLUSTER_LOCATION} \
	  --enable-stackdriver-kubernetes

echo "initialising SM on the project"
curl --request POST \
	  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
	  --data '' \
	  https://meshconfig.googleapis.com/v1alpha1/projects/${PROJECT_ID}:initialize \
	  > /dev/null

# Get cluster creds
gcloud container clusters get-credentials ${CLUSTER_NAME}

# Grant admin permissions to current user 
echo "grant permissionsi to cluster"
kubectl create clusterrolebinding cluster-admin-binding \
	  --clusterrole=cluster-admin \
	  --user="$(gcloud config get-value core/account)"

# Download install file
curl -LO https://storage.googleapis.com/gke-release/asm/istio-1.4.7-asm.0-linux.tar.gz

# Extract and add path
tar xzf istio-1.4.7-asm.0-linux.tar.gz
cd istio-1.4.7-asm.0
export PATH=$PWD/bin:$PATH

# Install ASM to cluster
echo "deploy istio manifests"
istioctl manifest apply --set profile=asm \
	  --set values.global.trustDomain=${WORKLOAD_POOL} \
	  --set values.global.sds.token.aud=${WORKLOAD_POOL} \
	  --set values.nodeagent.env.GKE_CLUSTER_URL=https://container.googleapis.com/v1/projects/${PROJECT_ID}/locations/${CLUSTER_LOCATION}/clusters/${CLUSTER_NAME} \
	  --set values.global.meshID=${MESH_ID} \
	  --set values.global.proxy.env.GCP_METADATA="${PROJECT_ID}|${PROJECT_NUMBER}|${CLUSTER_NAME}|${CLUSTER_LOCATION}" \
	  --set values.global.mtls.enabled=true

# Check it installation is proceeding
echo "Watching istio-system for 3mins"
wait 240
kubectl get deployment -n istio-system

