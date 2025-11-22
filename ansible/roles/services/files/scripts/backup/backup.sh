#!/bin/bash
# Author: Oscar
# Date: date +%Y-%m-%d
# Description: Backup script for my server

source /home/oscar/backup/.env

check() {
  if [[ $? -ne 0 ]]; then
    curl -d "$1" https://ntfy.oscarcorner.com/backups-oscar

    echo ""
    echo -e "\e[31mSomething went wrong \e[0m"
    echo -e "\e[31m '$1' \e[0m"
    echo ""
    exit
  fi

}

echo -e "\e[32mStarting backup script \e[0m"
echo ""
echo ""
restic backup /mnt/nfs/media/music/ \
  /home/oscar/jellyfin/config \
  /home/oscar/forgejo-backup \
  /home/oscar/qbitorrent/configs/ \
  /mnt/nfs/backup/ \
  /mnt/smb_backup/ \
  --exclude-file /home/oscar/backup/excludes.txt \
  --compression max --cleanup-cache \
  --exclude-caches
check "Something went wrong backing up the server"
restic forget --keep-daily 7 --keep-monthly 1 --prune
check "Something went wrong pruning the server"

restic check --read-data-subset=1G
check "Something went wrong checking the backups"

curl -d "Backup ran succsefully" https://ntfy.oscarcorner.com/backups-oscar

date=$(date +%Y-%m-%d)
echo -e "\e[32m backup script run succsefully at '$date'  \e[0m"
echo ""
echo ""
