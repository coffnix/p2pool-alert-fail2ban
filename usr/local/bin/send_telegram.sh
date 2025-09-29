#!/bin/bash
{
  TOKEN='8173700786:AAEVopf7Zw5CP2tT1fmGOtuYoEiOV4b-5qM'
  USER="$1"
  SUBJECT_IN="$2"

  date
  echo "comando:"
  echo "curl -s -X POST https://api.telegram.org/bot\${TOKEN}/sendMessage -d chat_id=\${USER} --data-urlencode text=\"\${SUBJECT_IN}\""
  echo
  echo "saida:"
  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
       -d "chat_id=${USER}" \
       --data-urlencode "text=${SUBJECT_IN}"
  echo -e '\n\n#################################'
} >> /var/log/p2pool_telegram.log 2>&1
exit 0
