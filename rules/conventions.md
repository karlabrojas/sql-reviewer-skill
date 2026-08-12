# SQL Reviewer — Convention Rules

## Purpose

The Convention Rules evaluate SQL code from a readability, consistency, naming, and maintainability perspective.

These rules identify naming patterns and stylistic inconsistencies that may make SQL code difficult to understand, maintain, review, or maintain over time.

Convention findings do not necessarily indicate that the SQL is invalid or functionally incorrect. Unless explicitly stated otherwise, convention findings should be treated as maintainability recommendations rather than functional errors.

The rules must evaluate only information available in the SQL input and must not assume an organization's naming standard unless that standard is explicitly provided.

# CONV-001 — Ambiguous Identifier Naming

## Description

Identifiers such as tables, columns, aliases, constraints, or other database objects may be difficult to understand when their names do not clearly communicate their purpose.

Ambiguous names can reduce readability and make SQL maintenance more difficult.

Examples include names such as:

```sql
SELECT x, y, z
FROM t;
```

or:

```sql
SELECT data, value, info
FROM products;
```

when the SQL provides no additional context that explains their meaning.

## Detection condition

The rule should be triggered when an identifier appears excessively ambiguous or provides insufficient semantic information about the represented data.

Potential indicators include:

Single-letter column names.
Extremely short identifiers without an obvious conventional meaning.
Generic abbreviations.
Names such as data, value, info, item, or object when their meaning cannot be inferred.
Identifiers whose meaning cannot reasonably be determined from the surrounding SQL.

The rule should not assume that every short identifier is incorrect.

## Examples

```sql
SELECT a, b, c
FROM customers;
SELECT data, value
FROM orders;
```

## Risk

Ambiguous identifiers can:

- Reduce code readability.
- Increase the time required to understand queries.
- Make maintenance more difficult.
- Increase the probability of selecting or modifying the wrong field.
- Make SQL reviews more difficult.

## Recommendation

Use descriptive identifiers that communicate the purpose or meaning of the data.

For example:

```sql
SELECT customer_id, customer_name, email
FROM customers;
```

instead of:

```sql
SELECT a, b, c
FROM customers;
```

## Limitations

The rule cannot determine the business meaning of an identifier unless sufficient context is available.

An identifier may be intentionally abbreviated because of an established organizational or database naming convention.

# CONV-002 — Generic Identifier Naming

## Description

Generic names may technically be valid but provide little information about the data they represent.

Names such as id, name, type, status, or value may become ambiguous when used across multiple entities or complex queries.

## Detection condition

The rule should be triggered when an identifier uses an excessively generic name and the surrounding SQL provides insufficient context to determine its specific meaning.

Examples include:

```sql
SELECT id, name, status
FROM customers;
```

and:

```sql
SELECT value, type
FROM transactions;
```

The rule should consider the surrounding table or query context before reporting the finding.

For example:

```sql
SELECT customer_id
FROM customers;
```

should not be reported merely because customer_id contains id.

## Examples

Potentially ambiguous:

```sql
SELECT id, name
FROM orders;
```

More descriptive:

```sql
SELECT order_id, customer_name
FROM orders;
```

## Risk

Generic identifiers may:

- Create ambiguity in complex queries.
- Make joins harder to understand.
- Reduce readability.
- Make generated SQL or application code harder to maintain.

## Recommendation

Prefer identifiers that describe the entity or purpose of the value.

For example:

id → customer_id
name → customer_name
status → order_status
type → payment_type

## Limitations

Generic identifiers are not inherently incorrect.

The rule should not report an identifier solely because it is short or common.

# CONV-003 — Inconsistent Naming Convention

## Description

A SQL script may use multiple naming conventions for identifiers without an apparent reason.

For example, a script may mix:

customer_id
customerName
CustomerAddress
customer-address

This can make the schema or SQL code inconsistent and harder to maintain.

## Detection condition

The rule should be triggered when multiple naming styles are detected within the same SQL input and there is sufficient evidence that the identifiers belong to the same naming context.

Examples of naming styles include:

- snake_case
- camelCase
- PascalCase
- UPPER_CASE
- Mixed or irregular naming.

## Examples

```sql
CREATE TABLE customers (
customer_id INT,
customerName VARCHAR(100),
CustomerEmail VARCHAR(200)
);
```

The identifiers use multiple naming conventions.

A consistent version could be:

```sql
CREATE TABLE customers (
customer_id INT,
customer_name VARCHAR(100),
customer_email VARCHAR(200)
);
```

## Risk

Inconsistent naming can:

- Reduce readability.
- Make schema navigation more difficult.
- Increase maintenance effort.
- Create confusion when writing new queries.
- Cause problems when integrating with tools that expect specific naming conventions.

## Recommendation

Use a consistent naming convention throughout the SQL input.

For example, if snake_case is selected:

customer_id
customer_name
customer_email
created_at
updated_at

## Limitations

The rule cannot determine the organization's preferred naming convention unless it is explicitly provided.

If the input contains only one or two identifiers, there may not be enough evidence to determine whether a convention is being violated.

# CONV-004 — Non-descriptive Alias

## Description

Table and column aliases should make complex SQL easier to understand.

Aliases such as a, b, x, or t1 may reduce readability when the query contains multiple tables or complex joins.

## Detection condition

The rule should be triggered when:

A table alias is excessively short or ambiguous.
Multiple aliases are used and their meaning is difficult to determine.
An alias does not provide useful semantic information in a complex query.

## Examples

```sql
SELECT a.name, b.name
FROM customers a
JOIN orders b
ON a.id = b.customer_id;
```

More descriptive:

```sql
SELECT c.name, o.name
FROM customers c
JOIN orders o
ON c.id = o.customer_id;
```

## Risk

Non-descriptive aliases can:

- Reduce query readability.
- Make joins harder to understand.
- Increase the probability of referencing the wrong table.
- Make complex queries harder to review.

## Recommendation

Use short but meaningful aliases that identify the table's purpose.

For example:

customers → c
orders → o
products → p

Avoid unnecessarily generic aliases such as:

a
b
x
y
t1
t2

when the query complexity makes them difficult to understand.

## Exceptions

Short aliases may be acceptable when:

- The query contains only one table.
- The alias is obvious from context.
- The project explicitly defines a short alias convention.
- The alias is widely understood and does not introduce ambiguity.

# CONV-005 — Inconsistent Table Alias Usage

## Description

A query may use aliases inconsistently, making references to tables unnecessarily difficult to follow.

For example, a table may be referenced using its full name in some parts of a query and an alias in other parts.

## Detection condition

The rule should be triggered when:

A table has an alias but references are inconsistently written.
Multiple naming styles are used for the same table within a query.
Alias usage introduces unnecessary ambiguity.

## Examples

SELECT customers.name
FROM customers c
JOIN orders o
ON customers.id = o.customer_id;

The query defines:

customers → c

but later references the table using customers.

A consistent version is:

SELECT c.name
FROM customers c
JOIN orders o
ON c.id = o.customer_id;

## Risk

Inconsistent alias usage can:

Reduce readability.
Make complex queries harder to understand.
Increase the possibility of reference errors.
Make query maintenance more difficult.

## Recommendation

Once an alias is defined, use it consistently throughout the query.

## Limitations

The exact syntax and alias requirements may vary between SQL engines.

The rule should focus on clear inconsistency rather than enforcing a specific alias style.

CONV-006 — Reserved Keyword Used as Identifier
Description

Using SQL reserved keywords as table or column names can reduce readability and may require quoting or escaping.

For example:

CREATE TABLE order (
id INT
);

order is commonly associated with SQL syntax.

Detection condition

The rule should be triggered when an identifier appears to use a reserved SQL keyword and the SQL dialect provides sufficient information to determine that the identifier conflicts with the language syntax.

Potential examples include:

order
user
group
select
table
where
from
Examples

Potentially problematic:

CREATE TABLE order (
id INT
);

Prefer:

CREATE TABLE orders (
order_id INT
);
Risk

Reserved keywords used as identifiers can:

Reduce portability between database engines.
Require quoting or escaping.
Reduce readability.
Cause syntax errors in some SQL dialects.
Recommendation

Avoid using reserved keywords as identifiers when possible.

Prefer descriptive alternatives such as:

order → orders
user → users
group → user_group
Limitations

Reserved keywords differ between SQL engines and versions.

The rule should not classify an identifier as a confirmed violation unless the SQL dialect is known or the keyword conflict is sufficiently evident.

When the SQL engine is unknown, the finding should be marked as potential.

CONV-007 — Inconsistent Capitalization
Description

SQL code may use inconsistent capitalization for SQL keywords, functions, identifiers, or other elements.

For example:

SELECT customer_id
from customers
WHERE status = 'active';

The SQL keywords use inconsistent capitalization.

Detection condition

The rule should be triggered when SQL keywords or other comparable elements use inconsistent capitalization within the same SQL input.

Examples include:

SELECT
from
WHERE
join

or:

SELECT
FROM
where
JOIN
Examples

Inconsistent:

SELECT customer_id
from customers
WHERE status = 'active';

Consistent:

SELECT customer_id
FROM customers
WHERE status = 'active';
Risk

Inconsistent capitalization can:

Reduce readability.
Make code reviews less consistent.
Make SQL scripts visually harder to scan.
Reduce adherence to project coding standards.
Recommendation

Use a consistent capitalization convention.

For example:

SELECT
FROM
WHERE
JOIN
GROUP BY
ORDER BY

SQL keywords can conventionally be written in uppercase while identifiers remain lowercase.

Exceptions

The rule should not report capitalization differences when:

The project explicitly defines another convention.
The SQL input is intentionally formatted differently.
Case differences are required by a particular SQL dialect or identifier behavior.
CONV-008 — Unclear Naming Separation
Description

Identifiers may contain multiple semantic components without a clear naming convention.

This can make it difficult to determine whether words represent an entity, attribute, relationship, or other concept.

Detection condition

The rule should be triggered when identifiers combine multiple concepts using unclear or inconsistent separators.

Potential examples include:

customerid
customer_id
customerId
customer-id
customerIDNumber

when these forms are mixed within the same schema or script.

Examples

Inconsistent:

CREATE TABLE customers (
customer_id INT,
customerName VARCHAR(100),
customer-email VARCHAR(200)
);

Consistent:

CREATE TABLE customers (
customer_id INT,
customer_name VARCHAR(100),
customer_email VARCHAR(200)
);
Risk

Unclear naming separation can:

Reduce readability.
Make identifiers harder to search.
Make relationships between words difficult to understand.
Create inconsistent schema conventions.
Recommendation

Use a consistent separator and naming style throughout the SQL input.

For example:

customer_id
customer_name
customer_email
created_at
updated_at
Limitations

The rule should not assume that one naming style is universally correct.

The appropriate convention depends on the project's standards, SQL engine, and existing schema.

Convention Rule Priority

Convention rules should generally have lower priority than security and data-integrity rules.

Recommended priority:

HIGH
└── Convention issue that can cause portability or syntax problems
(e.g., confirmed reserved keyword conflict)

MEDIUM
└── Significant inconsistency affecting maintainability
(e.g., inconsistent naming conventions)

LOW
└── Readability or stylistic recommendation
(e.g., non-descriptive alias)

INFO
└── Minor stylistic observation

Convention rules should not automatically receive HIGH or CRITICAL severity simply because a naming convention is violated.

Convention Review Principles

The convention reviewer should follow these principles:

Do not assume an organizational naming convention unless one is provided.
Do not treat stylistic preferences as functional errors.
Prefer consistency over a specific naming style.
Use the surrounding SQL as context before reporting ambiguous names.
Do not report a naming issue when the available context reasonably explains the identifier.
Distinguish between confirmed inconsistencies and potential recommendations.
Do not duplicate findings that belong to security or performance rules.
Do not infer business meaning that is not present in the SQL.
When the SQL dialect is unknown, avoid confirming dialect-specific naming violations.
Prioritize findings that materially affect readability and maintainability.
Avoid excessive stylistic findings that provide little practical value.
A query can be functionally correct while still containing convention findings.
The absence of convention findings does not mean that the SQL follows an organization's coding standard.
Recommendations should be actionable and, when appropriate, include an improved example.
The reviewer should preserve the distinction between CONFIRMED, POTENTIAL, and insufficient-context findings.
