#!/bin/bash
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: A brief description of the script.

set -euo pipefail
declare -a RECORDS=("sonarr" "radarr" "sonarr-anime" "navidrome" "prowlarr" "readarr" "calibre" "sabnzbd" "slskd" "bazarr" "lidarr")

# Your script starts here

for record in ${RECORDS[@]}; do
  echo -e "
  uci add dhcp cname
  uci set dhcp.@cname[-1].cname=$record.oscarcorner.com
  uci set dhcp.@cname[-1].target="media.home.com"
  uci commit dhcp
  service dnsmasq restart
  "
done
