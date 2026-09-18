import time
from elasticsearch import Elasticsearch
from prometheus_client import start_http_server, Gauge

# Authentification (sécurité activée en Phase 4 - voir Erreur 3 / secret elasticsearch-master-credentials)
ES_HOST = "https://elasticsearch-master.audit-elk.svc.cluster.local:9200"   # via kubectl port-forward
ES_USER = "elastic"
ES_PASSWORD = "21pCDzz6KKL8zWFo"     # à sécuriser plus tard (variable d'env, secret K8s)

es = Elasticsearch(
    ES_HOST,
    basic_auth=(ES_USER, ES_PASSWORD),
    verify_certs=False,   # certificat auto-signé (Erreur 11, Phase 4)
)

DENIED_COUNT = Gauge(
    "audit_access_denied_total_5min",
    "Nombre d'acces refuses sur les 5 dernieres minutes"
)

def poll():
    query = {
        "bool": {
            "must": [{"match": {"status": "denied"}}],
            "filter": [{"range": {"@timestamp": {"gte": "now-5m"}}}]
        }
    }
    try:
        result = es.count(index="audit-logs-5w", query=query)
        DENIED_COUNT.set(result["count"])
        print(f"[OK] Acces refuses (5 min) : {result['count']}")
    except Exception as e:
        print(f"[ERREUR] Impossible d'interroger Elasticsearch : {e}")

if __name__ == "__main__":
    start_http_server(8000)
    print("Exporter demarre sur le port 8000...")
    while True:
        poll()
        time.sleep(30)