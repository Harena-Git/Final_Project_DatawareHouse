"""
DAG — Pipeline complet CapilHair + SalonKera + Météo

Graphe d'exécution :
  etl_capilhair ──┐
  etl_salonkera ──┼──► dbt_run ──► dbt_tests ──► monitoring ──► build_email ──► send_email
  etl_meteo     ──┘
"""

import os
import sys
import subprocess
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.email import EmailOperator
from airflow.utils.trigger_rule import TriggerRule

# ── Chemins ──────────────────────────────────────────────────
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ETL_DIR      = os.path.join(PROJECT_ROOT, "etl")
DBT_DIR      = os.path.join(PROJECT_ROOT, "dbt_project")

RAPPORT_EMAIL = os.getenv("RAPPORT_EMAIL", "nyvoaryraherimandimby@gmail.com")

default_args = {
    "owner": "salon_dw",
    "retries": 1,
    "retry_delay": timedelta(minutes=3),
    "email_on_failure": True,
    "email": [RAPPORT_EMAIL],
}

# ── Tâches ETL ───────────────────────────────────────────────

def _run_etl(module_name: str, key: str, **context):
    if ETL_DIR not in sys.path:
        sys.path.insert(0, ETL_DIR)
    import importlib
    mod = importlib.import_module(module_name)
    total = mod.run()
    context["ti"].xcom_push(key=key, value=total)


def etl_capilhair(**ctx):
    _run_etl("etl_capilhair", "lignes_capilhair", **ctx)

def etl_salonkera(**ctx):
    _run_etl("etl_salonkera", "lignes_salonkera", **ctx)

def etl_meteo(**ctx):
    _run_etl("etl_meteo", "lignes_meteo", **ctx)


# ── Tâches DBT ───────────────────────────────────────────────

def dbt_run(**context):
    result = subprocess.run(
        ["dbt", "run", "--profiles-dir", DBT_DIR, "--project-dir", DBT_DIR],
        capture_output=True, text=True,
    )
    print(result.stdout)
    if result.returncode != 0:
        raise RuntimeError(f"dbt run échoué :\n{result.stderr}")
    context["ti"].xcom_push(key="dbt_output", value=result.stdout[-3000:])


def dbt_tests(**context):
    result = subprocess.run(
        ["dbt", "test", "--profiles-dir", DBT_DIR, "--project-dir", DBT_DIR],
        capture_output=True, text=True,
    )
    print(result.stdout)
    if result.returncode != 0:
        raise RuntimeError(f"dbt test échoué :\n{result.stderr}")


# ── Monitoring ───────────────────────────────────────────────

def monitoring(**context):
    import time
    if ETL_DIR not in sys.path:
        sys.path.insert(0, ETL_DIR)
    from db_config import get_connection

    ti = context["ti"]
    cap   = ti.xcom_pull(key="lignes_capilhair", task_ids="etl_capilhair") or 0
    ker   = ti.xcom_pull(key="lignes_salonkera", task_ids="etl_salonkera") or 0
    met   = ti.xcom_pull(key="lignes_meteo",     task_ids="etl_meteo")     or 0
    total = cap + ker + met
    start = ti.xcom_pull(key="start_time", task_ids="etl_capilhair") or 0
    duree = round(time.time() - start, 2) if start else None

    rapport = (
        f"RAPPORT MONITORING — {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        f"{'─'*44}\n"
        f"  ETL CapilHair  : {cap:>6} lignes   [OK]\n"
        f"  ETL SalonKera  : {ker:>6} lignes   [OK]\n"
        f"  ETL Météo      : {met:>6} lignes   [OK]\n"
        f"  TOTAL          : {total:>6} lignes\n"
        f"{'─'*44}\n"
        f"  DBT run        :           [OK]\n"
        f"  DBT tests      :           [OK]\n"
        f"  Statut global  :        SUCCÈS\n"
    )
    print(rapport)
    ti.xcom_push(key="rapport", value=rapport)

    # Écriture dans dwh.pipeline_runs → visible dans Power BI
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO dwh.pipeline_runs
                    (dag_id, run_id, date_execution, statut,
                     lignes_capilhair, lignes_salonkera, lignes_meteo,
                     total_lignes, duree_secondes, dbt_statut, email_envoye, message)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                context["dag"].dag_id,
                context["run_id"],
                datetime.now(),
                "SUCCÈS",
                cap, ker, met, total,
                duree, "OK", False,
                rapport,
            ))
        conn.commit()
        conn.close()
        print("[OK] Run enregistré dans dwh.pipeline_runs")
    except Exception as e:
        print(f"[WARN] Impossible d'écrire dans pipeline_runs : {e}")

    if total == 0:
        raise ValueError("Aucune ligne chargée — vérifier les sources ETL.")


# ── Email ────────────────────────────────────────────────────

def build_email(**context):
    ti = context["ti"]
    rapport = ti.xcom_pull(key="rapport", task_ids="monitoring") or ""
    body = f"""
    <h2>Pipeline CapilHair / SalonKera — Rapport d'exécution</h2>
    <p><b>Date :</b> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    <pre style="background:#f4f4f4;padding:12px;border-radius:4px">{rapport}</pre>
    <p>Les données sont disponibles dans le Data Warehouse et prêtes pour Power BI.</p>
    """
    ti.xcom_push(key="email_body", value=body)


# ── DAG ──────────────────────────────────────────────────────

with DAG(
    dag_id="pipeline_salon_dw",
    description="ETL → DBT → Monitoring → Email — CapilHair + SalonKera",
    default_args=default_args,
    start_date=datetime(2024, 1, 1),
    schedule_interval="0 6 * * *",   # tous les jours à 6h
    catchup=False,
    tags=["capilhair", "salonkera", "etl", "dbt", "salon_dw"],
) as dag:

    t_cap = PythonOperator(task_id="etl_capilhair", python_callable=etl_capilhair)
    t_ker = PythonOperator(task_id="etl_salonkera", python_callable=etl_salonkera)
    t_met = PythonOperator(task_id="etl_meteo",     python_callable=etl_meteo)

    t_dbt_run   = PythonOperator(task_id="dbt_run",   python_callable=dbt_run)
    t_dbt_tests = PythonOperator(task_id="dbt_tests", python_callable=dbt_tests)

    t_monitoring = PythonOperator(
        task_id="monitoring",
        python_callable=monitoring,
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    t_build_email = PythonOperator(task_id="build_email", python_callable=build_email)

    t_send_email = EmailOperator(
        task_id="send_email",
        to=RAPPORT_EMAIL,
        subject="[salon_dw] Rapport pipeline — {{ ds }}",
        html_content="{{ ti.xcom_pull(key='email_body', task_ids='build_email') }}",
    )

    # Ordre d'exécution
    [t_cap, t_ker, t_met] >> t_dbt_run >> t_dbt_tests >> t_monitoring >> t_build_email >> t_send_email
