terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.0"
    }
  }
}

provider "kubernetes" {
  # Use in-cluster config
  config_path = ""
}

provider "helm" {
  kubernetes {
    config_path = ""
  }
}

# Use the existing namespace provided by the cloud
locals {
  namespace = "jenkins-assignment"
}

resource "helm_release" "hextris" {
  name       = "hextris"
  chart      = "${path.module}/../helm-chart"  # path to your chart
  namespace  = local.namespace
  values = [
    yamlencode({
      replicaCount = 2
      image = {
        repository = "docker.io/israa2000/hextris"
        tag        = "latest"
      }
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "256Mi" }
      }
    })
  ]
  wait = true
}
