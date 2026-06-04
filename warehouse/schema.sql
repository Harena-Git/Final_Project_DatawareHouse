-- =============================================================
-- DATA WAREHOUSE — Analyse du Comportement Client
-- Projet : CapilHair + SalonKera
-- Modèle : Étoile (Star Schema)
-- =============================================================

-- =============================================================
-- SCHÉMAS
-- =============================================================

CREATE SCHEMA IF NOT EXISTS staging;   -- données brutes chargées par ETL
CREATE SCHEMA IF NOT EXISTS dwh;       -- data warehouse (dimensions + faits)


-- =============================================================
-- STAGING — tables brutes créées dynamiquement par les ETL
-- (etl_capilhair.py, etl_salonkera.py, etl_meteo.py)
-- Nommage : staging.raw_<boutique>_<table>
-- Ex : staging.raw_capilhair_clients, staging.raw_meteo
-- Ces tables sont recréées à chaque exécution ETL.
-- =============================================================


-- =============================================================
-- DIMENSIONS
-- =============================================================

-- Boutiques (CapilHair Tana + SalonKera Tamatave)
CREATE TABLE IF NOT EXISTS dwh.dim_boutiques (
    id_boutique     SERIAL PRIMARY KEY,
    code_boutique   VARCHAR(20) NOT NULL UNIQUE,  -- 'capilhair' | 'salonkera'
    nom             VARCHAR(100) NOT NULL,
    ville           VARCHAR(100) NOT NULL,
    region          VARCHAR(100),
    climat          VARCHAR(50),                  -- 'Hautes Terres' | 'Côte Est'
    date_ouverture  DATE,
    created_at      TIMESTAMP DEFAULT NOW()
);

INSERT INTO dwh.dim_boutiques (code_boutique, nom, ville, region, climat, date_ouverture)
VALUES
    ('capilhair', 'CapilHair', 'Antananarivo', 'Analamanga', 'Hautes Terres', '2020-01-01'),
    ('salonkera', 'SalonKera', 'Toamasina', 'Atsinanana', 'Côte Est (tropical humide)', '2018-05-01')
ON CONFLICT (code_boutique) DO NOTHING;


-- Clients (unifiés des deux boutiques)
CREATE TABLE IF NOT EXISTS dwh.dim_clients (
    id_client       SERIAL PRIMARY KEY,
    code_client     VARCHAR(20) NOT NULL,         -- C001, K001...
    source_boutique VARCHAR(20) NOT NULL,         -- 'capilhair' | 'salonkera'
    nom_prenom      VARCHAR(150),
    sexe            CHAR(1),                      -- M | F
    age             SMALLINT,
    tranche_age     VARCHAR(20),                  -- '18-25' | '26-35' | '36-45' | '46+'
    ville           VARCHAR(100),
    type_cheveux    VARCHAR(50),
    problemes       VARCHAR(100),
    routine         VARCHAR(50),
    reseaux_sociaux VARCHAR(50),
    budget_mensuel  NUMERIC(10,2),
    segment_budget  VARCHAR(20),                  -- 'Petit' | 'Moyen' | 'Grand' | 'Premium'
    date_inscription DATE,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (code_client, source_boutique)
);


-- Produits (unifiés des deux boutiques)
CREATE TABLE IF NOT EXISTS dwh.dim_produits (
    id_produit      SERIAL PRIMARY KEY,
    code_produit    VARCHAR(20) NOT NULL,
    source_boutique VARCHAR(20) NOT NULL,
    nom_produit     VARCHAR(200),
    categorie       VARCHAR(50),                  -- Shampoing | Masque | Huile | Sérum...
    marque          VARCHAR(100),
    prix_unitaire   NUMERIC(10,2),
    type_cheveux_cible VARCHAR(100),
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (code_produit, source_boutique)
);


-- Employés (unifiés des deux boutiques)
CREATE TABLE IF NOT EXISTS dwh.dim_employes (
    id_employe      SERIAL PRIMARY KEY,
    code_employe    VARCHAR(20) NOT NULL,
    source_boutique VARCHAR(20) NOT NULL,
    nom_prenom      VARCHAR(150),
    poste           VARCHAR(100),
    specialite      VARCHAR(150),
    date_embauche   DATE,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (code_employe, source_boutique)
);


-- Dimension Date (calendrier complet 2023-2026)
CREATE TABLE IF NOT EXISTS dwh.dim_date (
    id_date         INTEGER PRIMARY KEY,          -- format YYYYMMDD ex: 20240115
    date_complete   DATE NOT NULL UNIQUE,
    annee           SMALLINT,
    trimestre       SMALLINT,
    mois            SMALLINT,
    nom_mois        VARCHAR(20),
    semaine         SMALLINT,
    jour            SMALLINT,
    jour_semaine    SMALLINT,                     -- 1=Lundi ... 7=Dimanche
    nom_jour        VARCHAR(20),
    est_weekend     BOOLEAN,
    saison_mada     VARCHAR(40)                   -- Été/Hiver/Automne/Printemps (Madagascar)
);

INSERT INTO dwh.dim_date
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER         AS id_date,
    d                                        AS date_complete,
    EXTRACT(YEAR FROM d)::SMALLINT          AS annee,
    EXTRACT(QUARTER FROM d)::SMALLINT       AS trimestre,
    EXTRACT(MONTH FROM d)::SMALLINT         AS mois,
    TO_CHAR(d, 'TMMonth')                   AS nom_mois,
    EXTRACT(WEEK FROM d)::SMALLINT          AS semaine,
    EXTRACT(DAY FROM d)::SMALLINT           AS jour,
    EXTRACT(ISODOW FROM d)::SMALLINT        AS jour_semaine,
    TO_CHAR(d, 'TMDay')                     AS nom_jour,
    EXTRACT(ISODOW FROM d) IN (6,7)         AS est_weekend,
    CASE
        WHEN EXTRACT(MONTH FROM d) IN (11,12,1,2,3) THEN 'Été (saison des pluies)'
        WHEN EXTRACT(MONTH FROM d) IN (4,5)          THEN 'Automne (transition)'
        WHEN EXTRACT(MONTH FROM d) IN (6,7,8)        THEN 'Hiver (saison sèche)'
        ELSE 'Printemps (transition)'
    END                                     AS saison_mada
FROM GENERATE_SERIES('2023-01-01'::DATE, '2026-12-31'::DATE, '1 day') AS d
ON CONFLICT (id_date) DO NOTHING;


-- Météo
CREATE TABLE IF NOT EXISTS dwh.dim_meteo (
    id_meteo            SERIAL PRIMARY KEY,
    date_complete       DATE NOT NULL,
    id_date             INTEGER REFERENCES dwh.dim_date(id_date),
    ville               VARCHAR(100),
    temperature_max_c   NUMERIC(5,1),
    temperature_min_c   NUMERIC(5,1),
    humidite_pct        NUMERIC(5,1),
    precipitation_mm    NUMERIC(6,1),
    conditions          VARCHAR(100),
    vent_kmh            NUMERIC(5,1),
    saison              VARCHAR(50),
    uv_index            SMALLINT,
    created_at          TIMESTAMP DEFAULT NOW(),
    UNIQUE (date_complete, ville)
);


-- =============================================================
-- FAITS
-- =============================================================

-- Fait : Ventes
CREATE TABLE IF NOT EXISTS dwh.fact_ventes (
    id_fact_vente       SERIAL PRIMARY KEY,
    code_vente          VARCHAR(20),
    id_boutique         INTEGER REFERENCES dwh.dim_boutiques(id_boutique),
    id_client           INTEGER REFERENCES dwh.dim_clients(id_client),
    id_produit          INTEGER REFERENCES dwh.dim_produits(id_produit),
    id_date             INTEGER REFERENCES dwh.dim_date(id_date),
    quantite            SMALLINT,
    prix_unitaire       NUMERIC(10,2),
    prix_total          NUMERIC(10,2),
    canal_achat         VARCHAR(50),              -- 'Boutique' | 'En ligne'
    mode_paiement       VARCHAR(50),              -- 'Espèces' | 'Mobile Money' | 'Carte'
    created_at          TIMESTAMP DEFAULT NOW()
);


-- Fait : Rendez-vous / Prestations
CREATE TABLE IF NOT EXISTS dwh.fact_rendez_vous (
    id_fact_rdv         SERIAL PRIMARY KEY,
    code_rdv            VARCHAR(20),
    id_boutique         INTEGER REFERENCES dwh.dim_boutiques(id_boutique),
    id_client           INTEGER REFERENCES dwh.dim_clients(id_client),
    id_employe          INTEGER REFERENCES dwh.dim_employes(id_employe),
    id_date             INTEGER REFERENCES dwh.dim_date(id_date),
    type_soin           VARCHAR(150),
    duree_min           SMALLINT,
    prix                NUMERIC(10,2),
    statut              VARCHAR(20),              -- 'Effectué' | 'Annulé'
    note_client         SMALLINT,                 -- 1 à 5 (depuis avis_clients)
    created_at          TIMESTAMP DEFAULT NOW()
);


-- Fait : Actions CRM
CREATE TABLE IF NOT EXISTS dwh.fact_actions_crm (
    id_fact_crm         SERIAL PRIMARY KEY,
    code_action         VARCHAR(20),
    id_boutique         INTEGER REFERENCES dwh.dim_boutiques(id_boutique),
    id_client           INTEGER REFERENCES dwh.dim_clients(id_client),
    id_produit          INTEGER REFERENCES dwh.dim_produits(id_produit),
    id_date             INTEGER REFERENCES dwh.dim_date(id_date),
    type_action         VARCHAR(100),
    canal               VARCHAR(50),
    cout                NUMERIC(10,2),
    succes              BOOLEAN,
    created_at          TIMESTAMP DEFAULT NOW()
);


-- =============================================================
-- MONITORING PIPELINE — historique des runs Airflow
-- Chaque exécution du DAG écrit une ligne ici.
-- Power BI affiche cette table pour prouver l'automatisation.
-- =============================================================

CREATE TABLE IF NOT EXISTS dwh.pipeline_runs (
    id_run              SERIAL PRIMARY KEY,
    dag_id              VARCHAR(100),
    run_id              VARCHAR(200),
    date_execution      TIMESTAMP NOT NULL,
    statut              VARCHAR(20),           -- 'SUCCÈS' | 'ERREUR'
    lignes_capilhair    INTEGER DEFAULT 0,
    lignes_salonkera    INTEGER DEFAULT 0,
    lignes_meteo        INTEGER DEFAULT 0,
    total_lignes        INTEGER DEFAULT 0,
    duree_secondes      NUMERIC(8,2),
    dbt_statut          VARCHAR(20),           -- 'OK' | 'ERREUR'
    email_envoye        BOOLEAN DEFAULT FALSE,
    message             TEXT
);


-- =============================================================
-- INDEX (performances requêtes analytiques)
-- =============================================================

CREATE INDEX IF NOT EXISTS idx_fact_ventes_date     ON dwh.fact_ventes(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_ventes_client   ON dwh.fact_ventes(id_client);
CREATE INDEX IF NOT EXISTS idx_fact_ventes_produit  ON dwh.fact_ventes(id_produit);
CREATE INDEX IF NOT EXISTS idx_fact_ventes_boutique ON dwh.fact_ventes(id_boutique);

CREATE INDEX IF NOT EXISTS idx_fact_rdv_date        ON dwh.fact_rendez_vous(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_rdv_client      ON dwh.fact_rendez_vous(id_client);
CREATE INDEX IF NOT EXISTS idx_fact_rdv_boutique    ON dwh.fact_rendez_vous(id_boutique);

CREATE INDEX IF NOT EXISTS idx_fact_crm_date        ON dwh.fact_actions_crm(id_date);
CREATE INDEX IF NOT EXISTS idx_fact_crm_client      ON dwh.fact_actions_crm(id_client);

CREATE INDEX IF NOT EXISTS idx_meteo_date_ville     ON dwh.dim_meteo(date_complete, ville);
