package io.k8s.admission

import data.io.k8s.federation.clusters
import data.io.k8s.federation.replicasets
import input.resource.metadata.annotations as raw_input_annotations

################################################################
#
# replica-set-preferences
#
################################################################

replica_set_preferences_key = "federation.kubernetes.io/replica-set-preferences"

annotations[replica_set_preferences_key] = {
    "clusters": replica_set_clusters,
    "rebalance": true,
} {
    is_replica_set
}

replica_set_clusters[cluster_name] = {"weight": 1} {
    clusters[cluster_name]
    not excluded_by_input[cluster_name]
    not invalid_jurisdiction[cluster_name]
}

invalid_jurisdiction[cluster_name] {
    clusters[cluster_name] = cluster
    raw_input_annotations["requires-eu-jurisdiction"] = "true"
    not re_match("^europe-", cluster.status.region)
}

excluded_by_input[cluster_name] {
    clusters[cluster_name]
    preferences = input_annotations[replica_set_preferences_key]
    not preferences.clusters[cluster_name]
}

input_replica_set_cluster_names[cluster_name] {
    value = input_annotations[replica_set_preferences_key]
    value.clusters[cluster_name]
}

replica_set_cluster_names[cluster_name] {
    replica_set_clusters[cluster_name]
}

################################################################
#
# errors/conflicts
#
################################################################

errors["one or more requested clusters are not allowed"] {
    is_replica_set
    not_allowed = input_replica_set_cluster_names - replica_set_cluster_names
    not_allowed != set()
}

################################################################
#
# helpers
#
################################################################

annotations_marshalled[key] = value {
    json_marshal(annotations[key], value)
}

input_annotations[key] = value {
    json_unmarshal(raw_input_annotations[key], value)
}

is_replica_set {
    input.resource.kind = "ReplicaSet"
}

resource = {
    "metadata": {
        "annotations": annotations_marshalled,
    }
}
