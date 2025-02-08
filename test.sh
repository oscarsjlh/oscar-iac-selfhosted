#!/bin/bash
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: A brief description of the script.

set -euo pipefail

# Your script starts here

for file in ./services/*.timer; do
  echo "$file"
done
