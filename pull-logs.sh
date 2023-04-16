#!/bin/bash
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/send-it-log.txt
TARGETLOG=/tmp/it-app.log
# hostname will make it easy to locate the user in mdm
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in (non-root) user, might be useful at some point
ACTIVE_USER=$(stat -f%Su /dev/console)
# url to post to a chat bot
WEBHOOK_URL="https://example.com/v1/blabla"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

writeLog "== Debug log for IT Help app on $DEVICE_NAME used by $ACTIVE_USER =="

# strip special chars that break the curl post
writeLog "$(cat "$TARGETLOG" | tr -d '{}[]"')"
curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"

echo "Done."
exit 0