# CI/CD-Driven Database Change Deployment

> **MySQL 8 · Python 3.11 · GitHub Actions**

An enterprise-grade, **Liquibase-like** migration framework with a built-in
data pipeline — designed to eliminate manual DB changes and environment drift.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Architecture](#architecture)
3. [Repository Layout](#repository-layout)
4. [How It Works](#how-it-works)
5. [Migration Contract](#migration-contract)
6. [Data Pipeline](#data-pipeline)
7. [Data Quality & Reconciliation](#data-quality--reconciliation)
8. [Rollback & Failure Recovery](#rollback--failure-recovery)
9. [Security — RBAC & Data Masking](#security--rbac--data-masking)
10. [Performance & Tuning](#performance--tuning)
11. [Observability & Audit](#observability--audit)
12. [How to Run Locally](#how-to-run-locally)
13. [GenAI Usage & Refinement](#genai-usage--refinement)
14. [Design Decisions & Trade-offs](#design-decisions--trade-offs)
15. [Future Evolution](#future-evolution)

---

## Problem Statement

Manual database changes caused **inconsistencies across dev, test, and prod
environments**.  This project enforces:

| Requirement | How It's Met |
|---|---|
| Versioned migration scripts | YAML changelog + ordered SQL files |
| Rollback support | Automatic backup-restore on failure |
| Controlled schema evolution | Checksums, preconditions, policy gates |
| Environment-aware orchestration | GitHub Environments (dev / prod), contexts |
| Approval workflow | GitHub Environment required reviewers (prod) |
| Audit logs | `DATABASECHANGELOG`, `ops_migration_runs`, `ops_pipeline_runs` |
| Failure recovery | Auto-rollback + incident runbook |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│  GitHub Actions                                                          │
│  ┌─────────┐    ┌────────────┐    ┌────────────────┐                     │
│  │  CI      │    │ Deploy Dev │    │  Deploy Prod   │                     │
│  │ (PR/push)│    │ (push main)│    │ (manual+approv)│                     │
│  └────┬─────┘    └─────┬──────┘    └──────┬─────────┘                     │
│       │                │                   │                              │
│       ▼                ▼                   ▼                              │
│  ┌─────────────────────────────────────────────────────┐                  │
│  │                Migration Runner                      │                  │
│  │  validate → status → backup → update → auto-rollback │                  │
│  └──────────────────────┬──────────────────────────────┘                  │
│                         │                                                 │
│  ┌──────────────────────▼──────────────────────────────┐                  │
│  │                Data Pipeline                         │                  │
│  │  ingest (CSV→staging) → transform (dims/facts)       │                  │
│  │  → validate (DQ checks + reconciliation)             │                  │
│  └──────────────────────┬──────────────────────────────┘                  │
│                         │                                                 │
│                         ▼                                                 │
│  ┌──────────────────────────────────────────────────────┐                  │
│  │  MySQL 8                                              │                  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐              │                  │
│  │  │ stg_*    │ │ dim_*    │ │ fact_*   │              │                  │
│  │  │ (staging)│ │ (curated)│ │ (curated)│              │                  │
│  │  └──────────┘ └──────────┘ └──────────┘              │                  │
│  │  ┌──────────────────┐  ┌──────────────────┐          │                  │
│  │  │ DATABASECHANGELOG│  │ ops_*            │          │                  │
│  │  │ (migration audit)│  │ (pipeline audit) │          │                  │
│  │  └──────────────────┘  └──────────────────┘          │                  │
│  └──────────────────────────────────────────────────────┘                  │
└──────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
Source (CSV files)
   │
   ▼
Staging  (stg_customers, stg_orders)      ← idempotent upsert, watermark checkpoints
   │
   ▼
Curated  (dim_customer SCD-2, fact_order) ← joins, aggregations, surrogate keys
   │
   ▼
Consumption  (vw_customer_masked, vw_order_summary) ← masked + aggregated views
```

---

## Repository Layout

```
├── changelog/
│   └── changelog.yml           # Liquibase-like manifest (changesets + preconditions)
├── migrations/
│   ├── 001_initial_schema.up.sql
│   ├── 002_add_indexes.up.sql
│   └── 003_rbac_masking.up.sql
├── sql/
│   ├── transform/
│   │   ├── build_dims.sql      # SCD Type 2 dimension logic
│   │   └── build_facts.sql     # Fact-table join + upsert
│   └── validation/
│       └── dq_checks.sql       # Reference DQ queries
├── data/raw/
│   ├── customers.csv
│   └── orders.csv
├── src/
│   ├── db.py                   # Shared MySQL utilities
│   ├── migrate/
│   │   ├── __main__.py         # CLI: validate | status | update | update_sql | verify
│   │   ├── changelog.py        # Parse changelog YAML
│   │   ├── runner.py           # Core migration logic (lock, checksum, apply)
│   │   ├── preconditions.py    # tableExists / columnExists / indexExists / sqlCheck
│   │   └── policy.py           # Destructive-SQL gating
│   └── pipeline/
│       ├── __main__.py         # CLI: run
│       ├── ingest.py           # CSV → staging (upsert + watermark)
│       ├── transform.py        # staging → curated (SQL-driven)
│       ├── validate.py         # DQ checks + reconciliation
│       └── runner.py           # Orchestrator (ingest→transform→validate)
├── .github/workflows/
│   ├── ci.yml                  # PR + push: validate, apply, pipeline, verify
│   ├── deploy-dev.yml          # push main: backup → apply → pipeline
│   └── deploy-prod.yml         # manual: approval → backup → apply → rollback
├── CODEOWNERS                  # Enforces review for migrations/ and changelog/
├── requirements.txt
└── README.md
```

---

## How It Works

### Migration Runner (`python -m src.migrate`)

| Command | Description |
|---|---|
| `validate` | Validates changelog YAML + referenced SQL files (offline) |
| `status [--context dev]` | Lists pending changesets for a context |
| `update [--context dev]` | Applies pending changesets with lock + audit |
| `update_sql [--context dev]` | Dry-run: prints the SQL that would execute |
| `verify` | Confirms applied checksums match current SQL files |

**Execution flow** (on `update`):

1. Bootstrap `DATABASECHANGELOGLOCK` + `DATABASECHANGELOG` + `ops_migration_runs`.
2. Acquire advisory lock (`GET_LOCK`) + Liquibase-style row lock.
3. For each pending changeset:
   a. **Policy check** — block destructive SQL unless overridden.
   b. **Preconditions** — evaluate `tableExists`, `columnExists`, etc.
   c. **Apply** — execute SQL via multi-statement cursor.
   d. **Record** — insert into `DATABASECHANGELOG` with SHA-256 checksum.
4. Record run result in `ops_migration_runs`.
5. Release lock.

### Drift Detection

Once a changeset is applied, its SQL file's SHA-256 checksum is stored in
`DATABASECHANGELOG`.  If someone edits the file after it has been applied,
the next `update` or `verify` run fails with a **checksum mismatch** error.
This prevents silent drift.

---

## Migration Contract

Users add entries to `changelog/changelog.yml`:

```yaml
- changeSet:
    id: "004"
    author: "your-name"
    sqlFile: "migrations/004_my_change.up.sql"
    risk: "low"           # low | medium | high
    allowDestructive: false
    labels: "feature-x"
    contexts: "dev,prod"
    preconditions:          # optional
      - tableExists:
          tableName: "stg_customers"
        onFail: "HALT"     # HALT | MARK_RAN | WARN
```

**Rules**:
- Ordering comes from the changelog (not filenames).
- Once applied, **never edit** the SQL file — create a new changeset.
- Destructive SQL (`DROP TABLE`, `TRUNCATE`) is blocked unless
  `allowDestructive: true` AND `ALLOW_DESTRUCTIVE=true` env var is set.

---

## Data Pipeline

The pipeline (`python -m src.pipeline run`) demonstrates:

| Stage | What It Does | Key Pattern |
|---|---|---|
| **Ingest** | CSV → `stg_*` tables | Idempotent upsert + watermark checkpoints |
| **Transform** | `stg_*` → `dim_customer` + `fact_order` | SCD Type 2, JOIN + aggregation |
| **Validate** | 5 DQ checks → `ops_dq_results` | Fail pipeline if thresholds breached |

### Idempotency

- **Ingestion**: `INSERT ... ON DUPLICATE KEY UPDATE` ensures re-runs
  update rather than duplicate. Watermark checkpoints (`ops_checkpoints`)
  skip already-processed rows.
- **Transforms**: dimension SCD-2 only expires rows with actual changes;
  fact upsert uses `ON DUPLICATE KEY UPDATE`.

### Partial Failure Handling

If the pipeline fails mid-run:
- `ops_pipeline_runs.status` is set to `'failed'` with the error in `details`.
- Watermark checkpoints are saved per-dataset, so a re-run picks up where
  it left off for ingestion.
- The fact-table upsert is safe to re-run.

---

## Data Quality & Reconciliation

| Check | Rule | Threshold |
|---|---|---|
| `orphan_orders` | Every order has a matching customer | 0 orphans |
| `duplicate_order_ids` | `order_id` is unique | 0 duplicates |
| `fact_recon_count` | `COUNT(fact_order)` == joinable staging count | exact match |
| `null_required_fields` | `full_name`, `email`, `country` non-empty | 0 nulls |
| `negative_amounts` | `amount > 0` | 0 violations |

Results are stored in `ops_dq_results` with metric values and thresholds.
If **any** check fails, the pipeline raises an error and the workflow fails.

---

## Rollback & Failure Recovery

### How Rollback Works (UP-only migrations)

Since users provide only forward SQL (no `.down.sql`), rollback is
**backup-restore based**:

1. **Before** applying any changeset, the workflow takes a `mysqldump`
   logical backup and uploads it as a GitHub Actions artifact.
2. **If** migration fails, the workflow **automatically** restores the
   backup (`mysql … < backup.sql`), returning the DB to the state it was
   in **immediately before** the deploy.
3. The backup artifact is retained (7 days CI, 30 days dev, 90 days prod).

### Important Limitation

Auto-restore replaces the **entire database** with the backup snapshot.
If other systems wrote data between the backup and the failure, that data
is lost.  Mitigations:

- Schedule deployments in **maintenance windows** (prod).
- Block application writes during deploy (feature flag / read-only mode).
- The migration lock prevents concurrent schema changes, but does not
  block application DML.

### What Happens on Failure (step by step)

1. `update` raises an error → `ops_migration_runs.status = 'failed'`.
2. Workflow step `Auto-rollback on migration failure` triggers (`if: failure()`).
3. `mysql … < $BACKUP_FILE` restores the database.
4. (Prod only) An incident note is printed with next-step instructions.

---

## Security — RBAC & Data Masking

### Role-Based Access Control

Three MySQL user roles are documented in `migrations/003_rbac_masking.up.sql`:

| Role | Privileges | Purpose |
|---|---|---|
| `migrator` | `ALTER, CREATE, DROP, INDEX` + audit DML | Schema changes only |
| `etl_runner` | `SELECT, INSERT, UPDATE, DELETE` on `stg_*`, `dim_*`, `fact_*`, `ops_*` | Pipeline DML, no DDL |
| `analytics_ro` | `SELECT` on `vw_customer_masked`, `vw_order_summary`, `fact_order` | Read-only analytics |

> GRANTs are documented as SQL comments; a DBA applies them once per
> environment using a privileged session.

### Data Masking

- **`dim_customer.email_masked`**: SHA-256 hash of the raw email — stored
  at transform time.  Original email never leaves the staging layer.
- **`vw_customer_masked`**: replaces `full_name` with first initial + `***`.
- **`analytics_ro`** has no access to `stg_customers` or `dim_customer`,
  only the masked view.

---

## Performance & Tuning

### Indexing Strategy

| Index | Purpose |
|---|---|
| `idx_stg_customers_updated` | Watermark-based incremental processing |
| `idx_stg_orders_updated` | Watermark-based incremental processing |
| `idx_stg_orders_customer` | FK join acceleration |
| `idx_dim_cust_bk`, `idx_dim_cust_current` | Surrogate-key lookups, SCD-2 |
| `idx_fact_order_date`, `idx_fact_order_cust` | Analytics range scans |
| `idx_fact_order_date_cust` | Composite covering index for date+customer queries |
| `idx_fact_order_status_date` | Covering index for status-based reporting |

### Partitioning (Production Evolution)

For large `fact_order` tables, partition by `order_date` (RANGE or RANGE COLUMNS):

```sql
ALTER TABLE fact_order
PARTITION BY RANGE (TO_DAYS(order_date)) (
    PARTITION p2026q1 VALUES LESS THAN (TO_DAYS('2026-04-01')),
    PARTITION p2026q2 VALUES LESS THAN (TO_DAYS('2026-07-01')),
    PARTITION pmax    VALUES LESS THAN MAXVALUE
);
```

This enables partition pruning for date-range queries and simplifies
archival (`ALTER TABLE … DROP PARTITION`).

### Query Tuning — EXPLAIN Example

```sql
EXPLAIN SELECT d.country, SUM(f.amount)
FROM fact_order f
JOIN dim_customer d ON d.customer_sk = f.customer_sk AND d.is_current = 1
WHERE f.order_date BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY d.country;
```

Expected plan:
- `fact_order`: range scan on `idx_fact_order_date` (partition pruning if partitioned).
- `dim_customer`: eq_ref on PRIMARY via `customer_sk`.

---

## Observability & Audit

| What | Where |
|---|---|
| Changeset history | `DATABASECHANGELOG` (id, author, checksum, timestamp) |
| Migration run audit | `ops_migration_runs` (run_id, env, actor, status, backup_ref) |
| Pipeline run audit | `ops_pipeline_runs` (run_id, env, actor, status, details) |
| DQ check results | `ops_dq_results` (run_id, check, pass/fail, metric, threshold) |
| Watermark checkpoints | `ops_checkpoints` (dataset, last_watermark) |
| Structured logs | JSON lines on stdout (consumable by log aggregators) |
| Backup artifacts | GitHub Actions artifacts (retention: 7/30/90 days by env) |

---

## How to Run Locally

```bash
# 1. Start MySQL (Docker)
docker run -d --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=devpw \
  -e MYSQL_DATABASE=migration_db \
  -p 3306:3306 mysql:8.0

# 2. Set environment variables
export DB_HOST=127.0.0.1 DB_PORT=3306 DB_USER=root DB_PASSWORD=devpw DB_NAME=migration_db

# 3. Install Python deps
pip install -r requirements.txt

# 4. Run migrations
python -m src.migrate validate
python -m src.migrate status
python -m src.migrate update

# 5. Run pipeline
python -m src.pipeline run --env dev

# 6. Verify
python -m src.migrate verify
```

---

## GenAI Usage & Refinement

| Area | GenAI Contribution | What Was Corrected / Improved |
|---|---|---|
| Migration runner skeleton | Initial structure, argparse CLI | Added Liquibase-style lock table + advisory lock (defense-in-depth); GenAI only suggested `GET_LOCK`. |
| Changelog YAML parser | Drafted schema | Added duplicate-ID detection, context/label normalisation, and precondition-syntax validation that GenAI omitted. |
| Rollback design | Suggested transactional DDL wrapping | **Corrected**: MySQL DDL is not transactional.  Switched to backup-restore approach which is the only safe pattern for UP-only migrations on MySQL. |
| Policy checks | Basic regex denylist | Added `allowDestructive` dual-gate (changeset + env var) and risky-operation warnings (ALTER TABLE → gh-ost note). |
| Preconditions | Suggested a single `tableExists` | Extended to `columnExists`, `indexExists`, `sqlCheck` with `onFail: HALT / MARK_RAN / WARN` matching Liquibase semantics. |
| DQ checks | Drafted orphan + duplicate checks | Added reconciliation (fact vs staging count), null-field checks, and negative-amount checks. Made results auditable in `ops_dq_results`. |
| SCD Type 2 SQL | Basic INSERT/UPDATE | Refined idempotency: added `LEFT JOIN … WHERE d.customer_sk IS NULL` guard to prevent re-inserts on repeat runs. |
| GitHub Actions | Basic workflow structure | Added auto-rollback (`if: failure()`), prod approval gates (`environment: prod`), incident-note printing, artifact retention by env, and MySQL service container health checks. |

**Summary**: GenAI accelerated scaffolding and first-draft SQL but missed
MySQL-specific constraints (non-transactional DDL, lock semantics),
idempotency edge cases, and enterprise governance patterns.  All of these
were corrected through engineering judgment.

---

## Design Decisions & Trade-offs

| Decision | Rationale | Alternative Considered |
|---|---|---|
| YAML changelog (not folder-discovery) | Explicit ordering + metadata (labels, contexts, preconditions) | Flyway-style folder discovery — simpler but no preconditions or context filtering |
| UP-only (no down scripts) | Reduces user burden; down scripts are error-prone for DDL | Requiring `.down.sql` — safer rollback but higher authoring cost and MySQL DDL isn't transactional anyway |
| Backup-restore rollback | Only safe MySQL rollback for arbitrary DDL | PITR (binlog) — more precise but complex to automate in GitHub Actions |
| `mysqldump` (logical) | Simple, portable, works with service containers | `xtrabackup` (physical) — faster for large DBs but requires file-system access |
| Single changelog file | Simplicity for demo; real projects can use `include` patterns | Multiple changelogs per team/module |
| Watermark-based incremental | Simple, works with `updated_at` columns | CDC / binlog streaming — lower latency but much higher infrastructure cost |

---

## Future Evolution

If this were a real client project:

1. **Object-storage backups** — push `mysqldump` to S3/GCS instead of
   GitHub artifacts (larger DBs, longer retention, cross-workflow access).
2. **PITR with binlogs** — capture binlog coordinates before migration;
   enables precise point-in-time recovery without full backup restore.
3. **Online schema change** — integrate `gh-ost` or `pt-online-schema-change`
   for ALTER TABLE on large production tables (zero-downtime).
4. **Multi-changelog support** — `include` directives to split changelogs
   by team or module.
5. **Secrets via Vault / OIDC** — replace long-lived DB passwords with
   short-lived tokens from HashiCorp Vault or cloud IAM.
6. **Monitoring / alerting** — ship structured logs to Datadog / Splunk;
   alert on migration failures, DQ threshold breaches, or SLA misses.
7. **Data contracts** — formalise schema expectations between producers
   and consumers using a contract registry.
