terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/audit-vm-config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/audit-vm-config"
}

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "audit-kafka"
  }
}

resource "helm_release" "kafka" {
  name       = "audit-kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  namespace  = kubernetes_namespace.kafka.metadata[0].name
  version    = "29.3.5"

  values = [
    file("${path.module}/values-kafka.yaml")
  ]

  timeout = 1800
  wait    = true
}