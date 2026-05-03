# 📊 Projet Data Warehouse — Analyse des ventes e-commerce

---

## 🧠 1. Contexte du projet

Ce projet a pour objectif de mettre en place un **pipeline de données complet (Data Pipeline)** permettant de :

* Collecter des données brutes
* Les nettoyer et les structurer
* Les stocker dans un Data Warehouse
* Automatiser leur traitement
* Les visualiser à travers des tableaux de bord

Ce projet s’inscrit dans une démarche de **Data Engineering** et est considéré comme un **mini-mémoire**.

---

## 🎯 2. Objectifs

* Implémenter un processus **ETL (Extract, Transform, Load)**
* Construire un **Data Warehouse**
* Utiliser **DBT** pour les transformations
* Automatiser le pipeline avec **Airflow**
* Créer un **dashboard analytique**

---

## 🧱 3. Architecture du projet

Pipeline global :

```
Sources (CSV)
   ↓
ETL (Python)
   ↓
Data Warehouse (PostgreSQL)
   ↓
Transformation (DBT)
   ↓
Automatisation (Airflow)
   ↓
Visualisation (Dashboard)
```

---

## 🗂️ 4. Structure du projet

```
datawarehouse_project/
│
├── data/                  # Sources de données (CSV)
│   ├── clients.csv
│   ├── produits.csv
│   └── commandes.csv
│
├── etl/                   # Scripts ETL Python
│   └── extract_load.py
│
├── warehouse/             # Scripts SQL
│   └── schema.sql
│
├── dbt_project/           # Projet DBT (transformations)
│
├── airflow/               # DAG Airflow (automatisation)
│   └── dag_pipeline.py
│
└── README.md              # Documentation du projet
```

---

## 📥 5. Sources de données

Les données utilisées sont simulées sous forme de fichiers CSV :

### 📄 clients.csv

* Informations des clients

### 📄 produits.csv

* Catalogue des produits

### 📄 commandes.csv

* Historique des commandes

---

## 🗄️ 6. Data Warehouse

Le Data Warehouse est conçu selon un modèle simplifié inspiré du **modèle en étoile**.

### Tables :

* **dim_clients**
* **dim_produits**
* **fact_commandes**

### Objectif :

* Séparer les données en :

  * dimensions (clients, produits)
  * faits (commandes)

---

## 🐍 7. ETL (Extract, Transform, Load)

Le script Python permet de :

1. Extraire les données depuis les fichiers CSV
2. Transformer les données (format, nettoyage simple)
3. Charger les données dans PostgreSQL

### Technologies utilisées :

* Python
* pandas
* psycopg2

---

## 🔄 8. Transformations avec DBT

DBT permet de :

* Nettoyer les données
* Créer des tables analytiques
* Calculer des indicateurs

### Exemples de transformations :

* Chiffre d’affaires total
* Ventes par produit
* Ventes par mois
* Top clients

---

## ⚙️ 9. Automatisation avec Airflow

Airflow est utilisé pour :

* Automatiser l’exécution du pipeline
* Planifier les tâches
* Gérer les dépendances

### Exemple de workflow :

1. Exécution ETL
2. Lancement DBT
3. Mise à jour des tables analytiques

---

## 📊 10. Visualisation des données

Les données sont exploitées sous forme de dashboard.

### Outils possibles :

* Metabase
* Power BI

### Indicateurs affichés :

* Chiffre d’affaires
* Top produits
* Évolution des ventes
* Analyse clients

---

## 🛠️ 11. Technologies utilisées

| Outil      | Rôle                       |
| ---------- | -------------------------- |
| Python     | ETL                        |
| PostgreSQL | Base de données            |
| DBT        | Transformation des données |
| Airflow    | Automatisation             |
| Metabase   | Visualisation              |

---

## ▶️ 12. Exécution du projet

### Étapes :

1. Créer la base de données PostgreSQL
2. Exécuter le script SQL (`schema.sql`)
3. Lancer le script ETL :

```bash
python etl/extract_load.py
```

4. Exécuter DBT :

```bash
dbt run
```

5. Lancer Airflow (optionnel pour automatisation)

---

## 📈 13. Résultats attendus

* Base de données structurée
* Données propres et exploitables
* Dashboard interactif
* Pipeline automatisé

---

## 📘 14. Conclusion

Ce projet démontre la mise en place complète d’un système de traitement de données moderne, incluant :

* ingestion
* transformation
* stockage
* automatisation
* visualisation

Il représente une base solide pour des projets de **Data Engineering** à plus grande échelle.

---

## 👤 15. Auteur

* Noms : Harena, Ny Eja, Ny Voary, Fifaliana
* Projet académique — Data Warehouse
