import json
import random
import time
from datetime import datetime, timezone
from kafka import KafkaProducer
from faker import Faker

fake = Faker()

# Adapter selon l'exposition Kafka depuis l'hote (port-forward ou NodePort)
KAFKA_BOOTSTRAP_SERVERS = ["localhost:9094"]
TOPIC = "audit-logs-5w"

USERS = ["admin_prestataire", "support_n1", "support_n2", "dba_prestataire", "ops_lead"]
ACTIONS = [
    "consultation_dossier_adherent",
    "export_donnees_personnelles",
    "modification_droits_acces",
    "connexion_ssh_serveur",
    "consultation_logs_systeme",
    "modification_configuration_reseau",
    "acces_base_donnees_production",
]
RESOURCES = ["srv-app-01", "srv-db-01", "srv-app-02", "vpc-fede-prod", "bucket-s3-archives"]
REASONS = [
    "intervention_maintenance_planifiee",
    "ticket_support_incident",
    "audit_conformite_routine",
    "acces_urgence_incident_production",
    "non_documente",
]

def generate_log_entry(force_denied_ratio=0.3):
    action = random.choice(ACTIONS)
    reason = random.choice(REASONS)
    is_denied = reason == "non_documente" and random.random() < force_denied_ratio
    return {
        "who": random.choice(USERS),
        "what": action,
        "when": datetime.now(timezone.utc).isoformat(),
        "where": random.choice(RESOURCES),
        "why": reason,
        "status": "denied" if is_denied else "granted",
        "source_ip": fake.ipv4(),
        "@timestamp": datetime.now(timezone.utc).isoformat(),
    }

def main():
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    )

    print(f"Envoi de logs simules vers le topic '{TOPIC}'... (Ctrl+C pour arreter)")
    try:
        while True:
            entry = generate_log_entry()
            producer.send(TOPIC, value=entry)
            print(f"Envoye : {entry['who']} -> {entry['what']} ({entry['status']})")
            time.sleep(random.uniform(0.5, 2))
    except KeyboardInterrupt:
        print("\nArret du generateur.")
    finally:
        producer.flush()
        producer.close()

if __name__ == "__main__":
    main()
    