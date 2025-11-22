#!/bin/bash
# Date: $(date +%Y-%m-%d)
set -euo pipefail

REMOTE_USER="backupap"
REMOTE_HOST="nas.oscarcorner.com"
DOCKER_CONTAINER="ix-forgejo-forgejo-1"
REMOTE_BACKUP_DIR="/mnt/Black-Sabbath/Homedirs/AppBackup/backupap"
LOCAL_BACKUP_DIR="."
DATE="$(date +%Y-%m-%d)"
BACKUP_FILE="backup-${DATE}.zip"
REMOTE_TMP_FILE="/tmp/${BACKUP_FILE}"

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
  "find ${REMOTE_BACKUP_DIR} -maxdepth 1 -type f -name 'backup-*.zip' -mtime +30 -exec rm -vf {} \;"

echo "[*] Downloading latest backup file to local machine..."
scp "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BACKUP_DIR}/${BACKUP_FILE}" "${LOCAL_BACKUP_DIR}/"

if [ -d ${LOCAL_BACKUP_DIR}/${BACKUP_FILE} ]; then
  echo "[*] Removeing backup from remote server"
  ssh "${REMOTE_USER}@${REMOTE_HOST}" \
    "rm ${REMOTE_BACKUP_DIR}/${BACKUP_FILE}"
fi

find ${LOCAL_BACKUP_DIR} -maxdepth 1 -type f -name 'backup-*.zip' -mtime +30 -exec rm -vf {} \;
