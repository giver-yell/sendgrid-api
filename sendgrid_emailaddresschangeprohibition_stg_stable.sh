#!/bin/bash

API_KEY="$1"
if [[ -z $API_KEY ]]; then
    echo "Usage: $0 <API_KEY>"
    exit 1
fi

TEMPLATE_ID1="TEMPLATE_ID1"
TEMPLATE_ID2="TEMPLATE_ID2"

./sendgrid_template_diff_write.sh "$API_KEY" "$TEMPLATE_ID1" "$TEMPLATE_ID2"
