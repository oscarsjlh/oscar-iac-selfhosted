---
name: gortex-scripts-backup
description: "Work in the scripts/backup area — 4 symbols across 2 files (100% cohesion)"
---

# scripts/backup

4 symbols | 2 files | 100% cohesion

## When to Use

Use this skill when working on files in:
- `ansible/roles/services/files/scripts/backup/backup.sh`
- `ansible/roles/services/files/scripts/backup/export-metrics.sh`

## Key Files

| File | Symbols |
|------|---------|
| `ansible/roles/services/files/scripts/backup/backup.sh` | check |
| `ansible/roles/services/files/scripts/backup/export-metrics.sh` | clear_metrics, write_metrics, export_metric |

## Entry Points

- `ansible/roles/services/files/scripts/backup/backup.sh::check`
- `ansible/roles/services/files/scripts/backup/export-metrics.sh::write_metrics`
- `ansible/roles/services/files/scripts/backup/export-metrics.sh::clear_metrics`
- `ansible/roles/services/files/scripts/backup/export-metrics.sh::export_metric`

## How to Explore

```
get_communities with id: "community-0"
smart_context with task: "understand scripts/backup", format: "gcx"
find_usages with id: "ansible/roles/services/files/scripts/backup/backup.sh::check", format: "gcx"
```

_`format: "gcx"` returns the [GCX1 compact wire format](../../docs/wire-format.md) — round-trippable, ~27% fewer tokens than JSON. Drop it for JSON output; agents using `@gortex/wire` or the Go `github.com/gortexhq/gcx-go` package decode either._
