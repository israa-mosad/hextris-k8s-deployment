terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    helm = { // Add Helm provider to manage the deployment
      source  = "hashicorp/helm"
      version = "2.12.1"
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

// Deploy the application using the Helm provider, managing its configuration
resource "helm_release" "hextris_app" {
  name       = "hextris"
  // Point to the local Helm chart directory
  chart      = "../helm-chart" 
  namespace  = kubernetes_namespace.hextris.metadata[0].name
  
  // Override the image details with variables passed from Jenkins
  set {
    name  = "image.repository"
    value = var.docker_image_repo
  }
  set {
    name  = "image.tag"
    value = var.docker_image_tag
  }
 
}
