# Projet Final — Analyse du Comportement Client (Data Warehouse)

> Projet académique de type **mini-mémoire**

---

## 1. Contexte du projet

Ce projet a pour objectif de mettre en place un **pipeline de données complet** pour analyser le **comportement client** d'un salon capillaire (basé sur le projet [CapilHair](../CapilHair)).

Les données clients (types de cheveux, problèmes capillaires, habitudes d'achat, budget, canaux digitaux...) sont collectées depuis plusieurs sources, nettoyées, organisées dans un Data Warehouse, puis visualisées dans un dashboard interactif.

Flux global :

```
Données  →  Nettoyage  →  Organisation  →  Automatisation  →  Dashboard
```

La note finale dépend de la qualité de ce projet.

---

## 2. Objectifs

- Construire un pipeline ETL multi-sources
- Transformer et modéliser les données avec DBT
- Automatiser l'ensemble du workflow avec Airflow
- Surveiller l'état du pipeline (monitoring des nœuds)
- Envoyer un rapport par email à la fin du workflow
- Visualiser les résultats dans **Power BI**

---

## 3. Architecture du pipeline

```
┌──────────────────────────────────────────────────────┐
│                      SOURCES                         │
│   CSV (clients, ventes)  |  BDD  |  API              │
└────────────────┬─────────────────────────────────────┘
                 │  ETL (Extract → Transform → Load)
                 ▼
┌──────────────────────────────────────────────────────┐
│            DATA WAREHOUSE (PostgreSQL)               │
└────────────────┬─────────────────────────────────────┘
                 │  Transformation & modélisation
                 ▼
┌──────────────────────────────────────────────────────┐
│                  DBT (models, tests)                 │
└────────────────┬─────────────────────────────────────┘
                 │  Orchestration & automatisation
                 ▼
┌──────────────────────────────────────────────────────┐
│              AIRFLOW (DAG / Workflow)                │
│   [ETL] → [DBT run] → [Monitoring] → [Mail rapport] │
└────────────────┬─────────────────────────────────────┘
                 │  Visualisation
                 ▼
┌──────────────────────────────────────────────────────┐
│              POWER BI (Dashboard final)              │
└──────────────────────────────────────────────────────┘
```

---

## 4. Sources de données

Le projet exploite **3 sources indépendantes** :

### Boutique 1 — CapilHair (Antananarivo)
Système d'analyse comportementale des clients et d'actions CRM adaptées aux types de cheveux et aux comportements d'achat.

| Fichier CSV | Contenu |
|-------------|---------|
| `clients.csv` | Profils : âge, sexe, type de cheveux, routine, budget |
| `produits.csv` | Catalogue produits capillaires |
| `ventes.csv` | Historique des achats (canal, montant, date) |
| `actions_crm.csv` | Campagnes CRM ciblées par profil client |
| `rendez_vous.csv` | Réservations soins en boutique |
| `avis_clients.csv` | Notes et commentaires post-prestation |
| `programme_fidelite.csv` | Niveaux Bronze / Argent / Or / Platine |
| `stocks.csv` | Niveaux de stock par produit |
| `employes.csv` | Équipe et performances |
| `promotions.csv` | Campagnes promotionnelles |
| `remboursements.csv` | Demandes de retour/remboursement |
| `abonnements.csv` | Formules d'abonnement mensuel |

### Boutique 2 — SalonKera (Toamasina)
Deuxième boutique indépendante, en zone côtière tropicale — profils clients et gamme produits adaptés au climat humide.

| Fichier CSV | Contenu |
|-------------|---------|
| `clients.csv` | Profils clients de Toamasina |
| `produits.csv` | Gamme tropicale (frizz control, UV, humidité) |
| `ventes.csv` | Historique des achats |
| `actions_crm.csv` | Actions CRM adaptées au profil côtier |
| `rendez_vous.csv` | Réservations soins |
| `avis_clients.csv` | Notes et commentaires |
| `programme_fidelite.csv` | Programme fidélité |
| `stocks.csv` | Niveaux de stock |
| `employes.csv` | Équipe SalonKera |
| `promotions.csv` | Campagnes promotionnelles |
| `remboursements.csv` | Retours et remboursements |
| `abonnements.csv` | Abonnements mensuels |

### Source 3 — API Météo (OpenWeatherMap)
Données météo hebdomadaires pour les deux villes — corrélation entre conditions climatiques (humidité, pluie, saison sèche) et comportement d'achat des clients.

| Fichier | Contenu |
|---------|---------|
| `meteo_antananarivo.csv` | Température, humidité, précipitations, saison |
| `meteo_toamasina.csv` | Mêmes indicateurs pour le climat côtier |

> Script ETL : `etl/etl_meteo.py` — appelle l'API en temps réel, bascule sur le CSV de secours si la clé API n'est pas configurée.

---

## 5. Outils & technologies

| Outil | Rôle |
|-------|------|
| **Python / pandas** | ETL — extraction et chargement des données |
| **PostgreSQL** | Data Warehouse |
| **DBT** | Transformation et modélisation des données issues de l'ETL |
| **Airflow** | Automatisation, orchestration du workflow complet |
| **Power BI** | Visualisation finale (dashboard interactif) |

> L'ETL transite par **Airflow** (orchestration) et les données transformées passent par **DBT**.

---

## 6. Workflow Airflow (DAG)

Le DAG Airflow enchaîne les étapes suivantes :

```
[Extraction ETL]
      ↓
[Chargement Data Warehouse]
      ↓
[Transformation DBT]
      ↓
[Monitoring — vérification des nœuds]
      ↓
[Envoi rapport par email]
```

### Monitoring

- Chaque tâche du DAG expose son statut (succès / échec / en cours)
- Vue pipeline par **nœuds** : on voit en temps réel quelle étape tourne
- Alertes en cas d'échec d'un nœud

### Envoi de mail

- Un nœud dédié envoie automatiquement un rapport par email à la fin du workflow
- Le mail contient le résumé d'exécution (statuts, durées, éventuelles erreurs)

---

## 7. Vues & visualisation

### Vue pipeline (Airflow)

- Graphe des nœuds du DAG (vue Graph View dans Airflow)
- Permet de voir l'état de chaque étape : en attente, en cours, succès, échec

### Dashboard final (Power BI)

Les données après ETL + DBT sont **chargées dans Power BI** pour produire :

- Segmentation clients (type de cheveux, âge, budget)
- Top produits / services les plus demandés
- Évolution des ventes dans le temps
- Analyse des canaux d'acquisition (Instagram, Facebook, TikTok...)
- Comportement d'achat par profil client

---

## 8. Structure du projet

```
datawarehouse_project/
│
├── data/
│   ├── capilhair/               # Boutique 1 — Antananarivo (12 CSV)
│   │   ├── clients.csv
│   │   ├── produits.csv
│   │   ├── ventes.csv
│   │   ├── actions_crm.csv
│   │   ├── rendez_vous.csv
│   │   ├── avis_clients.csv
│   │   ├── programme_fidelite.csv
│   │   ├── stocks.csv
│   │   ├── employes.csv
│   │   ├── promotions.csv
│   │   ├── remboursements.csv
│   │   └── abonnements.csv
│   │
│   ├── salonkera/               # Boutique 2 — Toamasina (12 CSV)
│   │   ├── clients.csv
│   │   ├── produits.csv
│   │   ├── ventes.csv
│   │   ├── actions_crm.csv
│   │   ├── rendez_vous.csv
│   │   ├── avis_clients.csv
│   │   ├── programme_fidelite.csv
│   │   ├── stocks.csv
│   │   ├── employes.csv
│   │   ├── promotions.csv
│   │   ├── remboursements.csv
│   │   └── abonnements.csv
│   │
│   └── meteo/                   # Source API météo (CSV de secours)
│       ├── meteo_antananarivo.csv
│       └── meteo_toamasina.csv
│
├── etl/                         # Scripts ETL Python
│   ├── etl_capilhair.py         # Chargement boutique 1
│   ├── etl_salonkera.py         # Chargement boutique 2
│   └── etl_meteo.py             # Appel API OpenWeatherMap + fallback CSV
│
├── warehouse/                   # Scripts SQL
│   └── schema.sql
│
├── dbt_project/                 # Transformations DBT
│   ├── models/
│   └── dbt_project.yml
│
├── airflow/                     # DAGs Airflow
│   └── dag_pipeline.py
│
└── README.md
```

---

## 9. Résultats attendus

- Pipeline ETL fonctionnel sur plusieurs sources
- Data Warehouse structuré (modèle en étoile)
- Transformations DBT testées et documentées
- Workflow Airflow automatisé avec monitoring et envoi de mail
- Dashboard Power BI interactif chargé avec les données finales
