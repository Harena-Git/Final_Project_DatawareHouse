with source as (
    select * from staging.raw_capilhair_rendez_vous
)

select
    "id_rdv"                as code_rdv,
    "id_client"             as code_client,
    "id_employe"            as code_employe,
    "date_rdv"::date        as date_rdv,
    "heure"                 as heure,
    "duree_min"::integer    as duree_min,
    "type_soin"             as type_soin,
    "statut"                as statut,
    "prix"::numeric         as prix,
    "commentaire"           as commentaire,
    'capilhair'             as source_boutique
from source
