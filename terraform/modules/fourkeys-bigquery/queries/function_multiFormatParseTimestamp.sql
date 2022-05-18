CASE

-- 2022-01-05 04:36:28 -0800 -or- (...)+0800
WHEN REGEXP_CONTAINS(input, r"^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}$")
    THEN PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S %z', input)

-- 2022-01-12T09:47:26.948+01:00 -or- (...)-0100
WHEN REGEXP_CONTAINS(input, r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}[+-][0-9]{2}:[0-9]{2}$")
    THEN PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E3S%Ez', input)

-- 2022-01-18 05:35:35.320020 -or- 2022-01-18 05:35:35
WHEN REGEXP_CONTAINS(input, r"^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.?[0-9]*$")
    THEN PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S', input)

ELSE
    -- no regex match; attempt to cast directly to timestamp
    -- (if unparseable, this will throw an error)
    CAST(input AS TIMESTAMP)

END