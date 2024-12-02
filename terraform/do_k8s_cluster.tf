data "digitalocean_kubernetes_versions" "prod" {
  version_prefix = "1.29."
}

resource "digitalocean_kubernetes_cluster" "forensics-lab" {
  name         = "forensics-cluster"
  region       = "fra1"
  auto_upgrade = true
  version      = data.digitalocean_kubernetes_versions.prod.latest_version

  maintenance_policy {
    start_time = "04:00"
    day        = "friday"
  }

  node_pool {
    name       = "autoscale-worker-pool"
    size       = "s-4vcpu-16gb-amd"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }
}