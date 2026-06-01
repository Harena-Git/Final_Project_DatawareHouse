"""
Point d'entrée principal de l'ETL.
Lance les trois sources dans l'ordre : CapilHair → SalonKera → Météo
Peut être appelé directement ou depuis le DAG Airflow.
"""

import sys
import time
from datetime import datetime

import etl_capilhair
import etl_salonkera
import etl_meteo


def run_all():
    start = datetime.now()
    results = {}
    errors = {}

    steps = [
        ("CapilHair",  etl_capilhair.run),
        ("SalonKera",  etl_salonkera.run),
        ("Météo",      etl_meteo.run),
    ]

    print("=" * 60)
    print(f"  PIPELINE ETL — Démarrage : {start.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    for name, fn in steps:
        t0 = time.time()
        try:
            count = fn()
            results[name] = {"lignes": count, "duree_s": round(time.time() - t0, 2), "statut": "OK"}
        except Exception as e:
            errors[name] = str(e)
            results[name] = {"lignes": 0, "duree_s": round(time.time() - t0, 2), "statut": "ERREUR"}
            print(f"[ERREUR] {name} : {e}")

    duree_totale = round((datetime.now() - start).total_seconds(), 2)

    print()
    print("=" * 60)
    print("  RAPPORT D'EXÉCUTION ETL")
    print("=" * 60)
    print(f"  {'Source':<15} {'Statut':<10} {'Lignes':>8}   {'Durée':>8}")
    print(f"  {'-'*15} {'-'*10} {'-'*8}   {'-'*8}")
    for name, r in results.items():
        print(f"  {name:<15} {r['statut']:<10} {r['lignes']:>8}   {r['duree_s']:>7}s")
    print(f"  {'TOTAL':<15} {'':10} {sum(r['lignes'] for r in results.values()):>8}   {duree_totale:>7}s")
    print("=" * 60)

    if errors:
        print(f"\n  {len(errors)} erreur(s) détectée(s) :")
        for name, msg in errors.items():
            print(f"  - {name} : {msg}")
        sys.exit(1)

    print(f"\n  Pipeline ETL terminé avec succès.\n")
    return results


if __name__ == "__main__":
    run_all()
