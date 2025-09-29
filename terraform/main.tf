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
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "hextris" {
  metadata {
    name = "hextris"
  }
}

resource "helm_release" "hextris" {
  name       = "hextris"
  chart      = "${path.module}/../../chart/hextris"
  namespace  = kubernetes_namespace.hextris.metadata[0].name
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
}
