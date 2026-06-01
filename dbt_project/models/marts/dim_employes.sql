with capilhair as (
    select * from {{ ref('stg_capilhair_employes') }}
),

salonkera as (
    select * from {{ ref('stg_salonkera_employes') }}
),

unioned as (
    select * from capilhair
    union all
    select * from salonkera
)

select
    row_number() over (order by source_boutique, code_employe) as id_employe,
    code_employe,
    source_boutique,
    nom_prenom,
    poste,
    specialite,
    date_embauche
from unioned
