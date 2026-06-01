with source as (
    select * from staging.raw_capilhair_actions_crm
)

select
    "id_action"             as code_action,
    "id_client"             as code_client,
    "id_produit"            as code_produit,
    "date"::date            as date_action,
    "type_action"           as type_action,
    "canal"                 as canal,
    "cout"::numeric         as cout,
    case
        when lower("succes") in ('oui', 'true', '1', 'yes') then true
        else false
    end                     as succes,
    'capilhair'             as source_boutique
from source
