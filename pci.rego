package io.k8s.admission

import data.io.k8s.federation.clusters
import input.resource.metadata.annotations as input_annotations

insufficient_pci[cluster_name] {
    clusters[cluster_name] = cluster
    input_annotations["requires-pci-compliance"] = "true"
    not cluster.metadata.annotations["pci-certified"]
}
