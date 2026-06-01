with source as (
    select * from staging.raw_salonkera_employes
)

select
    "id_employe"            as code_employe,
    trim("nom_prenom")      as nom_prenom,
    "poste"                 as poste,
    "specialite"            as specialite,
    "date_embauche"::date   as date_embauche,
    'salonkera'             as source_boutique
from source
