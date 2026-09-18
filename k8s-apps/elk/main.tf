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

resource "kubernetes_namespace" "elk" {
  metadata {
    name = "audit-elk"
  }
}

resource "helm_release" "elasticsearch" {
  name       = "audit-es"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  namespace  = kubernetes_namespace.elk.metadata[0].name
  version    = "8.5.1"

  values = [
    file("${path.module}/values-elasticsearch.yaml")
  ]

  timeout = 1200
}
resource "helm_release" "kibana" {
  name       = "audit-kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  namespace  = kubernetes_namespace.elk.metadata[0].name
  version    = "8.5.1"

  values = [
    file("${path.module}/values-kibana.yaml")
  ]

  timeout = 1200

  depends_on = [helm_release.elasticsearch]
}

