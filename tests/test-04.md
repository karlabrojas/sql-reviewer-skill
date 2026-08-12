# Test 04

## Entrada

La entrada es el siguiente SQL **sin metadata de esquema, índices ni tamaños de tabla**:

```sql
SELECT id, name
FROM users
WHERE email = 'test@example.com';

SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id;

DELETE FROM users
WHERE status IS NOT NULL;
```

## Comportamiento esperado

Caso de información insuficiente. La skill debe reconocer cuándo no puede llegar a una conclusión y nunca debe inventar contexto de base de datos.

- La skill **no** debe afirmar que un índice definitivamente falta.
- La skill **no** debe afirmar que un tipo de columna es definitivamente incorrecto.
- La skill **no** debe afirmar que una consulta definitivamente causa un problema de rendimiento.

Hallazgos esperados:

| # | Regla | Severidad | Estado | Razonamiento |
|---|-------|-----------|--------|--------------|
| 1 | PERF-003 — Índice potencialmente faltante | LOW | POTENCIAL | Filtra por `users.email`, pero no hay metadata de índices. |
| 2 | PERF-007 — JOIN potencialmente costoso | INFO | POTENCIAL | Hay JOIN, pero no hay información de esquema/índices. |
| 3 | SEC-004 — WHERE amplio | HIGH | POTENCIAL | `WHERE status IS NOT NULL` no es demostrablemente restrictivo; podría afectar a una gran cantidad de filas. |

El reporte debe incluir una sección de **Lagos de información** que liste la metadata que mejoraría el análisis:

- Esquemas de tablas y definiciones de columnas.
- Índices existentes.
- Restricciones.
- Tamaños aproximados de las tablas.
- Motor y versión de base de datos.
- Plan de ejecución de consultas.

Para cada hallazgo no confirmado, el estado debe ser `POTENCIAL` o `INSUFFICIENT_CONTEXT` (CONTEXTO_INSUFICIENTE), nunca `CONFIRMADO`.

## Comportamiento real

Traza de reglas por cada sentencia:

1. `SELECT id, name FROM users WHERE email = 'test@example.com';` → PERF-003: hay una operación de filtrado; metadata de índices no disponible → LOW, POTENCIAL. Redacción: "Un índice puede ser beneficioso; deben comprobarse los índices existentes."
2. `SELECT u.name, o.total FROM users u JOIN orders o ON u.id = o.user_id;` → PERF-007: hay JOIN; información de esquema/índices no disponible → INFO, POTENCIAL.
3. `DELETE FROM users WHERE status IS NOT NULL;` → SEC-004: el WHERE existe pero no es demostrablemente restrictivo → HIGH, POTENCIAL. La skill indica que no puede determinar la cantidad real de filas afectadas sin datos de la base de datos.

La skill no fabrica índices, tamaños de tabla ni planes de ejecución.

## Pass / Fail

**PASS** — si la skill devuelve estados `POTENCIAL`/`INSUFFICIENT_CONTEXT`, lista la metadata faltante y nunca afirma que un índice definitivamente falta ni que las consultas son definitivamente lentas.

## Problema detectado

Ningún defecto de la skill. Esta prueba protege contra que la skill invente información de esquema para producir falsas confirmaciones.

## Modificación realizada en la skill

Ninguna requerida.
