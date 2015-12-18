SELECT e.id, e.occured_at, et.key
, MAX(IF(md.key='product_type', md.value, NULL)) AS product_type
, MAX(IF(rt.key='clarity_charge_project', s.friendly_name, NULL)) AS study
, MAX(IF(md.key='pipeline', md.value, NULL)) AS pipeline
, MAX(IF(md.key='number_of_samples', md.value, NULL)) AS number_of_samples
, MAX(IF(md.key='bait_library', md.value, NULL)) AS bait_library
, MAX(IF(md.key='library_type', md.value, NULL)) AS library_type
, MAX(IF(md.key='version', md.value, NULL)) AS version
, MAX(IF(md.key='platform', md.value, NULL)) AS platform
, MAX(IF(md.key='run_type', md.value, NULL)) AS run_type
, MAX(IF(md.key='read_length', md.value, NULL)) AS read_length
, MAX(IF(md.key='plex_level', md.value, NULL)) AS plex_level
, MAX(IF(md.key='cost_code', md.value, NULL)) AS cost_code
, MAX(IF(md.key='number_of_libraries', md.value, NULL)) AS number_of_libraries
, MAX(IF(md.key='number_of_lanes', md.value, NULL)) AS number_of_lanes
FROM metadata md
JOIN events e ON (md.event_id=e.id)
JOIN event_types et ON (e.event_type_id=et.id)
JOIN roles r ON (r.event_id=e.id)
JOIN role_types rt ON (rt.id=r.role_type_id)
JOIN subjects s ON (s.id=r.subject_id)
WHERE e.lims_id like 'C_GCLP_D'
GROUP BY e.id