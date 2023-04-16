#!/bin/bash

# first launch file
TMPLOG=/tmp/it-app.log
# get the user firstname (for personalized message)
FIRSTNAME="$(id -F | awk '{print $1}')"
# get the working directory to the invoked script (for portability)
DIR="$(cd "$(/usr/bin/dirname -- "$0")"; cd ../Resources; pwd)"
ICON="$DIR/AppIcon.icns"
PROCFILE="$DIR/proc"
ASSET_TAG=$(sed -e's/.local//; s/mac-//;' <<< $HOSTNAME)
FREE_SPACE=$(df -g / | awk '/\// {print $4}')
USERSNAME=$(id -F)
UPTIME=$(uptime)
source ~/.orgname

# clear old logs, or create a file for logging
[ -e "$TMPLOG" ] && echo > "$TMPLOG" || touch "$TMPLOG"

# generate a log entry
function logmsg() {
  # $1 = severity
  # $2 = message
  echo -e "$(date)\t$1\t$2" >> "$TMPLOG"
}

logmsg "INFO" "IT Help app launched"

# make sure the icon is accessible, else osascript farts out
[ -e "$ICON" ] && logmsg "INFO" "Icon lives at $ICON" || logmsg "ERROR" "Missing icon at $ICON"

# build the gui
# generates an alert box with 2 args, the user must click something to rid
function init_dialog() {

  CHOICE_BOX=$(osascript -e 'display dialog "'"$1\n\n$2"'" with icon POSIX file "'"$ICON"'" with title "Get IT Help" default answer "Describe your issue here" buttons {"Open Knowledgebase", "Close", "Submit as a Ticket"} default button "Submit as a Ticket"')
  logmsg "INFO" "Choice box data: $CHOICE_BOX"
  if [[ "$CHOICE_BOX"  = "button returned:Close"* ]];
  then
    logmsg "INFO" "Close button selected, exiting"
    exit 0
  elif [[ "$CHOICE_BOX" != *"text returned:Describe your issue here" ]];
  then
    logmsg "INFO" "$PROCFILE User is trying to submit a ticket, value: $CHOICE_BOX"
    logmsg "INFO" "Proc pre-launch" && $("$PROCFILE" "$FIRSTNAME" "$USERSNAME" "$ASSET_TAG" "$FREE_SPACE" "$UPTIME" "$ICON" "$CHOICE_BOX") && logmsg "INFO" "Proc post-launch"
    exit 0
  elif [[ "$CHOICE_BOX" =~ ^"button returned:Open Knowledgebase"* ]];
  then
    logmsg "INFO" "Knowledgebase base button selected"
    open "$KB" && logmsg "INFO" "Opened KB link"
  elif [[ "$CHOICE_BOX" =~ "text returned:Describe your issue here"$ ]];
  then
    logmsg "ERROR" "Nothing entered in the ticket create box, exiting, value: $CHOICE_BOX"
    osascript -e 'display dialog "Please describe your problem if you wish to submit a ticket.\n\nPlease re-run this app and try again." with icon POSIX file "'"$ICON"'" buttons {"OK"} with title "Error Submitting Your Ticket"'
    exit 0
  fi

  logmsg "INFO" "Default dialog displayed (init_dialog function)"
}


init_dialog "You can request IT assistance from this window.\n\nThe following info will also be sent with your message:\nAsset Tag:\t\t$ASSET_TAG\nFree Space:\t\t$FREE_SPACE GB" "\nOther ways to contact the Help Desk:\nEmail: "$HELPDESK_EMAIL"\nPhone: $HELPDESK_PHONE\n\nKnowledgebase & Announcements:\n$KB\n\n\nWhat do you need help with?"
