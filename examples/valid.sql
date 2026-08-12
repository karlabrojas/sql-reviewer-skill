-- ============================================================
-- examples/valid.sql
--
-- Happy path: SQL que cumple las reglas de la skill.
-- Resultado esperado: sin hallazgos CRITICAL / HIGH / MEDIUM.
-- Como máximo observaciones LOW / INFO de tipo potencial que
-- requieran metadata adicional (p. ej. PERF-003 sin info de índices).
-- ============================================================

-- SELECT bien formado: columnas explícitas, filtro restrictivo,
-- orden y un límite de filas explícito.
SELECT
    id,
    customer_name,
    email
FROM customers
WHERE status = 'active'
ORDER BY customer_name
LIMIT 50;

-- UPDATE restringido a un único registro mediante clave primaria.
UPDATE customers
SET last_login_at = CURRENT_TIMESTAMP
WHERE id = 42;

-- DELETE restringido a un conjunto reducido y claramente intencionado.
DELETE FROM sessions
WHERE expires_at < CURRENT_TIMESTAMP
  AND user_id = 7;

-- INSERT con columnas explícitas y valores estilo parametrizado.
INSERT INTO orders (order_id, customer_id, created_at, total_amount)
VALUES (1001, 42, CURRENT_TIMESTAMP, 250.00);

-- DDL con identificadores descriptivos y snake_case consistente.
CREATE TABLE order_items (
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL
);
