with capilhair as (
    select * from {{ ref('stg_capilhair_ventes') }}
),

salonkera as (
    select * from {{ ref('stg_salonkera_ventes') }}
),

ventes as (
    select * from capilhair
    union all
    select * from salonkera
),

dim_clients as (
    select id_client, code_client, source_boutique
    from {{ ref('dim_clients') }}
),

dim_produits as (
    select id_produit, code_produit, source_boutique, prix_unitaire
    from {{ ref('dim_produits') }}
),

dim_date as (
    select id_date, date_complete from dwh.dim_date
),

boutiques as (
    select id_boutique, code_boutique from dwh.dim_boutiques
)

select
    row_number() over (order by v.source_boutique, v.code_vente) as id_vente,
    v.code_vente,
    b.id_boutique,
    c.id_client,
    p.id_produit,
    d.id_date,
    v.quantite,
    p.prix_unitaire,
    v.prix_total,
    v.canal_achat,
    v.mode_paiement
from ventes v
left join dim_clients c
    on v.code_client = c.code_client
    and v.source_boutique = c.source_boutique
left join dim_produits p
    on v.code_produit = p.code_produit
    and v.source_boutique = p.source_boutique
left join dim_date d
    on v.date_achat = d.date_complete
left join boutiques b
    on v.source_boutique = b.code_boutique
