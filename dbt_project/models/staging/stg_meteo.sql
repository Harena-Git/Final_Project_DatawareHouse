with source as (
    select * from staging.raw_meteo
)

select
    "date"::date                        as date_complete,
    "ville"                             as ville,
    "temperature_max_c"::numeric        as temp_max,
    "temperature_min_c"::numeric        as temp_min,
    "humidite_pct"::numeric             as humidite,
    "precipitation_mm"::numeric         as precipitations,
    "conditions"                        as conditions,
    "vent_kmh"::numeric                 as vent,
    "saison"                            as saison,
    "uv_index"::numeric                 as uv_index
from source
