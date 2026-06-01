with source as (
    select * from staging.raw_salonkera_ventes
)

select
    "id_vente"              as code_vente,
    "id_client"             as code_client,
    "id_produit"            as code_produit,
    "date_achat"::date      as date_achat,
    "quantite"::integer     as quantite,
    "prix_total"::numeric   as prix_total,
    "canal_achat"           as canal_achat,
    "mode_paiement"         as mode_paiement,
    'salonkera'             as source_boutique
from source
