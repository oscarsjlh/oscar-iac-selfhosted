#!/bin/bash
METRICS_DIR="${BACKUP_METRICS_DIR:-/var/lib/node-exporter/textfile}"
mkdir -p "$METRICS_DIR"

export_metric() {
	local name="$1"
	local value="$2"
	local labels="${3:-}"
	local file="$METRICS_DIR/backup.prom.tmp"

	if [ -n "$labels" ]; then
		echo "${name}{${labels}} ${value}" >>"$file"
	else
		echo "${name} ${value}" >>"$file"
	fi
}

write_metrics() {
	local file="$METRICS_DIR/backup.prom.tmp"
	local final="$METRICS_DIR/backup.prom"
	mv "$file" "$final"
}

clear_metrics() {
	rm -f "$METRICS_DIR/backup.prom.tmp" "$METRICS_DIR/backup.prom"
}
