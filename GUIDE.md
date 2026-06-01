# Guide complet — Projet Data Warehouse Salon Capillaire

> Ce guide explique **tout le projet de A à Z** : ce que chaque outil fait, pourquoi,
> et comment faire tourner le pipeline sur une nouvelle machine.

---

## Résumé du projet en une phrase

On collecte des données de **deux salons capillaires** (CapilHair à Antananarivo,
SalonKera à Toamasina) et d'une **API météo**, on les nettoie, on les organise dans
une base de données, et on visualise les résultats dans **Power BI** pour analyser
le comportement des clients.

---

## Vue d'ensemble du pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  SOURCES                                                        │
│  data/capilhair/*.csv (12 fichiers)                             │
│  data/salonkera/*.csv (12 fichiers)                             │
│  API OpenWeatherMap (ou data/meteo/*.csv si pas de clé)         │
└──────────────────────┬──────────────────────────────────────────┘
                       │ ETL Python (etl/run_etl.py)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  STAGING (PostgreSQL — schéma "staging")                        │
│  Tables brutes : raw_capilhair_*, raw_salonkera_*, raw_meteo    │
│  Tout est en TEXT — pas encore nettoyé                          │
└──────────────────────┬──────────────────────────────────────────┘
                       │ DBT (dbt_project/)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  DATA WAREHOUSE (PostgreSQL — schéma "dwh")                     │
│  Dimensions : dim_clients, dim_produits, dim_employes,          │
│               dim_boutiques, dim_date, dim_meteo                │
│  Faits      : fact_ventes, fact_rendez_vous, fact_actions_crm   │
└──────────────────────┬──────────────────────────────────────────┘
                       │ Airflow (airflow/dag_pipeline.py)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  AUTOMATISATION — le tout tourne seul chaque jour à 6h          │
│  + monitoring des nœuds + rapport envoyé par email              │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  POWER BI — dashboard interactif connecté aux tables dwh.*      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prérequis à installer sur ta machine

| Outil | Pourquoi | Lien |
|-------|----------|------|
| **Python 3.10+** | ETL + DBT | python.org |
| **PostgreSQL 15** | Base de données | postgresql.org |
| **Docker Desktop** | Faire tourner Airflow | docker.com |
| **Git** | Cloner le projet | git-scm.com |
| **Power BI Desktop** | Visualisation (Windows uniquement) | microsoft.com |

---

## Mise en place sur une nouvelle machine

### 1 — Cloner le projet

```bash
git clone https://github.com/<votre-repo>/Final_Project_DatawareHouse.git
cd Final_Project_DatawareHouse
```

### 2 — Créer le fichier .env

Copier le fichier exemple et remplir les valeurs :

```bash
cp .env.example .env
```

Ouvrir `.env` et remplir :

```env
# PostgreSQL local
DB_HOST=localhost
DB_PORT=5432
DB_NAME=datawarehouse
DB_USER=postgres
DB_PASSWORD=ton_mot_de_passe_postgres

# API Météo (optionnel — laisser vide pour utiliser les CSV de secours)
OPENWEATHER_API_KEY=

# Gmail — pour recevoir le rapport Airflow
GMAIL_USER=ton.email@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
RAPPORT_EMAIL=ton.email@gmail.com
```

> **Comment obtenir GMAIL_APP_PASSWORD :**
> 1. Va sur myaccount.google.com → Sécurité → Validation en 2 étapes (activer)
> 2. Cherche "Mots de passe des applications" → créer → copier les 16 caractères

### 3 — Installer les dépendances Python

```bash
pip install -r requirements.txt
pip install "dbt-core==1.8.7" "dbt-postgres==1.8.2"
```

### 4 — Créer la base PostgreSQL

```bash
psql -U postgres -c "CREATE DATABASE datawarehouse;"
psql -U postgres -d datawarehouse -f warehouse/schema.sql
```

Vérification :
```bash
psql -U postgres -d datawarehouse -c "\dn"
# Doit afficher : staging, dwh
```

---

## Lancer le pipeline manuellement (sans Airflow)

Utile pour tester chaque étape séparément.

### Étape 1 — ETL : charger les données brutes

```bash
cd etl
python run_etl.py
```

Ce que ça fait :
- Lit les 12 CSV de `data/capilhair/`
- Lit les 12 CSV de `data/salonkera/`
- Appelle l'API météo (ou lit `data/meteo/*.csv` si pas de clé API)
- Charge tout dans `staging.raw_*` dans PostgreSQL

Résultat attendu :
```
[OK] staging.raw_capilhair_clients — 18 lignes chargées
[OK] staging.raw_salonkera_clients — 17 lignes chargées
...
Pipeline ETL terminé avec succès.
```

### Étape 2 — DBT : transformer les données

```bash
cd dbt_project
dbt run
dbt test
```

Ce que ça fait :
- `dbt run` : lit les tables `staging.raw_*` et crée les tables propres dans `dwh.*`
- `dbt test` : vérifie qu'il n'y a pas de doublons, de valeurs nulles interdites, etc.

Résultat attendu :
```
OK created view  staging.stg_capilhair_clients
OK created view  staging.stg_salonkera_ventes
...
OK created table dwh.dim_clients
OK created table dwh.fact_ventes
...
Completed successfully
```

---

## Lancer le pipeline automatiquement avec Airflow (Docker)

C'est la méthode principale du projet. Airflow lance tout dans le bon ordre
automatiquement chaque jour à 6h du matin.

### Ce qu'est Airflow

Airflow est un **chef d'orchestre**. Tu lui donnes une recette (appelée DAG)
et il s'assure que chaque étape s'exécute dans le bon ordre, au bon moment.

Notre DAG `pipeline_salon_dw` ressemble à ça :

```
etl_capilhair ──┐
etl_salonkera ──┼──► dbt_run ──► dbt_tests ──► monitoring ──► build_email ──► send_email
etl_meteo     ──┘
```

- Les 3 ETL tournent **en parallèle** (plus rapide)
- DBT attend que les 3 ETL soient finis
- Le monitoring vérifie que tout s'est bien passé
- Un email de rapport est envoyé automatiquement à la fin

### Démarrer Airflow

```bash
cd airflow
docker compose --env-file ../.env up
```

La première fois, ça prend ~3 minutes (téléchargement des images Docker).

Ouvrir l'interface : **http://localhost:8080**
Login : `admin` / Password : `admin`

### Lancer le pipeline depuis l'interface

1. Sur la page **DAGs**, trouver `pipeline_salon_dw`
2. Activer le DAG avec le **toggle** à gauche (il est gris = pausé par défaut)
3. Cliquer sur **▶** pour lancer un run manuel
4. Cliquer sur le nom du DAG → onglet **Graph** pour voir les nœuds en temps réel

### Lire la vue Graph (nœuds)

Chaque carré = une étape du pipeline. La couleur indique le statut :

| Couleur | Signification |
|---------|---------------|
| Vert | Succès ✅ |
| Rouge | Échec ❌ |
| Jaune | En cours / En attente de retry |
| Gris clair | En attente que l'étape précédente finisse |

### Voir les logs d'une étape

1. Cliquer sur un nœud dans la vue Graph
2. Cliquer sur **Logs**
3. Les logs montrent exactement ce qui s'est passé (lignes chargées, erreurs DBT, etc.)

### Arrêter Airflow

```bash
docker compose down
```

Pour tout réinitialiser (recrée les containers et la base Airflow) :
```bash
docker compose down -v
```

---

## Structure du projet

```
Final_Project_DatawareHouse/
│
├── data/
│   ├── capilhair/        # 12 fichiers CSV — boutique Antananarivo
│   ├── salonkera/        # 12 fichiers CSV — boutique Toamasina
│   └── meteo/            # CSV de secours météo
│
├── etl/
│   ├── db_config.py      # Connexion PostgreSQL (lit le .env)
│   ├── etl_capilhair.py  # ETL boutique 1
│   ├── etl_salonkera.py  # ETL boutique 2
│   ├── etl_meteo.py      # ETL météo (API + fallback CSV)
│   └── run_etl.py        # Lance les 3 ETL + affiche le rapport
│
├── warehouse/
│   └── schema.sql        # Crée les schémas staging et dwh dans PostgreSQL
│
├── dbt_project/
│   ├── dbt_project.yml   # Configuration DBT (nom du projet : salon_dw)
│   ├── profiles.yml      # Connexion PostgreSQL pour DBT
│   └── models/
│       ├── staging/      # Vues de nettoyage (stg_capilhair_*, stg_salonkera_*, stg_meteo)
│       └── marts/        # Tables finales (dim_clients, fact_ventes, etc.)
│
├── airflow/
│   ├── docker-compose.yml  # Lance Airflow avec Docker
│   ├── dag_pipeline.py     # DAG copié ici (hors du dossier dags/)
│   └── dags/
│       └── dag_pipeline.py # DAG lu par Airflow
│
├── .env                  # Secrets locaux (jamais commité sur Git)
├── .env.example          # Modèle du .env (sans les vraies valeurs)
├── .gitignore            # Ignore .env, __pycache__, etc.
├── requirements.txt      # Dépendances Python
├── README.md             # Description du projet
└── GUIDE.md              # Ce fichier
```

---

## Ce que fait chaque outil — résumé simple

### ETL (Python)
"Extract Transform Load" — il **extrait** les données des CSV et de l'API,
fait un minimum de nettoyage (ajouter la colonne `source_boutique`, la date de chargement),
et les **charge** dans PostgreSQL dans le schéma `staging`.
Les données sont stockées brutes en TEXT — c'est le rôle de DBT de les nettoyer vraiment.

### DBT (Data Build Tool)
DBT prend les données brutes du `staging` et crée des tables propres et typées dans `dwh`.
Il fait aussi les jointures (ex : lier une vente à son client et à son produit).
DBT écrit des fichiers SQL (dans `models/`) — pas de Python.
Il peut aussi tester la qualité des données automatiquement (`dbt test`).

### Airflow
Airflow est un planificateur de tâches avec une interface web.
Il lit notre fichier `dag_pipeline.py` qui décrit l'ordre des étapes.
Il lance ETL → DBT → monitoring → email chaque jour à 6h automatiquement.
Si une étape échoue, il envoie une alerte par email et réessaie automatiquement.

### Power BI
Power BI se connecte directement aux tables `dwh.*` dans PostgreSQL
et crée des graphiques interactifs. C'est la partie faite par l'autre duo.

---

## Dépannage

### "could not connect to server" dans l'ETL
→ PostgreSQL n'est pas démarré. Ouvrir pgAdmin ou lancer `pg_ctl start`.

### "dbt-core 2.0.0-alpha" — adapter not supported
→ Mauvaise version de dbt installée. Forcer : `pip install "dbt-core==1.8.7" "dbt-postgres==1.8.2"`

### Login Airflow invalide
→ Le container `airflow-init` n'a pas fini de créer le compte.
Attendre 2 minutes et réessayer. Si toujours invalide :
```bash
docker compose down -v
docker compose --env-file ../.env up
```

### Variables GMAIL_USER / DB_PASSWORD non trouvées dans Docker
→ Toujours lancer avec `--env-file ../.env` depuis le dossier `airflow/` :
```bash
docker compose --env-file ../.env up
```

### dbt_run échoue dans Airflow avec "localhost refused"
→ Le `profiles.yml` utilisait `localhost` à la place de `host.docker.internal`.
La version corrigée utilise `env_var('DB_HOST')` — vérifier que le `.env` est bien lu.

---

## Équipe

| Nom | Rôle |
|-----|------|
| **Ny Voary** | ETL + PostgreSQL (schema.sql) |
| **Misafidy** | DBT + Airflow |
| **Duo Power BI** | Dashboard final |
