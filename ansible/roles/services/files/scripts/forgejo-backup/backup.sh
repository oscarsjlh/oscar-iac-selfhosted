#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../backup/export-metrics.sh"

JOB="forgejo"
START_TIME=$(date +%s)

REMOTE_USER="backupap"
REMOTE_HOST="nas.oscarcorner.com"
DOCKER_CONTAINER="ix-forgejo-forgejo-1"
REMOTE_BACKUP_DIR="/mnt/Black-Sabbath/Homedirs/AppBackup/backupap"
LOCAL_BACKUP_DIR="$HOME/forgejo-backup"
DATE="$(date +%Y-%m-%d)"
BACKUP_FILE="backup-${DATE}.zip"
REMOTE_TMP_FILE="/tmp/${BACKUP_FILE}"

cleanup_metrics() {
	local status="$1"
	local end_time=$(date +%s)
	local duration=$((end_time - START_TIME))
	local file_size=0

	if [ -f "${LOCAL_BACKUP_DIR}/${BACKUP_FILE}" ]; then
		file_size=$(stat -c%s "${LOCAL_BACKUP_DIR}/${BACKUP_FILE}" 2>/dev/null || echo 0)
	fi

	clear_metrics
	export_metric "backup_status" "${status}" "job=\"${JOB}\""
	export_metric "backup_last_success_timestamp" "$(date +%s)" "job=\"${JOB}\""
	export_metric "backup_last_duration_seconds" "${duration}" "job=\"${JOB}\""
	export_metric "backup_last_size_bytes" "${file_size}" "job=\"${JOB}\""
	write_metrics
}

trap 'cleanup_metrics 0' ERR

echo "[*] Creating Forgejo backup on remote server..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
	"sudo docker exec -i ${DOCKER_CONTAINER} sh -c 'forgejo dump --config /etc/gitea/app.ini --file ${REMOTE_TMP_FILE}'"

echo "[*] Copying backup from docker container to remote user directory..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
	"sudo docker cp ${DOCKER_CONTAINER}:${REMOTE_TMP_FILE} ${REMOTE_BACKUP_DIR}/${BACKUP_FILE} && sudo chown ${REMOTE_USER}:${REMOTE_USER} ${REMOTE_BACKUP_DIR}/${BACKUP_FILE}"

echo "[*] Removing temporary backup file in container..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
	"sudo docker exec -i ${DOCKER_CONTAINER} rm -f ${REMOTE_TMP_FILE}"

echo "[*] Deleting backups older than 30 days on remote server..."
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
	"find ${REMOTE_BACKUP_DIR} -maxdepth 1 -type f -name 'backup-*.zip' -mtime +7 -exec rm -vf {} \;"

echo "[*] Downloading latest backup file to local machine..."
scp "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BACKUP_DIR}/${BACKUP_FILE}" "${LOCAL_BACKUP_DIR}/"

if [ -f "${LOCAL_BACKUP_DIR}"/"${BACKUP_FILE}" ]; then
	echo "[*] Removing backup from remote server"
	ssh "${REMOTE_USER}@${REMOTE_HOST}" \
		"rm ${REMOTE_BACKUP_DIR}/${BACKUP_FILE}"
fi

find ${LOCAL_BACKUP_DIR} -maxdepth 1 -type f -name 'backup-*.zip' -mtime +7 -exec rm -vf {} \;

cleanup_metrics 1
