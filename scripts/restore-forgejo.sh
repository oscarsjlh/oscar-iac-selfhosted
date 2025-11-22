#!/bin/bash
# Date: $(date +%Y-%m-%d)
set -euo pipefail
# ====== CONFIGURE THESE TWO PATHS ======
FORGEJO_PATH="/mnt/Black-Sabbath/Apps/Forgejo" # Current Forgejo directory on TrueNAS
BACKUP_PATH="./backups"                        # Directory containing restored backups
# =======================================

echo "== Stopping Forgejo App =="
docker stop ix-forgejo-forgejo-1
echo "== Restoring backup folders =="

cp -r "$BACKUP_PATH/app.ini" "$FORGEJO_PATH/Config/"
cp -r "$BACKUP_PATH/data" "$FORGEJO_PATH/AppData"
mkdir -p "$FORGEJO_PATH/AppData/git/repositories"
cp -r "$BACKUP_PATH/repos/wazor12" "$FORGEJO_PATH/AppData/git/repositories/"

chown -R 999:999 "$FORGEJO_PATH/Data"
chown -R root:root "$BACKUP_PATH/forgejo-db.sql"
chmod 0777 "$BACKUP_PATH/forgejo-db.sql"

docker start ix-forgejo-postgres-1

docker exec -i ix-forgejo-postgres-1 sh -c 'psql -U forgejo -d forgejo' <backups/forgejo-db.sql

echo "== Fixing ownership =="

echo "== Verifying structure =="
ls -l "$FORGEJO_PATH"

echo "== Starting Forgejo App =="

docker start ix-forgejo-forgejo-1

echo "== Done! =="
docker restart ix-forgejo-forgejo-1
