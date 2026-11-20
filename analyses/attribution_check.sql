-- Validates the session attribution assumptions. Compile with `dbt compile` and run the
-- SQL from target/compiled/... in the BigQuery console (analyses are not built as tables).

-- 1. Which events carry the session-scoped source / medium params?
--    Expectation: mostly the first events of a session (session_start, first_visit, page_view).
select
    event_name,
    count(*)                                              as events,
    countif(event_source is not null)                     as with_source,
    countif(event_medium is not null)                     as with_medium,
    round(safe_divide(countif(event_source is not null), count(*)), 3) as share_with_source
from {{ ref('stg_ga4__events') }}
group by event_name
order by with_source desc;

-- 2. How many sessions have a logged source, and is it stable within the session?
--    distinct_sources > 1 means "first non-null value" is a real choice, not a no-op.
select
    countif(n_sources = 0)                  as sessions_no_source,
    countif(n_sources = 1)                  as sessions_one_source,
    countif(n_sources > 1)                  as sessions_multiple_sources,
    count(*)                                as sessions
from (
    select session_key, count(distinct concat(event_source, '/', event_medium)) as n_sources
    from {{ ref('stg_ga4__events') }}
    where session_key is not null
    group by session_key
);

-- 3. Session-scoped vs user first-touch attribution: how often do they differ?
select
    attribution_basis,
    session_source = user_first_source and session_medium = user_first_medium as matches_first_touch,
    count(*) as sessions
from {{ ref('fct_sessions') }}
group by 1, 2
order by 1, 2;
