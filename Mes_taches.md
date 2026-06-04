## Directive Power BI
# Connexion
Serveur : localhost — Port : 5432
Base : datawarehouse
Importer uniquement les tables dwh.* — ignorer staging.*
Tables à importer :
dwh.dim_clients
dwh.dim_produits
dwh.dim_boutiques
dwh.dim_date
dwh.dim_meteo
dwh.fact_ventes
dwh.fact_rendez_vous
dwh.fact_actions_crm
dwh.pipeline_runs

# Page 1 — Vue générale
KPIs en haut :
- Chiffre d'affaires total (SUM fact_ventes.prix_total)
- Nombre de clients (COUNT dim_clients)
- Note moyenne prestations (AVG fact_rendez_vous.note_client)
- Taux succès CRM (% fact_actions_crm.succes = Oui)

# Page 2 — Profil des clients
- Graphe en anneau : répartition par sexe
- Histogramme : répartition par tranche d'âge
- Barres : types de cheveux les plus fréquents
- Barres : problèmes capillaires les plus signalés
- Barres : réseaux sociaux utilisés (Instagram, TikTok, Facebook...)
- Segments : budget (Petit / Moyen / Grand / Premium)

# Page 3 — Ventes & comportement d'achat
- Courbe : évolution mensuelle du CA
- Barres : top 10 produits les plus vendus
- Anneau : canal d'achat (Boutique vs En ligne)
- Anneau : mode de paiement (Espèces / Mobile Money / Carte)
- Filtre : par boutique (CapilHair / SalonKera)