# Test 03

## Entrada

La entrada es el contenido de `examples/edge-cases.sql`:

```sql
DELETE FROM TA_USERS
WHERE 1 = 1;

UPDATE TA_USERS
SET FCROLE = 'ADMIN'
WHERE TRUE;

SELECT * FROM TA_USERS
LIMIT 1000000000;

UPDATE TA_USERS
SET FCROLE = 'ADMIN'
WHERE FCEMAIL LIKE '%';
```

## Comportamiento esperado

Caso límite: las sentencias parecen seguras superficialmente porque contienen un `WHERE` o un `LIMIT`. La skill debe razonar sobre la intención y el impacto, no solo sobre la presencia de palabras clave.

| # | Regla | Severidad | Estado | Razonamiento |
|---|-------|-----------|--------|--------------|
| 1 | SEC-003 — WHERE no restrictivo | CRITICAL | CONFIRMADO | `WHERE 1 = 1` siempre es verdadero; elimina todas las filas. |
| 2 | SEC-003 — WHERE no restrictivo | CRITICAL | CONFIRMADO | `WHERE TRUE` siempre es verdadero; actualiza todas las filas. |
| 3 | PERF-001 — SELECT * | LOW | CONFIRMADO | La proyección contiene `*`. |
| 4 | PERF-002 — LIMIT efectivamente ilimitado | LOW | POTENCIAL | `LIMIT 1000000000` anula el propósito de un límite. |
| 5 | SEC-004 — WHERE amplio | HIGH | POTENCIAL | `WHERE FCEMAIL LIKE '%'` coincide con todas las filas no nulas; equivalente a actualizar toda la columna. |

La skill debe indicar explícitamente que las sentencias destructivas CRITICAL no deben ejecutarse hasta que el problema se corrija o se verifique intencionadamente.

La skill no debe inventar el esquema de la tabla `TA_USERS`; los hallazgos de LIKE/WHERE amplio permanecen como `POTENCIAL`.

## Comportamiento real

Traza de reglas por cada sentencia:

1. `DELETE FROM TA_USERS WHERE 1 = 1;` → SEC-003: el WHERE existe pero es determinísticamente siempre verdadero → CRITICAL, CONFIRMADO.
2. `UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE TRUE;` → SEC-003 → CRITICAL, CONFIRMADO.
3. `SELECT * FROM TA_USERS LIMIT 1000000000;` → PERF-001 (proyección `*`) LOW CONFIRMADO. La condición de detección de PERF-002 verifica "ausencia de LIMIT"; aquí el LIMIT existe técnicamente pero el valor es efectivamente ilimitado, por lo que el hallazgo se emite como LOW POTENCIAL con razonamiento explícito sobre la intención.
4. `UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';` → SEC-004: la condición no es demostrablemente restrictiva y puede coincidir con todas las filas no nulas → HIGH, POTENCIAL.

## Pass / Fail

**PASS** — si la skill reporta SEC-003 para los casos `1 = 1` y `TRUE`, marca el LIMIT absurdo en lugar de aceptarlo, reporta SEC-004 para el UPDATE con `LIKE '%'` y mantiene como POTENCIAL los hallazgos que dependen del esquema.

## Problema detectado

Ningún defecto de la skill en esta ejecución. Esta prueba protege contra una implementación ingenua que solo comprueba la presencia de las palabras clave `WHERE` / `LIMIT`.

## Modificación realizada en la skill

Ninguna requerida.
