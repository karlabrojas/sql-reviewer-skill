-- ============================================================
-- examples/invalid.sql
--
-- Caso de error: múltiples violaciones claras en un mismo script.
-- Hallazgos esperados (traza de reglas):
--   SEC-001 CRITICAL  DELETE sin WHERE
--   SEC-002 CRITICAL  UPDATE sin WHERE
--   SEC-005 CRITICAL  DROP TABLE (DDL destructivo)
--   SEC-007 HIGH      Concatenación de cadenas SQL con valor dinámico
--   SEC-008 HIGH      Ejecución de SQL dinámico
--   PERF-001 LOW      SELECT *
--   PERF-002 LOW      SELECT sin LIMIT (POTENCIAL)
--   PERF-004 MEDIUM   Comodín inicial en LIKE
--   CONV-001 LOW      Identificadores ambiguos
-- ============================================================

-- Elimina todas las filas. Sin cláusula WHERE.
DELETE FROM users;

-- Actualiza todas las filas. Sin cláusula WHERE.
UPDATE accounts
SET balance = balance - 100;

-- SELECT * más comodín inicial y sin LIMIT.
SELECT *
FROM products
WHERE name LIKE '%off%';

-- DDL destructivo sin ninguna restricción.
DROP TABLE legacy_reports;

-- SQL dinámico construido concatenando un valor externo.
EXECUTE 'DELETE FROM audit_log WHERE id = ' || audit_id;

-- Identificadores ambiguos de una sola letra.
SELECT x, y
FROM t;
