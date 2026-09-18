terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/audit-vm-config"
}

resource "kubernetes_namespace" "connect" {
  metadata {
    name = "audit-connect"
  }
}

resource "kubernetes_deployment" "kafka_connect" {
  metadata {
    name      = "kafka-connect"
    namespace = kubernetes_namespace.connect.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "kafka-connect" }
    }

    template {
      metadata {
        labels = { app = "kafka-connect" }
      }

      spec {
        container {
          name    = "kafka-connect"
          image = "confluentinc/cp-kafka-connect:7.9.0"
          command = ["sh", "-c", "confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:latest && /etc/confluent/docker/run"]

          port {
            container_port = 8083
          }

          env {
            name  = "CONNECT_BOOTSTRAP_SERVERS"
            value = "audit-kafka-controller-0.audit-kafka-controller-headless.audit-kafka.svc.cluster.local:9092"
          }
          env {
            name  = "CONNECT_GROUP_ID"
            value = "audit-connect-cluster"
          }
          env {
            name  = "CONNECT_CONFIG_STORAGE_TOPIC"
            value = "connect-configs"
          }
          env {
            name  = "CONNECT_OFFSET_STORAGE_TOPIC"
            value = "connect-offsets"
          }
          env {
            name  = "CONNECT_STATUS_STORAGE_TOPIC"
            value = "connect-status"
          }
          env {
            name  = "CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR"
            value = "1"
          }
          env {
            name  = "CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR"
            value = "1"
          }
          env {
            name  = "CONNECT_STATUS_STORAGE_REPLICATION_FACTOR"
            value = "1"
          }
          env {
            name  = "CONNECT_KEY_CONVERTER"
            value = "org.apache.kafka.connect.json.JsonConverter"
          }
          env {
            name  = "CONNECT_VALUE_CONVERTER"
            value = "org.apache.kafka.connect.json.JsonConverter"
          }
          env {
            name  = "CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE"
            value = "false"
          }
          env {
            name  = "CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE"
            value = "false"
          }
          env {
            name  = "CONNECT_REST_ADVERTISED_HOST_NAME"
            value = "kafka-connect"
          }
          env {
            name  = "CONNECT_PLUGIN_PATH"
            value = "/usr/share/confluent-hub-components,/usr/share/java/kafka"
          }

          resources {
            requests = { cpu = "300m", memory = "768Mi" }
            limits   = { cpu = "800m", memory = "1Gi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kafka_connect" {
  metadata {
    name      = "kafka-connect"
    namespace = kubernetes_namespace.connect.metadata[0].name
  }
  spec {
    selector = { app = "kafka-connect" }
    port {
      port        = 8083
      target_port = 8083
    }
    type = "NodePort"
  }
}