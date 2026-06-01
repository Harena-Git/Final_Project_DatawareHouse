with source as (
    select * from staging.raw_capilhair_produits
)

select
    "id_produit"                as code_produit,
    trim("nom_produit")         as nom_produit,
    "categorie"                 as categorie,
    "marque"                    as marque,
    "prix_unitaire"::numeric    as prix_unitaire,
    "type_cheveux_cible"        as type_cheveux_cible,
    "description"               as description,
    'capilhair'                 as source_boutique
from source
