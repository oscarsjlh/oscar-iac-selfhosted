#!/bin/bash
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: A brief description of the script.

set -euo pipefail

# Your script starts here

set -euo pipefail

IP_SERVICES=(
  "http://checkip.amazonaws.com"
  "https://api.ipify.org"
  "https://icanhazip.com"
  "https://ip.me"
)
get_public_ip() {
  for service in "${IP_SERVICES[@]}"; do
    IP=$(curl -s --max-time 5 "$service")
    if [[ $? -eq 0 && $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "$IP"
      return
    fi
  done

  # If all services fail, exit with an error
  echo "Error: Unable to retrieve public IP from any service." >&2
  exit 1
}

old_ip=old_ip.txt
NEW_IP=$(get_public_ip)
#

if [[ -f "$old_ip" ]]; then
  LAST_IP=$(cat $old_ip)
  if [[ "$NEW_IP" == "LAST_IP" ]]; then
    echo "No change in IP, Current: IP: $NEW_IP"
    exit 0
  fi
fi

echo $NEW_IP >$old_ip
# Your script starts here
#
cat >change-batch.json <<EOF
{
  "Comment": "Update DDNS record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "wireguard.oscarcorner.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$NEW_IP"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id Z05080821D3KFPK0X4CL1 --change-batch file://change-batch.json

if [[ $? -eq 0 ]]; then
  echo "DNS record updated successfully with IP: $NEW_IP"
  curl -d "Dns record updated with IP '$NEW_IP'" https://ntfy.oscarcorner.com/backups-oscar

else
  echo "Error: Failed to update DNS record." >&2
  curl -d "Dns record update faile" https://ntfy.oscarcorner.com/backups-oscar
  exit 1
fi
