-- PUNTO 1
SPOOL EJE_TP.SQL Y EJECUTAMOS TODO

-- PUNTO 2
SPOOL SINONIMOS.SQL

SELECT 'CREATE PUBLIC SYNONYM ' || TABLE_NAME || ' FOR ' || TABLE_NAME || ';' QUERY
FROM USER_TABLES;

SPOOL OFF

-- PUNTO 3
CREATE ROLE R_CONS;

-- PUNTO 4
GRANT SELECT ANY DICTIONARY TO R_CONS ;
