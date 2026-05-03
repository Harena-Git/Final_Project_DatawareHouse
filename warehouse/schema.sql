CREATE TABLE dim_clients (
    id_client INT PRIMARY KEY,
    nom VARCHAR(100),
    email VARCHAR(100),
    ville VARCHAR(100)
);

CREATE TABLE dim_produits (
    id_produit INT PRIMARY KEY,
    nom_produit VARCHAR(100),
    prix DECIMAL
);

CREATE TABLE fact_commandes (
    id_commande INT PRIMARY KEY,
    id_client INT,
    id_produit INT,
    quantite INT,
    date_commande DATE,
    FOREIGN KEY (id_client) REFERENCES dim_clients(id_client),
    FOREIGN KEY (id_produit) REFERENCES dim_produits(id_produit)
);