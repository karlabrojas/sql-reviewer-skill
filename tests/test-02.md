# Test 02

## Entrada

La entrada es el contenido de `examples/invalid.sql`:

```sql
DELETE FROM users;

UPDATE accounts
SET balance = balance - 100;

SELECT *
FROM products
WHERE name LIKE '%off%';

DROP TABLE legacy_reports;

EXECUTE 'DELETE FROM audit_log WHERE id = ' || audit_id;

SELECT x, y
FROM t;
```

## Comportamiento esperado

La skill debe detectar todas las violaciones claras y asignar la severidad definida por las reglas. Los hallazgos de seguridad tienen prioridad sobre los de estilo.

| # | Regla | Severidad | Estado | Ubicación |
|---|-------|-----------|--------|-----------|
| 1 | SEC-001 — DELETE sin WHERE | CRITICAL | CONFIRMADO | `DELETE FROM users;` |
| 2 | SEC-002 — UPDATE sin WHERE | CRITICAL | CONFIRMADO | `UPDATE accounts SET balance = balance - 100;` |
| 3 | SEC-005 — DDL destructivo | CRITICAL | CONFIRMADO | `DROP TABLE legacy_reports;` |
| 4 | SEC-007 — Concatenación evidente de cadenas SQL | HIGH | CONFIRMADO | `EXECUTE '...' \|\| audit_id;` |
| 5 | SEC-008 — Ejecución de SQL dinámico | HIGH | POTENCIAL | `EXECUTE '...' \|\| audit_id;` |
| 6 | PERF-004 — Comodín inicial en LIKE | MEDIUM | CONFIRMADO | `WHERE name LIKE '%off%'` |
| 7 | PERF-001 — SELECT * | LOW | CONFIRMADO | `SELECT * FROM products` |
| 8 | PERF-002 — Sin LIMIT | LOW | POTENCIAL | `SELECT * FROM products` |
| 9 | CONV-001 — Identificadores ambiguos | LOW | CONFIRMADO | `SELECT x, y FROM t;` |

La línea de resumen debe ser: `CRITICAL: 3, HIGH: 2, MEDIUM: 1, LOW: 3, INFO: 0`.

Para cada hallazgo destructivo CRITICAL, la skill debe indicar explícitamente que no se debe recomendar la ejecución hasta que el problema se corrija o se verifique intencionadamente.

## Comportamiento real

Traza de reglas por cada sentencia:

1. `DELETE FROM users;` → SEC-001: tipo de sentencia DELETE, sin WHERE → CRITICAL, CONFIRMADO.
2. `UPDATE accounts SET balance = balance - 100;` → SEC-002: tipo de sentencia UPDATE, sin WHERE → CRITICAL, CONFIRMADO.
3. `SELECT * FROM products WHERE name LIKE '%off%';` → PERF-001 (proyección `*`) LOW CONFIRMADO; PERF-004 (el patrón comienza con `%`) MEDIUM CONFIRMADO; PERF-002 (sin LIMIT) LOW POTENCIAL.
4. `DROP TABLE legacy_reports;` → SEC-005: DDL destructivo → CRITICAL, CONFIRMADO.
5. `EXECUTE 'DELETE FROM audit_log WHERE id = ' || audit_id;` → SEC-007 (SQL combinado con un valor dinámico mediante `||`) HIGH CONFIRMADO; SEC-008 (SQL construido dinámicamente) HIGH POTENCIAL.
6. `SELECT x, y FROM t;` → CONV-001: columnas de una sola letra sin contexto → LOW, CONFIRMADO.

## Pass / Fail

**PASS** — si se producen los nueve hallazgos con la regla, severidad y estado exactos de la tabla esperada, y los contadores del resumen coinciden.

## Problema detectado

Ningún defecto de la skill. Esta prueba es la línea base para demostrar que la skill detecta múltiples violaciones claramente evidenciadas y prioriza los hallazgos de seguridad.

## Modificación realizada en la skill

Ninguna requerida.
