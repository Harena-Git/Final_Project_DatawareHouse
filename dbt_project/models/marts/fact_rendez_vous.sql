with capilhair as (
    select * from {{ ref('stg_capilhair_rendez_vous') }}
),

salonkera as (
    select * from {{ ref('stg_salonkera_rendez_vous') }}
),

rdv as (
    select * from capilhair
    union all
    select * from salonkera
),

dim_clients as (
    select id_client, code_client, source_boutique
    from {{ ref('dim_clients') }}
),

dim_employes as (
    select id_employe, code_employe, source_boutique
    from {{ ref('dim_employes') }}
),

dim_date as (
    select id_date, date_complete from dwh.dim_date
),

boutiques as (
    select id_boutique, code_boutique from dwh.dim_boutiques
),

avis as (
    select "id_rdv" as code_rdv, "note"::integer as note_client
    from staging.raw_capilhair_avis_clients
    union all
    select "id_rdv" as code_rdv, "note"::integer as note_client
    from staging.raw_salonkera_avis_clients
)

select
    row_number() over (order by r.source_boutique, r.code_rdv) as id_rdv,
    r.code_rdv,
    b.id_boutique,
    c.id_client,
    e.id_employe,
    d.id_date,
    r.type_soin,
    r.duree_min,
    r.prix,
    r.statut,
    a.note_client
from rdv r
left join dim_clients c
    on r.code_client = c.code_client
    and r.source_boutique = c.source_boutique
left join dim_employes e
    on r.code_employe = e.code_employe
    and r.source_boutique = e.source_boutique
left join dim_date d
    on r.date_rdv = d.date_complete
left join boutiques b
    on r.source_boutique = b.code_boutique
left join avis a
    on r.code_rdv = a.code_rdv
