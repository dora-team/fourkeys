CREATE OR REPLACE FUNCTION four_keys.json2array(json STRING)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  if (json) {
    return JSON.parse(json).map(x=>JSON.stringify(x));
  } else {
    return [];
  }
""";