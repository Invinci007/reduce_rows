WITH DailyValueChanges AS (
    -- Detect changes in VALUE or DAY for each group
    SELECT
        SENSOR_TIME_STAMP,
        FLOAT_VALUE,
        TAG_SENSOR_NAME,
        TAG_LOCATION_NAME,
        ORIGINAL_DATASET,
        SITE,
        CAST(SENSOR_TIME_STAMP AS DATE) AS sensor_day,
        CASE
            WHEN FLOAT_VALUE != LAG(FLOAT_VALUE, 1, FLOAT_VALUE) OVER (PARTITION BY ORIGINAL_DATASET, TAG_SENSOR_NAME, TAG_LOCATION_NAME, CAST(SENSOR_TIME_STAMP AS DATE) ORDER BY SENSOR_TIME_STAMP)
            THEN 1
            ELSE 0
        END AS value_change_flag
    FROM
        machine_ancillary_data_test -- Replace with your actual source table name
    WHERE
        site = 'ASC' AND
        ORIGINAL_DATASET = 'sqlt_data_1_2025_05'
),
DailyValueGroups AS (
    -- Create groups of consecutive identical values within the same day
    SELECT
        *,
        SUM(value_change_flag) OVER (PARTITION BY ORIGINAL_DATASET, TAG_SENSOR_NAME, TAG_LOCATION_NAME, sensor_day ORDER BY SENSOR_TIME_STAMP) AS daily_value_group
    FROM
        DailyValueChanges
)
-- Final query to get START_TIME, END_TIME, and other required columns
SELECT
    MIN(SENSOR_TIME_STAMP) AS START_TIME,
    MAX(SENSOR_TIME_STAMP) AS END_TIME,
    MAX(FLOAT_VALUE) AS FLOAT_VALUE,
    TAG_SENSOR_NAME,
    CURRENT_DATE AS TRANSACTION_DATE,
    TAG_LOCATION_NAME,
    ORIGINAL_DATASET,
    SITE
FROM
    DailyValueGroups
GROUP BY
    ORIGINAL_DATASET,
    TAG_SENSOR_NAME,
    TAG_LOCATION_NAME,
    sensor_day,
    daily_value_group,
    SITE
ORDER BY
    site,
    ORIGINAL_DATASET,
    tag_sensor_name,
    tag_location_name,
    START_TIME;
