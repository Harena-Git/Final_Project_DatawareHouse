with source as (
    select * from staging.raw_salonkera_clients
)

select
    "id_client"                 as code_client,
    trim("nom_prenom")          as nom_prenom,
    "sexe"                      as sexe,
    "age"::integer              as age,
    case
        when "age"::integer < 25 then '18-24'
        when "age"::integer < 35 then '25-34'
        when "age"::integer < 45 then '35-44'
        when "age"::integer < 55 then '45-54'
        else '55+'
    end                         as tranche_age,
    lower(trim("email"))        as email,
    "telephone"                 as telephone,
    "type_cheveux"              as type_cheveux,
    "problemes"                 as problemes,
    "routine"                   as routine,
    "reseaux_sociaux"           as reseaux_sociaux,
    "budget_mensuel"::integer   as budget_mensuel,
    case
        when "budget_mensuel"::integer < 30000 then 'Petit budget'
        when "budget_mensuel"::integer < 60000 then 'Budget moyen'
        else 'Grand budget'
    end                         as segment_budget,
    "ville"                     as ville,
    "date_inscription"::date    as date_inscription,
    'salonkera'                 as source_boutique
from source
