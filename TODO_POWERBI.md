# TODO — Dashboard Power BI
> Harena & Fifa — à faire en parallèle

---

## Prérequis commun (faire ensemble, 10 min)

- [ ] Ouvrir **Power BI Desktop**
- [ ] `Obtenir des données` → `Base de données PostgreSQL`
- [ ] Serveur : `localhost` — Port : `5432` — Base : `datawarehouse`
- [ ] Importer **uniquement** ces tables :
  - `dwh.dim_clients`
  - `dwh.dim_produits`
  - `dwh.dim_boutiques`
  - `dwh.dim_date`
  - `dwh.dim_meteo`
  - `dwh.fact_ventes`
  - `dwh.fact_rendez_vous`
  - `dwh.fact_actions_crm`
  - `dwh.pipeline_runs`
- [ ] Vérifier que les relations sont bien détectées entre les tables (clés `id_client`, `id_produit`, `id_date`, `id_boutique`)

---

## HARENA — Pages 1, 2, 3

### Page 1 — Vue générale (KPIs)

- [ ] Carte : **Chiffre d'affaires total**
  - Mesure : `SUM(fact_ventes[prix_total])`
- [ ] Carte : **Nombre de clients**
  - Mesure : `DISTINCTCOUNT(dim_clients[id_client])`
- [ ] Carte : **Note moyenne prestations**
  - Mesure : `AVERAGE(fact_rendez_vous[note_client])`
- [ ] Carte : **Taux de succès CRM**
  - Mesure : `% de fact_actions_crm[succes] = "Oui"`
- [ ] Ajouter un **filtre global** par boutique (CapilHair / SalonKera) en haut de page

---

### Page 2 — Profil des clients

- [ ] Graphe en **anneau** : répartition par sexe (M / F)
- [ ] **Histogramme** : nombre de clients par tranche d'âge (18-25 / 26-35 / 36-45 / 46+)
- [ ] **Barres horizontales** : top types de cheveux (colonne `type_cheveux`)
- [ ] **Barres horizontales** : top problèmes capillaires (colonne `problemes`)
- [ ] **Barres horizontales** : réseaux sociaux utilisés (Instagram, TikTok, Facebook...)
- [ ] **Anneau** : répartition par segment budget (Petit / Moyen / Grand / Premium)

---

### Page 3 — Ventes & comportement d'achat

- [ ] **Courbe** : évolution mensuelle du chiffre d'affaires
  - Axe X : `dim_date[nom_mois]` — Axe Y : `SUM(fact_ventes[prix_total])`
- [ ] **Barres verticales** : top 10 produits les plus vendus
  - Lier `fact_ventes` → `dim_produits[nom_produit]`
- [ ] **Anneau** : répartition canal d'achat (Boutique vs En ligne)
- [ ] **Anneau** : répartition mode de paiement (Espèces / Mobile Money / Carte)
- [ ] **Filtre** : par boutique (CapilHair / SalonKera)
- [ ] **Filtre** : par période (mois / trimestre / année)

---

## FIFA — Pages 4, 5, 6

### Page 4 — Météo & saisonnalité

> C'est la page la plus originale du projet — bien la soigner.

- [ ] **Courbe double axe** : ventes vs humidité dans le temps
  - Axe X : date — Axe Y gauche : `SUM prix_total` — Axe Y droit : `AVG humidite_pct`
  - Lier `fact_ventes` → `dim_date` → `dim_meteo` sur `date_complete` et `ville`
- [ ] **Barres groupées** : chiffre d'affaires par saison
  - Utiliser `dim_date[saison_mada]` (Été pluies / Hiver sec / Transition)
- [ ] **Nuage de points** : température moyenne vs montant moyen d'achat par mois
- [ ] **Barres côte à côte** : ventes Antananarivo vs Toamasina par saison
  - Montre l'impact du climat humide (Toamasina) vs sec (Tana) sur les achats

---

### Page 5 — Comparaison boutiques

- [ ] **Barres groupées** : CA CapilHair vs SalonKera par mois
- [ ] **Barres groupées** : types de cheveux dominants par boutique
- [ ] **Barres groupées** : top 5 produits par boutique
- [ ] **Carte KPI** : note moyenne des prestations par boutique
- [ ] **Tableau** : résumé des indicateurs clés côte à côte
  | Indicateur | CapilHair | SalonKera |
  |---|---|---|
  | CA total | ... | ... |
  | Nb clients | ... | ... |
  | Note moyenne | ... | ... |
  | Produit top | ... | ... |

---

### Page 6 — Pipeline Airflow

> Prouve que l'automatisation fonctionne. Important pour le prof.

- [ ] **Carte** : date et heure du dernier run
  - Mesure : `MAX(pipeline_runs[date_execution])`
- [ ] **Carte colorée** : statut du dernier run
  - Vert si `SUCCÈS`, Rouge si `ERREUR`
- [ ] **Tableau** : historique des runs avec colonnes
  - `date_execution` / `statut` / `total_lignes` / `duree_secondes`
- [ ] **Barres** : nombre de lignes chargées par run (capilhair + salonkera + meteo empilés)
- [ ] **Texte explicatif** : "Ces données sont automatiquement mises à jour chaque jour à 6h00 par Airflow"

---

## Récap des pages par personne

| Page | Qui | Thème |
|---|---|---|
| Page 1 — KPIs | **Harena** | Vue d'ensemble |
| Page 2 — Profil clients | **Harena** | Qui sont nos clients ? |
| Page 3 — Ventes | **Harena** | Comment ils achètent ? |
| Page 4 — Météo | **Fifa** | Impact météo sur les achats |
| Page 5 — Boutiques | **Fifa** | CapilHair vs SalonKera |
| Page 6 — Pipeline | **Fifa** | Monitoring Airflow |

---

## Règles importantes

- **Ne pas importer** les tables `staging.*` — elles contiennent les données brutes non nettoyées
- **Toujours filtrer** par `source_boutique` quand on compare les deux boutiques
- Pour la page 4, lier la météo via `dim_date[date_complete]` = `dim_meteo[date_complete]` + `dim_boutiques[ville]` = `dim_meteo[ville]`
- Sauvegarder le fichier `.pbix` dans le dossier `powerbi/` du projet Git
