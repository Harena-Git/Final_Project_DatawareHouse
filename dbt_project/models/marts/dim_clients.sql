with capilhair as (
    select * from {{ ref('stg_capilhair_clients') }}
),

salonkera as (
    select * from {{ ref('stg_salonkera_clients') }}
),

unioned as (
    select * from capilhair
    union all
    select * from salonkera
)

select
    row_number() over (order by source_boutique, code_client) as id_client,
    code_client,
    source_boutique,
    nom_prenom,
    sexe,
    age,
    tranche_age,
    email,
    telephone,
    ville,
    type_cheveux,
    problemes,
    routine,
    reseaux_sociaux,
    budget_mensuel,
    segment_budget,
    date_inscription
from unioned
