WITH ValueChanges AS (
    -- Detect changes in VALUE for each group
    SELECT
        SENSOR_TIME_STAMP,
        INTEGER_VALUE,
        FLOAT_VALUE,
        STRING_VALUE,
        DATE_VALUE,
        DATA_INTEGRITY,
        SITE,
        TAG_UNIQUE_ID,
        ORIGINAL_DATASET,
        INSERT_DATE,
        TAG_SENSOR_NAME,
        TAG_PATH,
        TAG_SENSOR_TYPE,
        TAG_LOCATION_NAME,
        DATA_TYPE,
        TAG_CREATED_DATE,
        TAG_RETIRED_DATE,
        CASE
            WHEN VALUE != LAG(VALUE, 1, VALUE) OVER (PARTITION BY ORIGINAL_DATASET, TAG_SENSOR_NAME, MACHINE_NAME, TAG_LOCATION_NAME ORDER BY SENSOR_TIME_STAMP)
            THEN 1
            ELSE 0
        END AS value_change_flag
    FROM
        source_table -- Replace with your actual source table name
),
ValueGroups AS (
    -- Create groups of consecutive identical values
    SELECT
        *,
        SUM(value_change_flag) OVER (PARTITION BY ORIGINAL_DATASET, TAG_SENSOR_NAME, MACHINE_NAME, TAG_LOCATION_NAME ORDER BY SENSOR_TIME_STAMP) AS value_group
    FROM
        ValueChanges
)
-- Final query to get START_TIME, END_TIME, and other required columns
SELECT
    MIN(SENSOR_TIME_STAMP) AS START_TIME,
    MAX(SENSOR_TIME_STAMP) AS END_TIME,
    MAX(VALUE) AS VALUE, -- Since VALUE is constant within the group, MAX, MIN, or AVG will work
    TAG_SENSOR_NAME,
    CURRENT_DATE AS TRANSACTION_DATE, -- Or use a specific date column if available
    MACHINE_NAME,
    TAG_LOCATION_NAME,
    SITE
FROM
    ValueGroups
GROUP BY
    ORIGINAL_DATASET,
    TAG_SENSOR_NAME,
    MACHINE_NAME,
    TAG_LOCATION_NAME,
    value_group,
    SITE
ORDER BY
    TAG_SENSOR_NAME,
    MACHINE_NAME,
    TAG_LOCATION_NAME,
    START_TIME;
