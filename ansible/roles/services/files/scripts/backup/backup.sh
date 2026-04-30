#!/bin/bash
# Author: Oscar
# Description: Backup script for my server with Prometheus metrics

source /home/oscar/backup/.env
source "$(dirname "$0")/export-metrics.sh"

JOB="restic"
START_TIME=$(date +%s)

check() {
	if [[ $? -ne 0 ]]; then
		curl -d "$1" https://ntfy.oscarcorner.com/backups-oscar
		END_TIME=$(date +%s)
		DURATION=$((END_TIME - START_TIME))

		clear_metrics
		export_metric "backup_status" "0" "job=\"${JOB}\""
		export_metric "backup_last_failure_timestamp" "$(date +%s)" "job=\"${JOB}\""
		export_metric "backup_last_duration_seconds" "${DURATION}" "job=\"${JOB}\""
		write_metrics

		echo ""
		echo -e "\e[31mSomething went wrong \e[0m"
		echo -e "\e[31m '$1' \e[0m"
		echo ""
		exit 1
	fi
}

echo -e "\e[32mStarting backup script \e[0m"
echo ""

OUTPUT=$(restic backup /mnt/nfs/media/music/ \
	/home/oscar/jellyfin/config \
	/mnt/nas/media/photos/immich/library \
	/home/oscar/forgejo-backup \
	/home/oscar/qbitorrent/configs/ \
	/home/oscar/technitium \
	/mnt/nfs/backup/ \
	/mnt/smb_backup/ \
	--exclude-file /home/oscar/backup/excludes.txt \
	--compression max --cleanup-cache \
	--exclude-caches --json 2>&1)

SUMMARY=$(echo "$OUTPUT" | grep '"message_type":"summary"' | tail -1)
if [ -n "$SUMMARY" ]; then
	FILES_NEW=$(echo "$SUMMARY" | jq -r '.files_new // 0')
	FILES_CHANGED=$(echo "$SUMMARY" | jq -r '.files_changed // 0')
	FILES_UNMODIFIED=$(echo "$SUMMARY" | jq -r '.files_unmodified // 0')
	BYTES_ADDED=$(echo "$SUMMARY" | jq -r '.bytes_added // 0')
	BYTES_PROCESSED=$(echo "$SUMMARY" | jq -r '.bytes_processed // 0')
else
	FILES_NEW=0
	FILES_CHANGED=0
	FILES_UNMODIFIED=0
	BYTES_ADDED=0
	BYTES_PROCESSED=0
fi

check "Something went wrong backing up the server"

restic forget --keep-daily 7 --keep-monthly 1 --prune
check "Something went wrong pruning the server"

restic check --read-data-subset=1G
check "Something went wrong checking the backups"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

clear_metrics
export_metric "backup_status" "1" "job=\"${JOB}\""
export_metric "backup_last_success_timestamp" "$(date +%s)" "job=\"${JOB}\""
export_metric "backup_last_duration_seconds" "${DURATION}" "job=\"${JOB}\""
export_metric "backup_last_size_bytes" "${BYTES_ADDED}" "job=\"${JOB}\""
export_metric "backup_files_new" "${FILES_NEW}" "job=\"${JOB}\""
export_metric "backup_files_changed" "${FILES_CHANGED}" "job=\"${JOB}\""
export_metric "backup_files_unmodified" "${FILES_UNMODIFIED}" "job=\"${JOB}\""
export_metric "backup_bytes_processed" "${BYTES_PROCESSED}" "job=\"${JOB}\""
write_metrics

curl -d "Backup ran successfully" https://ntfy.oscarcorner.com/backups-oscar

date=$(date +%Y-%m-%d)
echo -e "\e[32m backup script run successfully at '$date'  \e[0m"
echo ""
