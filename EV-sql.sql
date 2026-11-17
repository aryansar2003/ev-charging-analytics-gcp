-- SECTION 1: DATA VALIDATION

-- Query 1: Verify row counts across all four tables

SELECT
    'Charging Reports' AS dataset,
    COUNT(*) AS total_rows
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_charging_reports`

UNION ALL

SELECT
    'User Predictions',
    COUNT(*)
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_user_predictions`

UNION ALL

SELECT
    'Session Predictions',
    COUNT(*)
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_session_predictions`

UNION ALL

SELECT
    'Hourly Predictions',
    COUNT(*)
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_hourly_predictions`;


-- Query 2: Inspect table schemas

SELECT
    table_name,
    column_name,
    data_type
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.INFORMATION_SCHEMA.COLUMNS`
ORDER BY
    table_name,
    ordinal_position;

-- Query 3: Charging activity by hour
-- Business Question: At what hours do residents typically
-- plug in their electric vehicles?

SELECT
    plugin_hour,
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT user_id) AS unique_users
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_charging_reports`
GROUP BY
    plugin_hour
ORDER BY
    plugin_hour;


-- Query 4: Charging activity by day
-- Business Question: Which days have the highest
-- charging activity?

SELECT
    plugin_day,
    COUNT(*) AS total_sessions
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_charging_reports`
GROUP BY
    plugin_day
ORDER BY
    total_sessions DESC;


-- Query 5: Predicted energy demand by hour
-- Business Question: When does predicted hourly energy
-- demand reach its peak?

SELECT
    hour,
    SUM(IFNULL(energy_charged_i, 0)) AS predicted_energy_demand
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_hourly_predictions`
GROUP BY
    hour
ORDER BY
    predicted_energy_demand DESC;


-- Query 6: Average charging time and idle time
-- Business Question: How long do vehicles spend charging
-- and remaining idle?

SELECT
    COUNT(*) AS total_sessions,
    ROUND(AVG(charging_time), 2) AS avg_charging_time,
    ROUND(AVG(idle_time), 2) AS avg_idle_time
FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_session_predictions`;


-- Query 7: Identify sessions with potential charging flexibility
-- Business Question: Which sessions have at least one hour
-- of predicted idle time?

SELECT
    COUNT(*) AS total_sessions,

    COUNTIF(idle_time >= 1) AS potential_flexible_sessions,

    ROUND(
        AVG(
            CASE
                WHEN idle_time >= 1 THEN idle_time
            END
        ), 2
    ) AS avg_flexible_idle_hours

FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_session_predictions`;


-- Query 8: Charging sessions and predicted energy by location
-- Business Question: How does charging activity and predicted
-- energy demand vary across residential locations?


SELECT
    c.location,

    ROUND(
        SUM(IFNULL(h.energy_charged_i, 0))
        / COUNT(DISTINCT c.session_id),
        2
    ) AS avg_predicted_energy_per_session,

    COUNT(DISTINCT c.session_id) AS total_charging_sessions,

    ROUND(
        SUM(IFNULL(h.energy_charged_i, 0)),
        2
    ) AS predicted_energy_demand

FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_charging_reports` AS c

INNER JOIN
    `ev-charging-analytics-2026.ev_charging_analytics.src_hourly_predictions` AS h

    ON c.session_id = h.session_id
    AND c.user_id = h.user_id

GROUP BY
    c.location

ORDER BY
    predicted_energy_demand DESC;


-- Query 9: Identify lower predicted energy demand hours
-- Business Question: Which hours have relatively lower
-- predicted charging demand?

SELECT
    hour,

    ROUND(
        SUM(IFNULL(energy_charged_i, 0)), 2
    ) AS predicted_energy_demand

FROM
    `ev-charging-analytics-2026.ev_charging_analytics.src_hourly_predictions`

GROUP BY
    hour

ORDER BY
    predicted_energy_demand ASC;


