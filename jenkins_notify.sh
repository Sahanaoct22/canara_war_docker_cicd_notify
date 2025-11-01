#!/bin/bash
# ./jenkins_notify.sh
# Usage: ./jenkins_notify.sh <STATUS> <JOB_NAME> <BUILD_ID> "<comma,separated,emails>"
#
# Designed & Developed by Sak_Shetty

STATUS="$1"
JOB_NAME="$2"
BUILD_ID="$3"
RECEIVERS="$4"

# fallback
[ -z "$RECEIVERS" ] && RECEIVERS="defaultteam@example.com"
# convert comma separated to space-separated
TO_LIST=$(echo "$RECEIVERS" | sed 's/,/ /g')

# Jenkins-provided credentials (set via withCredentials in pipeline)
GMAIL_USER="${GMAIL_USER:-}"
GMAIL_PASS="${GMAIL_APP_PASS:-}"

# Install mailx if not present (idempotent)
if ! command -v mailx &> /dev/null; then
  echo "📦 mailx not found — installing..."
  sudo apt-get update -y
  sudo apt-get install -y mailutils heirloom-mailx
else
  echo "✅ mailx installed — skipping"
fi

# Email content
TIMESTAMP="$(date --rfc-3339=seconds)"
SUBJECT_PREFIX="[Canara CI/CD]"
SUBJECT="$SUBJECT_PREFIX $STATUS: $JOB_NAME #$BUILD_ID"
SUBJECT="$SUBJECT - Designed & Developed by Sak_Shetty"

BODY="$(cat <<EOF
Build Status : $STATUS
Job Name     : $JOB_NAME
Build ID     : $BUILD_ID
Date         : $TIMESTAMP
Build URL    : ${BUILD_URL:-N/A}

This notification was Designed & Developed by Sak_Shetty
EOF
)"

# Send email using mailx with Gmail SMTP
echo -e "$BODY" | mailx \
  -S smtp="smtp.gmail.com:587" \
  -S smtp-use-starttls \
  -S smtp-auth=login \
  -S smtp-auth-user="$GMAIL_USER" \
  -S smtp-auth-password="$GMAIL_PASS" \
  -S ssl-verify=ignore \
  -s "$SUBJECT" $TO_LIST

if [ $? -eq 0 ]; then
  echo "✅ Mail sent successfully to: $TO_LIST"
else
  echo "❌ Mail sending failed"
  exit 1
fi
