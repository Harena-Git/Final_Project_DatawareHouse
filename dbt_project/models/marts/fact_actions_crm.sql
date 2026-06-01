with capilhair as (
    select * from {{ ref('stg_capilhair_actions_crm') }}
),

salonkera as (
    select * from {{ ref('stg_salonkera_actions_crm') }}
),

actions as (
    select * from capilhair
    union all
    select * from salonkera
),

dim_clients as (
    select id_client, code_client, source_boutique
    from {{ ref('dim_clients') }}
),

dim_produits as (
    select id_produit, code_produit, source_boutique
    from {{ ref('dim_produits') }}
),

dim_date as (
    select id_date, date_complete from dwh.dim_date
),

boutiques as (
    select id_boutique, code_boutique from dwh.dim_boutiques
)

select
    row_number() over (order by a.source_boutique, a.code_action) as id_action,
    a.code_action,
    b.id_boutique,
    c.id_client,
    p.id_produit,
    d.id_date,
    a.type_action,
    a.canal,
    a.cout,
    a.succes
from actions a
left join dim_clients c
    on a.code_client = c.code_client
    and a.source_boutique = c.source_boutique
left join dim_produits p
    on a.code_produit = p.code_produit
    and a.source_boutique = p.source_boutique
left join dim_date d
    on a.date_action = d.date_complete
left join boutiques b
    on a.source_boutique = b.code_boutique
