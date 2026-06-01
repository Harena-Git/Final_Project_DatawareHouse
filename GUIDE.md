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

## ETAPE 1 — Installer les dépendances

### Ce que c'est
Installer tous les outils Python nécessaires pour faire tourner le projet.

### Commandes
```bash
pip install -r requirements.txt
pip install dbt-core==1.8.7 dbt-postgres==1.8.2
```

### Vérification
```bash
dbt --version
```
Doit afficher `dbt-core: 1.8.7`

### Statut
✅ Fait

---

## ETAPE 2 — Créer la base PostgreSQL

### Ce que c'est
Créer la base de données centrale où tout va transiter — données brutes, transformations DBT, tables finales pour Power BI.

### Commande
```bash
psql -U postgres -c "CREATE DATABASE datawarehouse;"
```

### Vérification
```bash
psql -U postgres -c "\l"
```
Doit afficher `datawarehouse` dans la liste.

### Statut
✅ Fait

---

## ETAPE 3 — Créer les schémas et tables (schema.sql)

### Ce que c'est
Le fichier `warehouse/schema.sql` crée la **structure** de la base analytique.
Il crée le modèle en étoile :

```
         dim_clients (qui a acheté ?)
               ↑
dim_date ← fact_ventes → dim_produits (quoi ?)
               ↓
         dim_boutiques (où ?)
```

Les tables sont créées **vides** — c'est DBT qui les remplira.

### Commande
```bash
psql -U postgres -d datawarehouse -f warehouse/schema.sql
```

### Vérification
```bash
# Vérifier les schémas créés
psql -U postgres -d datawarehouse -c "\dn"
```
Doit afficher :
```
staging
dwh
```

```bash
# Vérifier les tables dwh créées (vides pour l'instant)
psql -U postgres -d datawarehouse -c "\dt dwh.*"
```
Doit afficher :
```
dwh.dim_boutiques
dwh.dim_clients
dwh.dim_date
dwh.dim_employes
dwh.dim_meteo
dwh.dim_produits
dwh.fact_actions_crm
dwh.fact_rendez_vous
dwh.fact_ventes
```

### Statut
✅ Fait

---

## ETAPE 4 — Lancer l'ETL

### Ce que c'est
Les scripts Python lisent les CSV et les copient dans PostgreSQL (schéma `staging`).
Tout est inséré en TEXT brut — DBT fera la transformation ensuite.

### Fichiers
- `etl/etl_capilhair.py` — charge les 12 CSV de CapilHair
- `etl/etl_salonkera.py` — charge les 12 CSV de SalonKera
- `etl/etl_meteo.py` — récupère la météo (API ou CSV de secours)
- `etl/run_etl.py` — lance les 3 scripts dans l'ordre

### Commande
```bash
python etl/run_etl.py
```

Résultat attendu :
```
[ETL CapilHair] Terminé — ... lignes
[ETL SalonKera] Terminé — ... lignes
[ETL Météo] Terminé — ... lignes
```

### Vérification
```bash
# Vérifier que les tables staging existent
psql -U postgres -d datawarehouse -c "\dt staging.*"
```
Doit afficher toutes les tables `raw_capilhair_*`, `raw_salonkera_*`, `raw_meteo`.

```bash
# Vérifier que les données sont bien là
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM staging.raw_capilhair_clients;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM staging.raw_salonkera_clients;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM staging.raw_capilhair_ventes;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM staging.raw_meteo;"
```
Doit afficher des nombres supérieurs à 0.

```bash
# Voir les premières lignes brutes
psql -U postgres -d datawarehouse -c "SELECT * FROM staging.raw_capilhair_clients LIMIT 3;"
```

### Statut
✅ Fait

---

## ETAPE 5 — Lancer DBT

### Ce que c'est
DBT lit les tables brutes `staging.raw_*` et crée les tables analytiques propres dans `dwh`.

```
staging.raw_capilhair_clients  ──┐
                                  ├──► dwh.dim_clients (propre, typé, unifié)
staging.raw_salonkera_clients  ──┘

staging.raw_capilhair_ventes   ──┐
                                  ├──► dwh.fact_ventes (avec jointures vers dim_*)
staging.raw_salonkera_ventes   ──┘
```

### Commandes
```bash
cd dbt_project
dbt run
```

Résultat attendu :
```
OK created view staging.stg_capilhair_clients
OK created view staging.stg_salonkera_clients
...
OK created table dwh.dim_clients
OK created table dwh.dim_produits
OK created table dwh.dim_employes
OK created table dwh.fact_ventes
OK created table dwh.fact_rendez_vous
OK created table dwh.fact_actions_crm
Completed with 0 errors
```

### Vérification — tables remplies
```bash
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM dwh.dim_clients;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM dwh.dim_produits;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM dwh.dim_employes;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM dwh.fact_ventes;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM dwh.fact_rendez_vous;"
psql -U postgres -d datawarehouse -c "SELECT COUNT(*) FROM dwh.fact_actions_crm;"
```
Doit afficher des nombres supérieurs à 0.

### Vérification — contenu des données
```bash
psql -U postgres -d datawarehouse
```

Puis dans psql :
```sql
-- Clients des 2 boutiques réunis
SELECT code_client, nom_prenom, source_boutique, type_cheveux
FROM dwh.dim_clients LIMIT 5;

-- Ventes avec montants
SELECT code_vente, prix_total, canal_achat
FROM dwh.fact_ventes LIMIT 5;

-- Répartition clients par boutique
SELECT source_boutique, COUNT(*) as nb_clients
FROM dwh.dim_clients
GROUP BY source_boutique;

-- Quitter psql
\q
```

### Statut
⏳ En cours de test

---

## ETAPE 6 — Tester les données DBT

### Ce que c'est
DBT vérifie automatiquement la qualité des données :
- Pas de doublons dans les clés primaires
- Pas de valeurs nulles obligatoires
- Chaque vente pointe vers un client qui existe

### Commande
```bash
dbt test
```

Résultat attendu :
```
PASS ... tests
Completed with 0 errors
```

### Statut
⏳ En cours de test

---

## ETAPE 7 — Airflow (à faire)

### Ce que c'est
Airflow est un **chef d'orchestre** — il lance automatiquement ETL → DBT dans l'ordre, sans que vous tapiez les commandes manuellement.

Le DAG (= la recette) fait :
```
1. Lance ETL capilhair + salonkera + meteo
       ↓
2. Lance DBT run
       ↓
3. Lance DBT test
       ↓
4. Pipeline terminé ✅
```

### Fichiers
- `airflow/dag_pipeline.py` — à créer

### Statut
❌ À faire

---

## Résumé de l'avancement

| Etape | Ce que ça fait | Statut |
|-------|---------------|--------|
| 1. Installation | Installer Python + DBT | ✅ Fait |
| 2. Base PostgreSQL | Créer la base datawarehouse | ✅ Fait |
| 3. Schema SQL | Créer la structure dwh en étoile | ✅ Fait |
| 4. ETL Python | Charger les CSV dans staging | ✅ Fait |
| 5. DBT run | Transformer staging → dwh | ⏳ En test |
| 6. DBT test | Vérifier la qualité des données | ⏳ En test |
| 7. Airflow | Automatiser tout le pipeline | ❌ À faire |
| 8. Power BI | Dashboard sur les tables dwh.* | ❌ Après DBT validé |
