# SQL Reviewer — Security Rules

## Purpose

This document defines the security rules used by the `sql-reviewer` skill.

These rules identify SQL statements that may cause data loss, unauthorized modification, or SQL Injection vulnerabilities.

Each rule defines an explicit detection condition, severity, evidence requirements, recommendation, and limitations.

The skill must only report a confirmed security finding when the SQL itself provides sufficient evidence.

# SEC-001 — DELETE without WHERE

## Description

A `DELETE` statement without a `WHERE` clause can remove all rows from the target table.

## Detection condition

```text
IF statement.type = DELETE
AND WHERE clause is absent
THEN
    finding = SEC-001
    severity = CRITICAL
    status = CONFIRMED
```

## Example

```sql
DELETE FROM users;
```

## Expected finding

```text
Rule: SEC-001
Severity: CRITICAL
Status: CONFIRMED
```

## Evidence

The evidence must include the `DELETE` statement showing that no `WHERE` clause is present.

## Risk

The statement may delete every row from the target table.

## Recommendation

Add a restrictive `WHERE` condition that identifies the intended rows.

Example:

```sql
DELETE FROM users
WHERE id = 10;
```

## Execution policy

The skill must not recommend executing a `DELETE` statement without a `WHERE` clause.

## Exceptions

None.

A `DELETE` without `WHERE` is always considered a critical finding by this rule.

# SEC-002 — UPDATE without WHERE

## Description

An `UPDATE` statement without a `WHERE` clause may modify every row in the target table.

## Detection condition

```text
IF statement.type = UPDATE
AND WHERE clause is absent
THEN
    finding = SEC-002
    severity = CRITICAL
    status = CONFIRMED
```

## Example

```sql
UPDATE users
SET active = false;
```

## Expected finding

```text
Rule: SEC-002
Severity: CRITICAL
Status: CONFIRMED
```

## Evidence

The evidence must include the `UPDATE` statement showing the absence of a `WHERE` clause.

## Risk

The statement may modify every row in the target table.

## Recommendation

Add a restrictive `WHERE` condition identifying the intended records.

Example:

```sql
UPDATE users
SET active = false
WHERE id = 10;
```

## Execution policy

The skill must not recommend executing an `UPDATE` without `WHERE` unless the user explicitly provides sufficient context demonstrating that modifying every row is intentional and safe.

Even when the operation is intentional, the absence of `WHERE` must still be reported as a security/data-integrity concern.

## Exceptions

No automatic exceptions.

# SEC-003 — Non-restrictive WHERE condition

## Description

An `UPDATE` or `DELETE` statement may contain a `WHERE` clause that is technically present but effectively matches every row.

The presence of `WHERE` alone does not guarantee that an operation is safe.

## Detection condition

```text
IF statement.type IN [UPDATE, DELETE]
AND WHERE condition is always true
THEN
    finding = SEC-003
    severity = CRITICAL
    status = CONFIRMED
```

## Examples

```sql
DELETE FROM users
WHERE 1 = 1;
```

```sql
UPDATE users
SET active = false
WHERE TRUE;
```

## Risk

The statement can affect all rows despite containing a `WHERE` clause.

## Recommendation

Replace the non-restrictive condition with a condition that identifies the intended records.

Example:

```sql
DELETE FROM users
WHERE id = 10;
```

## Exceptions

None for conditions that are deterministically always true.

# SEC-004 — Potentially broad WHERE condition

## Description

An `UPDATE` or `DELETE` statement may contain a `WHERE` clause that is not provably always true but is broad enough to potentially affect a large number of records.

This rule must be applied conservatively.

## Detection condition

```text
IF statement.type IN [UPDATE, DELETE]
AND WHERE clause exists
AND condition is not provably restrictive
AND available SQL indicates potentially broad row matching
THEN
    finding = SEC-004
    severity = HIGH or MEDIUM
    status = POTENTIAL
```

## Examples

```sql
DELETE FROM users
WHERE status IS NOT NULL;
```

```sql
UPDATE products
SET active = false
WHERE category_id IS NOT NULL;
```

## Risk

The operation may affect significantly more rows than intended.

## Recommendation

Use a condition that explicitly identifies the intended records.

When possible, verify the number of affected rows before executing the statement.

## Limitations

The skill must not claim that the statement will affect all rows unless the SQL proves that condition.

The actual number of affected rows cannot be determined without database data.

# SEC-005 — Destructive DDL operation

## Description

Certain DDL statements can permanently remove database objects or data.

## Detection condition

```text
IF statement.type IN [DROP, TRUNCATE]
THEN
    finding = SEC-005
    severity = CRITICAL
    status = CONFIRMED
```

## Examples

```sql
DROP TABLE users;
```

```sql
DROP DATABASE production;
```

```sql
TRUNCATE TABLE orders;
```

## Risk

The operation may permanently remove data or database structures.

## Recommendation

Verify the target object and intended impact before execution.

For destructive operations involving important data, recommend using backups, transactions where supported, or an appropriate recovery strategy.

## Execution policy

The skill must not recommend executing a destructive DDL operation solely because it is syntactically valid.

## Exceptions

None for identifying the operation as destructive.

The exact recoverability may depend on the database engine and execution context.

# SEC-006 — Potentially destructive ALTER operation

## Description

Some `ALTER TABLE` operations may remove columns, constraints, or other database structures.

## Detection condition

```text
IF statement.type = ALTER
AND operation removes or destructively changes database structure
THEN
    finding = SEC-006
    severity = HIGH
    status = CONFIRMED
```

## Examples

```sql
ALTER TABLE users
DROP COLUMN email;
```

```sql
ALTER TABLE orders
DROP CONSTRAINT orders_customer_id_fkey;
```

## Risk

Structural changes may result in data loss, broken dependencies, or application failures.

## Recommendation

Verify dependencies and backups before applying the operation.

Use a migration strategy appropriate for the production environment.

## Limitations

The skill cannot determine the complete dependency graph unless the database schema is provided.

# SEC-007 — Evident SQL string concatenation

## Description

Building SQL statements by concatenating external or dynamic values into SQL text can facilitate SQL Injection.

The rule focuses on evidence that SQL syntax and dynamic values are being combined into executable SQL text.

## Detection condition

```text
IF SQL construction combines SQL syntax
AND an external or dynamic value
through string concatenation
THEN
    finding = SEC-007
    severity = HIGH
    status = CONFIRMED or POTENTIAL
```

## Examples

Application-level example:

```text
"SELECT * FROM users WHERE id = " + userId
```

SQL dynamic execution example:

```sql
EXECUTE 'SELECT * FROM users WHERE id = ' || user_id;
```

## Risk

An attacker may manipulate the dynamic value and alter the intended SQL statement.

## Recommendation

Use parameterized queries, prepared statements, or the parameterization mechanism provided by the database driver or framework.

## Important distinction

The skill must not classify normal SQL string functions as SQL Injection.

For example:

```sql
SELECT CONCAT(first_name, ' ', last_name)
FROM users;
```

must not trigger SEC-007 by itself.

## Limitations

The skill can identify evident unsafe construction patterns but cannot perform a complete application-level SQL Injection assessment without seeing how input values are obtained and passed to the database.

# SEC-008 — Dynamic SQL execution

## Description

Dynamic SQL execution can introduce security risks when SQL statements are constructed from untrusted or insufficiently validated input.

## Detection condition

```text
IF statement executes dynamically constructed SQL
AND the SQL text contains dynamic values
THEN
    finding = SEC-008
    severity = HIGH
    status = POTENTIAL
```

## Examples

```sql
EXECUTE 'SELECT * FROM users WHERE name = ''' || user_name || '''';
```

## Risk

Dynamically constructed SQL may allow attackers to inject SQL syntax.

## Recommendation

Prefer parameterized dynamic SQL mechanisms provided by the database engine.

Validate and constrain dynamic identifiers when parameterization is not possible.

## Limitations

The skill must not automatically classify every use of dynamic SQL as vulnerable.

The finding is potential unless the SQL itself demonstrates unsafe handling of external input.

# SEC-009 — Dangerous privilege modification

## Description

Statements that grant or revoke database privileges can have significant security implications.

## Detection condition

```text
IF statement.type IN [GRANT, REVOKE]
AND operation grants or removes significant database privileges
THEN
    finding = SEC-009
    severity = HIGH
    status = CONFIRMED
```

## Examples

```sql
GRANT ALL PRIVILEGES ON DATABASE production TO public;
```

```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO user1;
```

## Risk

Excessive permissions may allow unauthorized access, modification, or deletion of data.

## Recommendation

Apply the principle of least privilege and grant only the permissions required for the intended role.

## Limitations

The actual security impact depends on the database roles, ownership, existing permissions, and environment.

# SEC-010 — Sensitive value exposed in SQL

## Description

SQL scripts may contain credentials, secrets, tokens, or other sensitive values directly in SQL statements.

## Detection condition

```text
IF SQL contains an apparent credential,
secret, password, API key, token,
or other sensitive authentication value
THEN
    finding = SEC-010
    severity = HIGH
    status = POTENTIAL or CONFIRMED
```

## Examples

```sql
INSERT INTO users(username, password)
VALUES ('admin', 'MySecretPassword');
```

## Risk

Secrets stored directly in source code or SQL scripts may be exposed through repositories, logs, backups, or development artifacts.

## Recommendation

Do not hard-code secrets.

Use secure secret management and appropriate password hashing mechanisms.

## Limitations

The skill cannot determine whether a string is truly a secret unless the context makes this evident.

Generic strings must not automatically be classified as credentials.

# Security Rule Priority

When multiple security rules apply to the same statement, report all relevant findings unless one finding completely subsumes another.

The following priority should be used for ordering:

1. CRITICAL
2. HIGH
3. MEDIUM
4. LOW
5. INFO

Example:

```sql
DELETE FROM users;
```

should primarily report:

```text
SEC-001
CRITICAL
```

rather than generating unrelated low-severity observations that distract from the immediate data-loss risk.

# Security Review Principles

The skill must follow these principles when applying security rules:

1. Absence of `WHERE` in `UPDATE` or `DELETE` is a confirmed critical finding.
2. Presence of `WHERE` does not automatically make an operation safe.
3. Destructive operations must be explicitly identified.
4. SQL Injection findings require evidence of dynamic SQL construction.
5. Normal string functions are not automatically SQL Injection.
6. Potential issues must be clearly marked as potential.
7. Database context must never be invented.
8. Recommendations must not imply that dangerous SQL is safe merely because it is syntactically valid.
9. The skill must never execute the reviewed SQL.
10. Security findings take precedence over stylistic observations when prioritizing the report.
