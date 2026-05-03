import pandas as pd
import psycopg2

# Connexion PostgreSQL
conn = psycopg2.connect(
    dbname="dw_project",
    user="postgres",
    password="password",
    host="localhost",
    port="5432"
)

cursor = conn.cursor()

# Charger les fichiers CSV
clients = pd.read_csv("../data/clients.csv")
produits = pd.read_csv("../data/produits.csv")
commandes = pd.read_csv("../data/commandes.csv")

# Insertion clients
for _, row in clients.iterrows():
    cursor.execute(
        "INSERT INTO dim_clients VALUES (%s, %s, %s, %s)",
        (row.id_client, row.nom, row.email, row.ville)
    )

# Insertion produits
for _, row in produits.iterrows():
    cursor.execute(
        "INSERT INTO dim_produits VALUES (%s, %s, %s)",
        (row.id_produit, row.nom_produit, row.prix)
    )

# Insertion commandes
for _, row in commandes.iterrows():
    cursor.execute(
        "INSERT INTO fact_commandes VALUES (%s, %s, %s, %s, %s)",
        (row.id_commande, row.id_client, row.id_produit, row.quantite, row.date_commande)
    )

conn.commit()
cursor.close()
conn.close()

print("ETL terminé avec succès")