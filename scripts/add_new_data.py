"""
Ajoute un nouveau lot de données et met à jour la base en local.

1. Choisit la date du lot : celle de --date, sinon aujourd'hui,
   sinon le jour qui suit le dernier lot de storage/raw/batches/.
2. Génère le lot avec scripts/generate_daily_batch.py.
3. Lance dbt build (modèles + tests) pour mettre à jour staging, marts et warehouse.duckdb.
4. Affiche le nombre de lignes dans le staging.

Usage, depuis rebtel_local/ :
  python scripts/add_new_data.py                 # un lot
  python scripts/add_new_data.py --days 3        # trois lots, sur trois jours qui se suivent
  python scripts/add_new_data.py --date 2026-10-25

Ensuite, pour l'envoyer sur GitHub :
  git add storage/raw/batches
  git commit -m "Nouveaux lots"
  git push
"""
import argparse
import datetime
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BATCHES = ROOT / "storage" / "raw" / "batches"
DBT_DIR = ROOT / "rebtel_dbt"
GENERATOR = ROOT / "scripts" / "generate_daily_batch.py"


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--date", help="Date du premier lot, format AAAA-MM-JJ")
    parser.add_argument("--days", type=int, default=1, help="Nombre de lots à ajouter (un par jour)")
    parser.add_argument("--skip-dbt", action="store_true", help="Génère les lots sans lancer dbt build")
    return parser.parse_args()


def existing_dates():
    if not BATCHES.exists():
        return set()
    return {datetime.date.fromisoformat(p.name) for p in BATCHES.iterdir() if p.is_dir()}


def first_free_date(requested):
    taken = existing_dates()
    if requested:
        day = datetime.date.fromisoformat(requested)
    else:
        day = datetime.date.today()
        if day in taken:
            day = max(taken) + datetime.timedelta(days=1)
    while day in taken:
        day += datetime.timedelta(days=1)
    return day


def generate(day):
    subprocess.run([sys.executable, str(GENERATOR), "--date", day.isoformat()], check=True)


def run_dbt_build():
    from dbt.cli.main import dbtRunner

    print("\n[INFO] dbt build (13 modèles + 38 tests)...")
    # Les chemins de profiles.yml et sources.yml sont relatifs à rebtel_dbt/
    os.chdir(DBT_DIR)
    result = dbtRunner().invoke(["build", "--profiles-dir", "."])
    os.chdir(ROOT)
    if not result.success:
        sys.exit("[ERREUR] dbt build a échoué. Regarde les messages au-dessus.")


def print_counts():
    import duckdb

    staging = ROOT / "storage" / "staging"
    print("\n[INFO] Lignes dans le staging :")
    for name in ["stg_stream_cdrs", "stg_stream_transfers", "stg_batch_payments"]:
        path = (staging / f"{name}.parquet").as_posix()
        count = duckdb.sql(f"select count(*) from read_parquet('{path}')").fetchone()[0]
        print(f"  {name:<22} {count:>6}")


def main():
    args = parse_args()
    day = first_free_date(args.date)
    for _ in range(args.days):
        generate(day)
        day = first_free_date((day + datetime.timedelta(days=1)).isoformat())

    if args.skip_dbt:
        print("\n[INFO] dbt build ignoré (--skip-dbt).")
        return
    run_dbt_build()
    print_counts()
    print("\n[OK] Base à jour. Pour l'envoyer sur GitHub : git add storage/raw/batches, git commit, git push.")


if __name__ == "__main__":
    main()
