# SQL Reviewer — Performance Rules

## Purpose

This document defines the performance rules used by the `sql-reviewer` skill.

These rules identify SQL patterns that may result in unnecessary data retrieval, inefficient execution, excessive resource consumption, or poor scalability.

Performance findings must be conservative.

The skill must not claim that a query is slow or that an index is missing unless the available evidence supports that conclusion.

# PERF-001 — SELECT \*

## Description

Using `SELECT *` retrieves all columns from the selected table or tables instead of explicitly requesting only the required columns.

This may result in unnecessary data retrieval and can make queries less resilient to schema changes.

## Detection condition

```text id="o8z5bp"
IF statement.type = SELECT
AND projection contains *
THEN
    finding = PERF-001
    severity = LOW
    status = CONFIRMED
```

## Example

```sql id="r1j0gs"
SELECT *
FROM users;
```

## Expected finding

```text id="w0k3yn"
Rule: PERF-001
Severity: LOW
Status: CONFIRMED
```

## Evidence

The evidence must identify the use of `*` in the `SELECT` projection.

## Risk

Potential consequences include:

- Retrieving unnecessary columns.
- Increased network traffic.
- Increased memory usage.
- Reduced query clarity.
- Increased coupling between the query and the table schema.

The actual performance impact depends on the number and size of the columns and rows returned.

## Recommendation

Explicitly select only the columns required by the application.

Example:

```sql id="x7az4c"
SELECT id, name, email
FROM users;
```

## Exceptions

`SELECT *` must not automatically be considered a severe performance problem.

The rule identifies the pattern, but the actual impact depends on the query context.

# PERF-002 — Potentially large result set without LIMIT

## Description

A `SELECT` query that may return a large number of rows without a limiting mechanism can produce excessive result sets.

## Detection condition

```text id="v8qvps"
IF statement.type = SELECT
AND query can reasonably return multiple rows
AND LIMIT is absent
AND no other explicit row-limiting mechanism is present
THEN
    finding = PERF-002
    severity = LOW
    status = POTENTIAL
```

## Example

```sql id="m3b6mi"
SELECT id, name, email
FROM users;
```

## Expected finding

```text id="3n0q4b"
Rule: PERF-002
Severity: LOW
Status: POTENTIAL
```

## Risk

The query may retrieve more rows than necessary, increasing:

- Database workload.
- Memory consumption.
- Network traffic.
- Application processing time.

## Recommendation

If the use case does not require the complete result set, use an appropriate limiting or pagination strategy.

Example:

```sql id="f0q3se"
SELECT id, name, email
FROM users
LIMIT 100;
```

For APIs or user-facing applications, cursor-based or offset-based pagination may be more appropriate than an arbitrary fixed limit.

## Limitations

The skill must not assume that every query requires `LIMIT`.

For example, reporting queries, aggregation queries, exports, or administrative operations may intentionally require the complete result set.

Therefore this rule is normally `POTENTIAL`.

# PERF-003 — Potentially missing index

## Description

A query may benefit from an index on columns frequently used for filtering, joining, grouping, or ordering.

The skill must only confirm the existence or absence of an index when schema/index metadata is provided.

## Detection condition

```text id="f7d13v"
IF statement contains a filtering, joining, grouping,
or ordering operation on a column
AND index metadata is available
AND no suitable index exists
THEN
    finding = PERF-003
    severity = MEDIUM
    status = CONFIRMED
```

If index metadata is unavailable:

```text id="k1ez3j"
IF statement contains a filtering, joining, grouping,
or ordering operation
AND index metadata is unavailable
THEN
    finding = PERF-003
    severity = LOW
    status = POTENTIAL
```

## Example

SQL:

```sql id="i8l4z1"
SELECT id, name
FROM users
WHERE email = 'test@example.com';
```

If the provided schema shows:

```text id="yps1jj"
Indexes:
PRIMARY KEY (id)
```

and no index exists on `email`, the rule may be confirmed.

## Risk

A missing suitable index may result in inefficient scans as the table grows.

## Recommendation

Evaluate whether an index should be created based on:

- Query frequency.
- Table size.
- Selectivity.
- Read/write workload.
- Existing indexes.
- Query execution plan.

Example:

```sql id="d9cltd"
CREATE INDEX idx_users_email
ON users(email);
```

## Limitations

The skill must never state:

> "The index is missing."

based only on the SQL.

Without index metadata, the correct wording is:

> "An index may be beneficial; existing indexes should be checked."

The skill must also avoid recommending redundant indexes without considering existing indexes.

# PERF-004 — Leading wildcard in LIKE

## Description

A `LIKE` condition beginning with `%` may prevent efficient use of a conventional B-tree index for the searched column.

## Detection condition

```text id="z6y1ju"
IF statement contains LIKE
AND search pattern begins with %
THEN
    finding = PERF-004
    severity = MEDIUM
    status = CONFIRMED
```

## Example

```sql id="k7h5ts"
SELECT id, name
FROM products
WHERE name LIKE '%pan%';
```

## Risk

The database may be unable to efficiently use a standard B-tree index for the beginning of the search pattern.

For large datasets this can result in expensive scans.

## Recommendation

Consider alternatives based on the database engine and search requirements, such as:

- Prefix searches.
- Full-text search.
- Specialized indexes.
- Search engines.
- Database-specific indexing strategies.

Example of a prefix search:

```sql id="w6f4mj"
SELECT id, name
FROM products
WHERE name LIKE 'pan%';
```

## Limitations

The actual execution strategy depends on:

- Database engine.
- Index type.
- Query planner.
- Data distribution.
- Available extensions or search mechanisms.

The skill must not claim that the query definitely performs a full table scan unless execution-plan information is provided.

# PERF-005 — Function applied to filtered column

## Description

Applying a function to a column used in a filtering condition may prevent efficient use of a conventional index on that column.

## Detection condition

```text id="w9c2h6"
IF WHERE clause applies a function or expression
directly to a column
AND the expression may prevent normal index usage
THEN
    finding = PERF-005
    severity = MEDIUM
    status = POTENTIAL
```

## Example

```sql id="1v9l7e"
SELECT id, name
FROM users
WHERE LOWER(email) = 'user@example.com';
```

## Risk

Depending on the database engine and available indexes, the expression may prevent the database from using a normal index on `email`.

## Recommendation

Consider:

- Functional indexes.
- Expression indexes.
- Normalizing data before storage.
- Alternative query formulations.

Example:

```sql id="8yblq3"
CREATE INDEX idx_users_lower_email
ON users(LOWER(email));
```

## Limitations

The skill must not claim that an index cannot be used.

The actual behavior depends on the database engine, available indexes, query planner, and execution plan.

# PERF-006 — Potentially expensive ORDER BY

## Description

Sorting a large result set may require significant CPU and memory resources, especially when no suitable index supports the ordering operation.

## Detection condition

```text id="73n6s2"
IF SELECT statement contains ORDER BY
AND available SQL indicates a potentially large result set
AND no LIMIT or equivalent restriction is present
THEN
    finding = PERF-006
    severity = LOW
    status = POTENTIAL
```

## Example

```sql id="jsf7n5"
SELECT id, name, created_at
FROM users
ORDER BY created_at DESC;
```

## Risk

Large sorts may consume additional CPU and memory resources.

## Recommendation

Evaluate:

- Whether the complete result set is required.
- Whether pagination is appropriate.
- Whether an index supports the ordering.
- Whether the query can reduce the number of rows before sorting.

## Limitations

The skill cannot determine the actual cost of the sort without information about:

- Number of rows.
- Existing indexes.
- Database engine.
- Query plan.

# PERF-007 — Potentially expensive JOIN

## Description

Joins involving large datasets may become expensive when appropriate filtering or indexing is absent.

## Detection condition

```text id="94f7q8"
IF SELECT contains JOIN
AND join condition involves columns
AND schema/index information is available
AND suitable indexes are absent
THEN
    finding = PERF-007
    severity = MEDIUM
    status = CONFIRMED
```

If index metadata is unavailable:

```text id="nd7kvi"
IF SELECT contains JOIN
AND schema/index information is unavailable
THEN
    finding = PERF-007
    severity = INFO
    status = POTENTIAL
```

## Example

```sql id="x3hjv8"
SELECT
    users.name,
    orders.total
FROM users
JOIN orders
    ON users.id = orders.user_id;
```

## Risk

Large joins without appropriate indexing may require expensive scans or join operations.

## Recommendation

Verify:

- Join columns.
- Existing indexes.
- Table sizes.
- Query execution plan.

Consider appropriate indexes on frequently joined columns when justified by workload.

## Limitations

The presence of a `JOIN` alone is not a performance defect.

The skill must not report a confirmed performance problem without sufficient evidence.

# PERF-008 — Repeated retrieval of unnecessary columns

## Description

A query may retrieve columns that are not needed for the apparent purpose of the query.

This rule should be applied conservatively because the skill may not know how the result is consumed.

## Detection condition

```text id="clqk7y"
IF SELECT explicitly retrieves many columns
AND available context indicates only a subset is required
THEN
    finding = PERF-008
    severity = LOW
    status = POTENTIAL
```

## Example

If the user explicitly states:

```text id="8g7n5q"
"The API only needs the user's id and name."
```

but the query is:

```sql id="5v9n1z"
SELECT id, name, email, phone, address, created_at, updated_at
FROM users
WHERE id = 10;
```

the rule may be applied.

## Risk

Retrieving unnecessary columns may increase:

- Network usage.
- Memory consumption.
- Serialization cost.
- Application processing.

## Recommendation

Return only the columns required by the consuming operation.

## Limitations

The skill must not infer application requirements that were not provided.

Without application context, this rule should normally not be reported.

# PERF-009 — Potentially inefficient OFFSET pagination

## Description

Large `OFFSET` values can require the database to process and discard many rows before returning the requested page.

## Detection condition

```text id="f3c2c1"
IF SELECT contains OFFSET
AND offset value is explicitly large
THEN
    finding = PERF-009
    severity = LOW
    status = POTENTIAL
```

## Example

```sql id="h8v2w4"
SELECT id, name
FROM products
ORDER BY id
LIMIT 50
OFFSET 100000;
```

## Risk

Large offsets may result in unnecessary database work.

## Recommendation

For large datasets, consider keyset or cursor-based pagination.

Example concept:

```sql id="y3z1x0"
SELECT id, name
FROM products
WHERE id > 100000
ORDER BY id
LIMIT 50;
```

## Limitations

The actual performance depends on:

- Database engine.
- Indexes.
- Query plan.
- Ordering columns.
- Table size.

# PERF-010 — Unnecessary DISTINCT

## Description

`DISTINCT` may require additional processing to eliminate duplicate rows.

It should only be flagged when the available SQL provides evidence that duplicate elimination may be unnecessary.

## Detection condition

```text id="c9k6a3"
IF SELECT contains DISTINCT
AND available context indicates duplicate elimination
is unnecessary
THEN
    finding = PERF-010
    severity = LOW
    status = POTENTIAL
```

## Example

If the schema guarantees uniqueness:

```sql id="u2x9qk"
SELECT DISTINCT id
FROM users;
```

and `id` is a primary key, the `DISTINCT` operation is potentially redundant.

## Risk

Unnecessary duplicate elimination may introduce additional sorting or hashing work.

## Recommendation

Remove `DISTINCT` when uniqueness is already guaranteed by the schema or query logic.

## Limitations

The skill must not assume that `DISTINCT` is unnecessary without evidence of uniqueness.

# Performance Review Principles

The skill must follow these principles when applying performance rules:

1. `SELECT *` is a confirmed pattern but not necessarily a confirmed performance problem.
2. Missing `LIMIT` is generally a potential issue, not an automatic defect.
3. Missing indexes cannot be confirmed without index metadata.
4. The presence of a `JOIN` is not itself a performance problem.
5. The presence of `ORDER BY` is not itself a performance problem.
6. A leading `%` in `LIKE` is a confirmed pattern that may prevent efficient use of conventional B-tree indexes.
7. Functions applied to filtered columns should generally be reported as potential optimization opportunities unless execution information proves the impact.
8. The skill must distinguish query-pattern detection from actual runtime performance.
9. Query execution plans provide stronger evidence than static SQL alone.
10. The skill must never invent table sizes, indexes, workload characteristics, or execution times.
11. Recommendations should consider the database engine when that information is available.
12. Performance findings should prioritize practical impact rather than reporting every stylistic optimization.
13. When insufficient context exists, the skill must clearly identify what information is required for confirmation.
