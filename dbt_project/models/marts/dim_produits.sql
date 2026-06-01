with capilhair as (
    select * from {{ ref('stg_capilhair_produits') }}
),

salonkera as (
    select * from {{ ref('stg_salonkera_produits') }}
),

unioned as (
    select * from capilhair
    union all
    select * from salonkera
)

select
    row_number() over (order by source_boutique, code_produit) as id_produit,
    code_produit,
    source_boutique,
    nom_produit,
    categorie,
    marque,
    prix_unitaire,
    type_cheveux_cible,
    description
from unioned
