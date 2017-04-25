#!/usr/bin/env bash

set -x

OPA=$(kubectl --context=federation-host get svc opa -o 'jsonpath={.status.loadBalancer.ingress[0].ip}')

curl $OPA:8181/v1/policies/test -X PUT --data-binary @empty.rego

kubectl --context=federation-cluster delete -f nginx-eu.yaml

kubectl --context=federation-cluster delete rs nginx
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west1" delete rs nginx
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west2" delete rs nginx
kubectl --context="gke_federation-poc_us-central1-b_gce-us-central1" delete rs nginx

kubectl --context=federation-cluster delete rs nginx-eu
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west2" delete rs nginx-eu
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west1" delete rs nginx-eu
kubectl --context="gke_federation-poc_us-central1-b_gce-us-central1" delete rs nginx-eu

kubectl --context=federation-cluster delete rs nginx-eu-pci
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west2" delete rs nginx-eu-pci
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west1" delete rs nginx-eu-pci
kubectl --context="gke_federation-poc_us-central1-b_gce-us-central1" delete rs nginx-eu-pci

kubectl --context=federation-cluster delete rs nginx-error
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west2" delete rs nginx-error
kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west1" delete rs nginx-error
kubectl --context="gke_federation-poc_us-central1-b_gce-us-central1" delete rs nginx-error

kubectl --context=federation-cluster get clusters gce-europe-west1 -o json | jq -e '.metadata.annotations["pci-certified"]'

if [ $? -eq 0 ]; then
    kubectl --context=federation-cluster patch clusters gce-europe-west1 --type='json' --patch='[{"op": "remove", "path": "/metadata/annotations/pci-certified"}]'
fi
