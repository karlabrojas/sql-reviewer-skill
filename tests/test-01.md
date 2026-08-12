# Test 01

## Entrada

La entrada es el contenido de `examples/valid.sql`:

```sql
SELECT
    id,
    customer_name,
    email
FROM customers
WHERE status = 'active'
ORDER BY customer_name
LIMIT 50;

UPDATE customers
SET last_login_at = CURRENT_TIMESTAMP
WHERE id = 42;

DELETE FROM sessions
WHERE expires_at < CURRENT_TIMESTAMP
  AND user_id = 7;

INSERT INTO orders (order_id, customer_id, created_at, total_amount)
VALUES (1001, 42, CURRENT_TIMESTAMP, 250.00);

CREATE TABLE order_items (
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL
);
```

## Comportamiento esperado

Happy path. La skill no debe generar problemas artificiales.

- **0 hallazgos CRITICAL, 0 HIGH, 0 MEDIUM.**
- Sin hallazgos de seguridad: todo `UPDATE` y `DELETE` tiene un `WHERE` restrictivo.
- Sin `SELECT *`, y todo `SELECT` que pueda devolver varias filas tiene un `LIMIT` explícito.
- Sin DDL destructivo.
- Sin concatenación de SQL dinámico.
- Los identificadores son descriptivos y con nombres consistentes, por lo que no hay hallazgos de convenciones.
- Como máximo observaciones **LOW / INFO de tipo potencial** que piden explícitamente metadata faltante, por ejemplo:

```text
[LOW] PERF-003 — POTENCIAL
Un índice puede ser beneficioso en customers(status);
deben comprobarse los índices existentes.
```

- El reporte debe indicar explícitamente que no se identificaron problemas cubiertos por las reglas actuales, sin afirmar que el SQL es completamente seguro o está libre de errores.

## Comportamiento real

Traza de reglas sobre la entrada:

| Sentencia | Reglas aplicadas | Resultado |
|-----------|------------------|-----------|
| `SELECT ... WHERE status = 'active' ... LIMIT 50` | PERF-001, PERF-002, PERF-003 | Sin PERF-001 (no hay `*`), sin PERF-002 (hay LIMIT). PERF-003 LOW / POTENCIAL porque no hay metadata de índices. |
| `UPDATE ... WHERE id = 42` | SEC-002, SEC-003 | Sin hallazgo. El WHERE es restrictivo. |
| `DELETE ... WHERE expires_at < ... AND user_id = 7` | SEC-001, SEC-003, SEC-004 | Sin hallazgo. El WHERE es restrictivo. |
| `INSERT INTO orders ...` | - | Sin hallazgo. |
| `CREATE TABLE order_items (...)` | CONV-001..CONV-008 | Sin hallazgo. Identificadores descriptivos en snake_case. |

## Pass / Fail

**PASS** — si la skill no produce hallazgos CRITICAL/HIGH/MEDIUM y solo reporta las observaciones LOW/INFO esperadas.

## Problema detectado

Ningún defecto de la skill. Esta prueba es la línea base para demostrar que la skill no inventa problemas sobre SQL correcto.

## Modificación realizada en la skill

Ninguna requerida.
