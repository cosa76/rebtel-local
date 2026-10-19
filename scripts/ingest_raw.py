"""
Ingestion locale (remplace GCS + Pub/Sub + Airbyte + chargement BigQuery).
Copie les fichiers sources de telecom-project-main/data vers storage/raw/.
"""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / "telecom-project-main" / "data"
RAW = ROOT / "storage" / "raw"

FILES = {
    "stream/call_data_records.json": "call_data_records.json",
    "stream/money_transfers.json": "money_transfers.json",
    "saas/zendesk_tickets.json": "zendesk_tickets.json",
    "batch/financial_payments.csv": "financial_payments.csv",
}

RAW.mkdir(parents=True, exist_ok=True)
for src, dst in FILES.items():
    shutil.copy2(SOURCE / src, RAW / dst)
    print(f"[OK] {src} -> storage/raw/{dst}")
