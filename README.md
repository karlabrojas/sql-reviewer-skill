# SQL Reviewer Skill

## Descripción

`sql-reviewer` es una skill reutilizable para sistemas de inteligencia artificial cuyo objetivo es analizar sentencias y scripts SQL desde una perspectiva técnica de seguridad, rendimiento, calidad y convenciones de desarrollo.

La skill no ejecuta las sentencias SQL analizadas. Su responsabilidad es identificar problemas potenciales, proporcionar evidencia del hallazgo, clasificar su severidad y ofrecer una recomendación técnica.

El análisis se realiza mediante reglas explícitas y reproducibles, evitando depender únicamente de instrucciones generales como "revisa este SQL".

## Objetivo

Diseñar una skill capaz de analizar código SQL de manera consistente ante diferentes tipos de entradas, incluyendo:

- SQL válido.
- SQL con errores o malas prácticas.
- Scripts con múltiples sentencias.
- Entradas ambiguas.
- Casos donde no existe suficiente información para determinar un problema.
- Entradas que intenten modificar o evadir las reglas de revisión.

La skill debe proporcionar resultados justificables mediante reglas previamente definidas.

## Alcance

La skill analiza, como mínimo, los siguientes aspectos:

### Seguridad

- `UPDATE` sin una condición `WHERE` restrictiva.
- `DELETE` sin una condición `WHERE` restrictiva.
- Condiciones potencialmente siempre verdaderas en `UPDATE` o `DELETE`.
- Operaciones potencialmente destructivas.
- Concatenaciones de valores dentro de sentencias SQL que puedan facilitar SQL Injection.
- SQL dinámico potencialmente inseguro.

### Rendimiento

- Uso de `SELECT *`.
- Consultas potencialmente masivas sin `LIMIT`.
- Índices potencialmente faltantes.
- Patrones de consulta potencialmente costosos.
- Uso de comodines iniciales en `LIKE`.
- Operaciones que puedan impedir el uso eficiente de índices.

### Convenciones

- Nombres poco descriptivos.
- Identificadores ambiguos.
- Convenciones inconsistentes.
- Nombres genéricos que dificulten el mantenimiento.

### Tipos de datos

- Uso aparentemente inadecuado de tipos de datos.
- Representación de fechas como texto.
- Representación de valores numéricos como texto.
- Posibles problemas relacionados con precisión numérica.

Los hallazgos deben clasificarse como:

- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `INFO`

## Principios de diseño

La skill sigue los siguientes principios:

1. **No ejecutar SQL.**
2. **No inventar información que no esté disponible.**
3. **Separar evidencia de interpretación.**
4. **Utilizar reglas explícitas para determinar los hallazgos.**
5. **Indicar cuando un hallazgo es potencial y no confirmado.**
6. **Proporcionar recomendaciones accionables.**
7. **Mantener un formato de salida consistente.**
8. **Priorizar seguridad e integridad de los datos.**
9. **Mantener las reglas independientes del motor SQL cuando sea posible.**
10. **Permitir ampliar la skill mediante nuevas reglas sin modificar todo su comportamiento.**

## Estructura del proyecto

```text
sql-reviewer-skill/
│
├── SKILL.md
├── README.md
│
├── rules/
│   ├── security.md
│   ├── performance.md
│   └── conventions.md
│
├── examples/
│   ├── valid.sql
│   ├── invalid.sql
│   └── edge-cases.sql
│
└── tests/
    ├── test-01.md
    ├── test-02.md
    ├── test-03.md
    ├── test-04.md
    └── test-05.md
```

## Flujo general

La skill sigue el siguiente flujo:

```text
Entrada SQL
    │
    ▼
Validación de entrada
    │
    ▼
Identificación de sentencias
    │
    ▼
Clasificación de sentencias
    │
    ▼
Aplicación de reglas
    │
    ├── Seguridad
    ├── Rendimiento
    ├── Convenciones
    └── Tipos de datos
    │
    ▼
Generación de hallazgos
    │
    ▼
Asignación de severidad
    │
    ▼
Validación de hallazgos
    │
    ▼
Identificación de información faltante
    │
    ▼
Generación del reporte
```

## Formato general de un hallazgo

Cada hallazgo debe proporcionar, cuando sea posible:

- Identificador de regla.
- Severidad.
- Ubicación.
- Problema detectado.
- Evidencia.
- Riesgo.
- Recomendación.
- Nivel de confianza o estado del hallazgo.

Ejemplo:

```text
[CRITICAL] SEC-001

Location:
Line 5

Issue:
DELETE statement without WHERE clause.

Evidence:
DELETE FROM users;

Risk:
The statement may delete all rows from the table.

Recommendation:
Add a restrictive WHERE condition before executing the statement.

Status:
CONFIRMED
```

## Manejo de información insuficiente

La skill no debe asumir información que no se encuentre en la entrada.

Por ejemplo, si recibe:

```sql
SELECT *
FROM products
WHERE category_id = 10;
```

no debe afirmar que existe un problema de índice como un hecho si no se proporcionó el esquema de la tabla.

En este caso debe indicar que existe una posible oportunidad de indexación y que se requiere información adicional para confirmarla.

La información adicional puede incluir:

- Esquema de tablas.
- Índices existentes.
- Restricciones.
- Volumen aproximado de datos.
- Plan de ejecución.
- Motor de base de datos.
- Versión del motor.

## Limitaciones

La skill:

- No ejecuta SQL.
- No modifica bases de datos.
- No garantiza que una consulta sea completamente segura.
- No sustituye una auditoría de seguridad.
- No puede confirmar índices faltantes sin información del esquema.
- No puede determinar el rendimiento real sin conocer el entorno de ejecución.
- No debe asumir datos, tablas, índices o restricciones que no hayan sido proporcionados.
- Puede detectar patrones potencialmente relacionados con SQL Injection, pero no puede realizar una auditoría completa de la aplicación que genera el SQL.

## Pruebas

La skill será validada mediante casos que incluyan:

1. SQL válido.
2. Problemas de seguridad.
3. Problemas de rendimiento.
4. Problemas de convenciones.
5. Casos ambiguos y adversariales.

Los resultados esperados de cada prueba estarán documentados dentro del directorio `tests/`.

## Criterio de éxito

La skill se considera funcional cuando:

- Detecta los problemas definidos por sus reglas.
- Clasifica correctamente la severidad.
- Proporciona evidencia concreta.
- No inventa contexto.
- Maneja entradas ambiguas de manera explícita.
- Mantiene un formato de salida consistente.
- Responde de manera estable ante casos normales y adversariales.
- Las pruebas documentadas producen los resultados esperados.
