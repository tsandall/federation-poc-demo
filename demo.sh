#!/usr/bin/env bash

OPA=$(kubectl --context=federation-host get svc opa -o 'jsonpath={.status.loadBalancer.ingress[0].ip}')

curl --silent $OPA:8181/v1/policies/test -X PUT --data-binary @policy.rego >/dev/null

if [ $? -ne 0 ]; then
    echo "Error uploading initial policy to OPA."
    exit 1
fi

source ./util.sh

clear

run kubectl --context=federation-cluster get clusters

desc "Inspect example app"
run view ./nginx-eu.yaml

desc "Create/deploy example app"
run kubectl --context=federation-cluster create -f nginx-eu.yaml

desc "Observe annotations on example app"
run watch -n 1 kubectl --context=federation-cluster get rs nginx-eu -o yaml

desc "Observe deployment of example app"
run kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west1" get rs
run kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west2" get rs
run kubectl --context="gke_federation-poc_us-central1-b_gce-us-central1" get rs

desc "Let's look at how this actually works..."
desc "  * Developer submits ReplicaSet to federation-apiserver"
desc "  * Admission controller queries OPA"
desc "  * OPA evaluates policies to generate annotation value"
desc "  * OPA sends response to admission controller"
desc "  * Admission controller applies annotation to ReplicaSet"
desc "  * ReplicaSet is created and scheduled normally"
run open overview.svg
run vim policy.rego

run kubectl --context=federation-host get deployments
run kubectl --context=federation-host get svc opa

desc "Update policy directly in policy engine"
run curl $OPA:8181/v1/policies/test -X PUT --data-binary @policy.rego

desc "Update cluster to reflect PCI certification"
run kubectl --context=federation-cluster annotate clusters gce-europe-west1 pci-certified='true'

desc "Inspect example app w/ additional requirement"
run view ./nginx-eu-pci.yaml

desc "Create/deploy example app w/ additional requirement"
run kubectl --context=federation-cluster create -f nginx-eu-pci.yaml

desc "Observe annotations on example app w/ additional requirement"
run watch -n 1 kubectl --context=federation-cluster get rs nginx-eu-pci -o yaml

desc "Observe deployment of example app w/ additional requirement"
run kubectl --context="gke_federation-poc_europe-west1-b_gce-europe-west1" get rs

desc "Inspect example app w/ conflicting requirements"
run view nginx-error.yaml

desc "Inspect error/conflict handling"
run vim ./policy.rego

desc "Attempt to create/deploy example app w/ conflict"
run kubectl --context=federation-cluster create -f nginx-error.yaml

desc "Thanks for watching!"
run open links.svg
