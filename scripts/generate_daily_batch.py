"""
Génère un lot de nouvelles données synthétiques pour une journée.
Reprend les règles de telecom-project-main/src/data_generator.py, à plus petite échelle.

Le lot est écrit dans storage/raw/batches/<date>/ :
  - call_data_records.json
  - money_transfers.json
  - financial_payments.csv

Les user_id viennent de storage/raw/zendesk_tickets.json, comme dans l'original.
Les identifiants contiennent la date (ex. CALL-20261019-00001), donc ils restent uniques d'un lot à l'autre.
La graine aléatoire dépend de la date : relancer pour la même date donne le même lot.

Usage :
  python scripts/generate_daily_batch.py                  # lot du jour
  python scripts/generate_daily_batch.py --date 2026-10-18
"""
import argparse
import csv
import datetime
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "storage" / "raw"

COUNTRIES = ["SE", "US", "UK", "DE", "NG", "IN", "PK", "PH", "TR", "MX", "BR", "ZA"]
PLANS = ["basic", "standard", "premium", "family"]
PLAN_PRICES = {"basic": 4.99, "standard": 9.99, "premium": 19.99, "family": 29.99}
PAY_STATUS = ["success", "failed", "pending", "refunded"]


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--date", default=datetime.date.today().isoformat(), help="Date du lot, format AAAA-MM-JJ")
    parser.add_argument("--calls", type=int, default=100, help="Nombre d'appels")
    parser.add_argument("--transfers", type=int, default=60, help="Nombre de transferts")
    parser.add_argument("--payments", type=int, default=60, help="Nombre de paiements")
    return parser.parse_args()


def load_user_ids():
    tickets = json.loads((RAW / "zendesk_tickets.json").read_text(encoding="utf-8"))
    user_ids = sorted({t["user_id"] for t in tickets})
    if not user_ids:
        raise ValueError("Aucun user_id dans storage/raw/zendesk_tickets.json")
    return user_ids


def main():
    args = parse_args()
    day = datetime.date.fromisoformat(args.date)
    tag = day.strftime("%Y%m%d")
    out_dir = RAW / "batches" / day.isoformat()

    if out_dir.exists():
        print(f"[SKIP] Le lot {day} existe déjà : {out_dir.relative_to(ROOT)}")
        return

    rng = random.Random(tag)
    user_ids = load_user_ids()
    start = datetime.datetime.combine(day, datetime.time())

    def random_ts():
        return (start + datetime.timedelta(seconds=rng.randint(0, 86399))).strftime("%Y-%m-%dT%H:%M:%SZ")

    cdrs = []
    for i in range(args.calls):
        success = rng.random() > 0.25
        cdrs.append({
            "call_id": f"CALL-{tag}-{i + 1:05d}",
            "user_id": rng.choice(user_ids),
            "duration_seconds": rng.randint(10, 3600) if success else rng.randint(0, 30),
            "connection_success": success,
            "call_quality_score": round(rng.uniform(1.0, 5.0), 2) if success else round(rng.uniform(0.5, 2.0), 2),
            "delivery_rate_percent": round(rng.uniform(70.0, 99.9), 2) if success else round(rng.uniform(0.0, 50.0), 2),
            "timestamp": random_ts(),
        })

    transfers = []
    for i in range(args.transfers):
        is_fraud = rng.random() < 0.08
        sender = rng.choice(COUNTRIES)
        receiver = rng.choice([c for c in COUNTRIES if c != sender])
        transfers.append({
            "transfer_id": f"TRF-{tag}-{i + 1:05d}",
            "user_id": rng.choice(user_ids),
            "sender_country": sender,
            "receiver_country": receiver,
            "transfer_amount_usd": round(rng.uniform(800.0, 2000.0), 2) if is_fraud else round(rng.uniform(5.0, 2000.0), 2),
            "is_fraud_flag": is_fraud,
        })

    payments = []
    for i in range(args.payments):
        plan = rng.choice(PLANS)
        payments.append({
            "transaction_id": f"TXN-{tag}-{i + 1:05d}",
            "user_id": rng.choice(user_ids),
            "subscription_plan": plan,
            "payment_amount": round(PLAN_PRICES[plan] + rng.uniform(-0.5, 0.5), 2),
            "payment_status": rng.choice(PAY_STATUS),
        })

    out_dir.mkdir(parents=True)
    (out_dir / "call_data_records.json").write_text(json.dumps(cdrs, indent=2), encoding="utf-8")
    (out_dir / "money_transfers.json").write_text(json.dumps(transfers, indent=2), encoding="utf-8")
    with open(out_dir / "financial_payments.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(payments[0].keys()))
        writer.writeheader()
        writer.writerows(payments)

    print(f"[OK] Lot {day} : {len(cdrs)} appels, {len(transfers)} transferts, {len(payments)} paiements")
    print(f"     -> {out_dir.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
