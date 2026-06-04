-- ===============================================================================
-- SCRIPT DE GENERATION DE DONNÉES AUTOMATIQUE POUR LE DATA WAREHOUSE (MOCK DATA)
-- À executer dans PostgreSQL (base: datawarehouse)
-- ===============================================================================

-- 1. Vider les tables existantes (pour éviter les doublons si vous relancez le script)
TRUNCATE TABLE dwh.fact_actions_crm, dwh.fact_rendez_vous, dwh.fact_ventes, dwh.dim_meteo RESTART IDENTITY CASCADE;
TRUNCATE TABLE dwh.dim_employes, dwh.dim_produits, dwh.dim_clients, dwh.pipeline_runs RESTART IDENTITY CASCADE;

-- =====================================================================
-- 2. DIMENSION CLIENTS (Génération de 1000 clients)
-- =====================================================================
INSERT INTO dwh.dim_clients (code_client, source_boutique, nom_prenom, sexe, age, tranche_age, ville, type_cheveux, problemes, routine, reseaux_sociaux, budget_mensuel, segment_budget, date_inscription)
SELECT 
    'C' || lpad(i::text, 4, '0'),
    (ARRAY['capilhair', 'salonkera'])[floor(random() * 2 + 1)],
    'Client ' || i,
    (ARRAY['M', 'F'])[floor(random() * 2 + 1)],
    floor(random() * 42 + 18)::smallint AS age,
    CASE 
        WHEN floor(random() * 42 + 18) BETWEEN 18 AND 25 THEN '18-25'
        WHEN floor(random() * 42 + 18) BETWEEN 26 AND 35 THEN '26-35'
        WHEN floor(random() * 42 + 18) BETWEEN 36 AND 45 THEN '36-45'
        ELSE '46+' 
    END,
    (ARRAY['Antananarivo', 'Toamasina', 'Majunga', 'Fianarantsoa'])[floor(random() * 4 + 1)],
    (ARRAY['Lisses', 'Boucles', 'Crépus', 'Ondules'])[floor(random() * 4 + 1)],
    (ARRAY['Pellicules', 'Chute', 'Secs', 'Gras', 'Aucun'])[floor(random() * 5 + 1)],
    (ARRAY['Basique', 'Complete', 'Premium'])[floor(random() * 3 + 1)],
    (ARRAY['Facebook', 'Instagram', 'TikTok'])[floor(random() * 3 + 1)],
    floor(random() * 250 + 20)::numeric(10,2) AS budget,
    CASE 
        WHEN floor(random() * 250 + 20) < 50 THEN 'Petit'
        WHEN floor(random() * 250 + 20) < 150 THEN 'Moyen'
        WHEN floor(random() * 250 + 20) < 200 THEN 'Grand'
        ELSE 'Premium' 
    END,
    '2023-01-01'::date + (floor(random() * 700)::integer)
FROM generate_series(1, 1000) s(i);

-- =====================================================================
-- 3. DIMENSION PRODUITS (Génération de 200 produits)
-- =====================================================================
INSERT INTO dwh.dim_produits (code_produit, source_boutique, nom_produit, categorie, marque, prix_unitaire, type_cheveux_cible)
SELECT 
    'P' || lpad(i::text, 4, '0'),
    (ARRAY['capilhair', 'salonkera'])[floor(random() * 2 + 1)],
    'Produit ' || i,
    (ARRAY['Shampoing', 'Masque', 'Huile', 'Serum', 'Coloration'])[floor(random() * 5 + 1)],
    (ARRAY['L''Oreal', 'Garnier', 'Kerastase', 'Naturals', 'Shea Moisture'])[floor(random() * 5 + 1)],
    floor(random() * 80 + 10)::numeric(10,2),
    (ARRAY['Tous', 'Secs', 'Gras', 'Colores', 'Abimes'])[floor(random() * 5 + 1)]
FROM generate_series(1, 200) s(i);

-- =====================================================================
-- 4. DIMENSION EMPLOYES (Génération de 50 employés)
-- =====================================================================
INSERT INTO dwh.dim_employes (code_employe, source_boutique, nom_prenom, poste, specialite, date_embauche)
SELECT 
    'E' || lpad(i::text, 3, '0'),
    (ARRAY['capilhair', 'salonkera'])[floor(random() * 2 + 1)],
    'Employe ' || i,
    (ARRAY['Coiffeur', 'Coloriste', 'Manager', 'Assistant'])[floor(random() * 4 + 1)],
    (ARRAY['Coupe', 'Coloration', 'Soin', 'Polyvalent'])[floor(random() * 4 + 1)],
    '2020-01-01'::date + (floor(random() * 1000)::integer)
FROM generate_series(1, 50) s(i);

-- =====================================================================
-- 5. METEO (Génération de 150 relevés météo)
-- =====================================================================
INSERT INTO dwh.dim_meteo (date_complete, id_date, ville, temperature_max_c, temperature_min_c, humidite_pct, precipitation_mm, conditions, vent_kmh, saison, uv_index)
SELECT 
    current_date - floor(random() * 500)::integer AS dt,
    to_char(current_date - floor(random() * 500)::integer, 'YYYYMMDD')::integer,
    (ARRAY['Antananarivo', 'Toamasina'])[floor(random() * 2 + 1)],
    floor(random() * 15 + 20)::numeric(5,1),
    floor(random() * 10 + 10)::numeric(5,1),
    floor(random() * 40 + 50)::numeric(5,1),
    floor(random() * 20)::numeric(6,1),
    (ARRAY['Ensoleille', 'Nuageux', 'Pluvieux'])[floor(random() * 3 + 1)],
    floor(random() * 30)::numeric(5,1),
    (ARRAY['Ete', 'Hiver', 'Automne', 'Printemps'])[floor(random() * 4 + 1)],
    floor(random() * 10 + 1)::smallint
FROM generate_series(1, 150) s(i)
ON CONFLICT (date_complete, ville) DO NOTHING;

-- =====================================================================
-- 6. FAITS VENTES (Génération de 5000 ventes)
-- =====================================================================
INSERT INTO dwh.fact_ventes (code_vente, id_boutique, id_client, id_produit, id_date, quantite, prix_unitaire, prix_total, canal_achat, mode_paiement)
SELECT 
    'V' || lpad(i::text, 6, '0'),
    floor(random() * 2 + 1)::integer,  -- entre 1 et 2 (CapilHair ou SalonKera)
    floor(random() * 999 + 1)::integer, -- référence à un id_client
    floor(random() * 199 + 1)::integer,  -- référence à un id_produit
    to_char('2023-01-01'::date + floor(random() * 800)::integer, 'YYYYMMDD')::integer, -- Ex: 20230514
    floor(random() * 5 + 1)::smallint AS qty,
    floor(random() * 80 + 10)::numeric(10,2) AS pu,
    (floor(random() * 5 + 1) * floor(random() * 80 + 10))::numeric(10,2) AS pt,
    (ARRAY['Boutique', 'En ligne'])[floor(random() * 2 + 1)],
    (ARRAY['Especes', 'Mobile Money', 'Carte bancaire'])[floor(random() * 3 + 1)]
FROM generate_series(1, 5000) s(i);

-- =====================================================================
-- 7. FAITS RENDEZ-VOUS (Génération de 3000 rendez-vous)
-- =====================================================================
INSERT INTO dwh.fact_rendez_vous (code_rdv, id_boutique, id_client, id_employe, id_date, type_soin, duree_min, prix, statut, note_client)
SELECT 
    'R' || lpad(i::text, 6, '0'),
    floor(random() * 2 + 1)::integer,
    floor(random() * 999 + 1)::integer,     -- sur 1000 clients
    floor(random() * 49 + 1)::integer,      -- sur 50 employés
    to_char('2023-01-01'::date + floor(random() * 800)::integer, 'YYYYMMDD')::integer,
    (ARRAY['Coupe Simple', 'Shampoing Brushing', 'Coloration Complete', 'Soin Botox', 'Poses Extensions'])[floor(random() * 5 + 1)],
    (ARRAY[30, 45, 60, 90, 120])[floor(random() * 5 + 1)]::smallint,
    floor(random() * 150 + 20)::numeric(10,2),
    (ARRAY['Effectue', 'Effectue', 'Effectue', 'Annule'])[floor(random() * 4 + 1)],
    floor(random() * 3 + 3)::smallint -- Note aléatoire entre 3 et 5
FROM generate_series(1, 3000) s(i);

-- =====================================================================
-- 8. FAITS ACTIONS CRM (Génération de 2000 actions CRM)
-- =====================================================================
INSERT INTO dwh.fact_actions_crm (code_action, id_boutique, id_client, id_produit, id_date, type_action, canal, cout, succes)
SELECT 
    'A' || lpad(i::text, 6, '0'),
    floor(random() * 2 + 1)::integer,
    floor(random() * 999 + 1)::integer,
    floor(random() * 199 + 1)::integer,
    to_char('2023-01-01'::date + floor(random() * 800)::integer, 'YYYYMMDD')::integer,
    (ARRAY['Email Promo', 'SMS Relance', 'Appel Anniversaire', 'Publicite Facebook'])[floor(random() * 4 + 1)],
    (ARRAY['Email', 'SMS', 'Telephone', 'Reseaux Sociaux'])[floor(random() * 4 + 1)],
    floor(random() * 10 + 1)::numeric(10,2),
    (random() > 0.4) -- Donne environ 60% de chance d'avoir la valeur TRUE (succés)
FROM generate_series(1, 2000) s(i);

-- =====================================================================
-- 9. PIPELINE RUNS (MOCK Historique Airflow)
-- =====================================================================
INSERT INTO dwh.pipeline_runs (dag_id, run_id, date_execution, statut, lignes_capilhair, lignes_salonkera, lignes_meteo, total_lignes, duree_secondes, dbt_statut, email_envoye)
SELECT 
    'dag_pipeline_etl',
    'run_' || to_char('2024-01-01'::date + i, 'YYYYMMDD'),
    ('2024-01-01'::date + i)::timestamp + interval '2 hours',
    (ARRAY['SUCCES', 'SUCCES', 'SUCCES', 'ERREUR'])[floor(random() * 4 + 1)],
    floor(random() * 500 + 100)::integer,
    floor(random() * 500 + 100)::integer,
    floor(random() * 50 + 10)::integer,
    floor(random() * 1000 + 200)::integer,
    floor(random() * 120 + 30)::numeric(8,2),
    (ARRAY['OK', 'OK', 'OK', 'ERREUR'])[floor(random() * 4 + 1)],
    (random() > 0.5)
FROM generate_series(1, 15) s(i);