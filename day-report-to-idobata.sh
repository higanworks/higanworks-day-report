#!/bin/sh

#
# Require env valuse
#
#   GITHUB_USER
#   GITHUB_TOKEN
#   DAY_REPORT_RB_PATH
#   IDOBATA_HOOK_URL
#

RESULT=`${DAY_REPORT_RB_PATH}`

curl --data-urlencode "source=${RESULT}" -d format=html ${IDOBATA_HOOK_URL}
