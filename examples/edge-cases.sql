-- ============================================================
-- examples/edge-cases.sql
--
-- Casos límite: sentencias que parecen seguras superficialmente
-- porque contienen un WHERE o un LIMIT, pero siguen siendo
-- peligrosas o efectivamente sin límite. La skill debe razonar
-- sobre la intención y el impacto en lugar de comprobar solo la
-- presencia de las palabras clave.
--
-- Hallazgos esperados (traza de reglas):
--   SEC-003 CRITICAL  WHERE no restrictivo (1 = 1)
--   SEC-003 CRITICAL  WHERE no restrictivo (TRUE)
--   PERF-001 LOW      SELECT *
--   PERF-002 LOW      LIMIT efectivamente ilimitado (POTENCIAL)
--   SEC-004 HIGH      WHERE amplio en UPDATE (POTENCIAL)
--   CONV-002 LOW      Identificadores genéricos si el contexto es insuficiente
-- ============================================================

-- El WHERE existe pero siempre es verdadero. Afecta a todas las filas.
DELETE FROM TA_USERS
WHERE 1 = 1;

-- Mismo patrón usando una constante booleana literal.
UPDATE TA_USERS
SET FCROLE = 'ADMIN'
WHERE TRUE;

-- El LIMIT existe pero es absurdamente grande: efectivamente sin límite.
SELECT * FROM TA_USERS
LIMIT 1000000000;

-- El WHERE existe pero coincide con todas las filas no nulas:
-- efectivamente equivalente a actualizar toda la columna.
UPDATE TA_USERS
SET FCROLE = 'ADMIN'
WHERE FCEMAIL LIKE '%';
