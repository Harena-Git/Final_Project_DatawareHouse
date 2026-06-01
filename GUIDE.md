# Guide du projet — Data Warehouse Salon Capillaire

## Le problème de départ

Vous avez des données dans des fichiers CSV (clients, ventes, produits...) de 2 boutiques.
Le but du projet c'est d'**analyser le comportement des clients** dans Power BI.
Mais Power BI ne peut pas lire directement des CSV dispersés — il faut tout organiser dans une base de données propre.

---

## La solution — un pipeline en 4 étapes

```
ETAPE 1        ETAPE 2         ETAPE 3        ETAPE 4
CSV files  →  PostgreSQL  →   PostgreSQL  →  Airflow
(données       (données         (données       (lance tout
 brutes)        brutes           propres        automatiquement)
                staging)         dwh)
                   ↑                ↑
                 ETL             DBT fait
                fait ça            ça
```

---

## ETAPE 1 — ETL

### Ce que c'est
ETL = Extract, Transform, Load.
Les 3 scripts Python lisent les CSV et les copient dans PostgreSQL.

### Fichiers concernés
- `etl/etl_capilhair.py` — charge les 12 CSV de CapilHair
- `etl/etl_salonkera.py` — charge les 12 CSV de SalonKera
- `etl/etl_meteo.py` — récupère la météo (API ou CSV de secours)
- `etl/run_etl.py` — lance les 3 scripts dans l'ordre

### Avant / Après
- **Avant :** données dans des fichiers CSV sur votre PC
- **Après :** données dans PostgreSQL dans le schéma `staging` — tables `raw_capilhair_clients`, `raw_salonkera_ventes`, etc.

### Commande
```bash
python etl/run_etl.py
```

### Statut
✅ Fait

---

## ETAPE 2 — Data Warehouse (schema.sql)

### Ce que c'est
Le fichier `warehouse/schema.sql` crée la **structure** de la base analytique — comme un plan d'architecte.
Il crée le modèle en étoile :

```
         dim_clients (qui a acheté ?)
               ↑
dim_date ← fact_ventes → dim_produits (quoi ?)
               ↓
         dim_boutiques (où ?)
```

### Fichiers concernés
- `warehouse/schema.sql` — crée les schémas `staging` et `dwh` avec toutes les tables

### Avant / Après
- **Avant :** base de données vide
- **Après :** structure en étoile créée — tables `dwh.dim_clients`, `dwh.fact_ventes`, etc. (vides, DBT les remplira)

### Commande
```bash
psql -U postgres -d datawarehouse -f warehouse/schema.sql
```

### Statut
✅ Fait

---

## ETAPE 3 — DBT

### Ce que c'est
DBT lit les tables brutes du `staging` et les transforme en tables propres dans `dwh`.

```
staging.raw_capilhair_clients  ──┐
                                  ├──► dwh.dim_clients (propre, typé, unifié)
staging.raw_salonkera_clients  ──┘

staging.raw_capilhair_ventes   ──┐
                                  ├──► dwh.fact_ventes (avec jointures vers dim_*)
staging.raw_salonkera_ventes   ──┘
```

### Fichiers concernés
- `dbt_project/dbt_project.yml` — configuration principale
- `dbt_project/profiles.yml` — connexion PostgreSQL
- `dbt_project/models/staging/` — 13 fichiers SQL de nettoyage
- `dbt_project/models/marts/` — 6 fichiers SQL (dim_* et fact_*)
- `dbt_project/models/staging/schema.yml` — tests staging
- `dbt_project/models/marts/schema.yml` — tests marts

### Ce que DBT fait concrètement
| Commande | Ce que ça fait |
|----------|---------------|
| `dbt run` | Crée les tables `dwh.*` dans PostgreSQL |
| `dbt test` | Vérifie pas de doublons, pas de valeurs nulles, clés FK valides |
| `dbt docs generate` | Génère la documentation HTML |

### Avant / Après
- **Avant :** `dwh.dim_clients` est vide
- **Après :** `dwh.dim_clients` contient tous les clients des 2 boutiques réunis et nettoyés

### Commandes
```bash
cd dbt_project
dbt run
dbt test
```

### Vérification dans PostgreSQL
```sql
SELECT COUNT(*) FROM dwh.dim_clients;
SELECT COUNT(*) FROM dwh.fact_ventes;
SELECT COUNT(*) FROM dwh.fact_rendez_vous;
```

### Statut
⏳ En cours de test

---

## ETAPE 4 — Airflow

### Ce que c'est
Airflow est un **chef d'orchestre**.
Sans Airflow, vous devez lancer manuellement ETL puis DBT à chaque fois.
Avec Airflow, vous définissez un DAG (= une recette) qui s'exécute automatiquement.

### Ce que le DAG fait
```
Tous les lundis à 8h :
  1. Lance l'ETL (capilhair + salonkera + meteo)
  2. Quand c'est fini → lance DBT run
  3. Quand c'est fini → lance DBT test
  4. Quand tout est OK → pipeline terminé
```

### Fichiers concernés
- `airflow/dag_pipeline.py` — le DAG Airflow (à créer)

### Commandes (après installation)
```bash
airflow db init
airflow webserver --port 8080
airflow scheduler
```

### Statut
❌ À faire

---

## Résumé de l'avancement

| Etape | Ce que ça fait | Statut |
|-------|---------------|--------|
| ETL Python | Charge les CSV dans PostgreSQL staging | ✅ Fait |
| Schema SQL | Crée la structure dwh en étoile | ✅ Fait |
| DBT | Transforme staging → dwh | ⏳ En test |
| Airflow | Automatise tout le pipeline | ❌ À faire |
| Power BI | Dashboard sur les tables dwh.* | ❌ Après DBT validé |

---

## Ordre des commandes pour tout lancer

```bash
# 1. Créer la base
psql -U postgres -c "CREATE DATABASE datawarehouse;"
psql -U postgres -d datawarehouse -f warehouse/schema.sql

# 2. Lancer l'ETL
python etl/run_etl.py

# 3. Lancer DBT
cd dbt_project
dbt run
dbt test

# 4. Vérifier
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM dwh.dim_clients;"
```
