#!/bin/bash

set -u

STATE_FILE="/scheduler/state/active_shift"
LOG_DIR="/var/log/auto-hr"

mkdir -p "$LOG_DIR"

JOB_NAME="${1:-}"
ACTION="${2:-}"

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"

LOG_FILE="$LOG_DIR/${ACTION}.log"

log() {
    echo "[$TIMESTAMP] $*" >> "$LOG_FILE"
}

if [ ! -f "$STATE_FILE" ]; then
    log "JOB=$JOB_NAME ACTION=$ACTION RESULT=SKIPPED REASON=no_active_shift"
    exit 0
fi

ACTIVE_SHIFT="$(cat "$STATE_FILE")"

log "JOB=$JOB_NAME ACTION=$ACTION ACTIVE_SHIFT=$ACTIVE_SHIFT"

# ------------------------------------------------------------
# Determine which shift this job belongs to
# ------------------------------------------------------------

case "$JOB_NAME" in

    5am-*)
        REQUIRED_SHIFT="5am"
        ;;

    1pm-*)
        REQUIRED_SHIFT="1pm"
        ;;

    6pm-*)
        REQUIRED_SHIFT="6pm"
        ;;

    *)
        log "RESULT=FAILED REASON=unknown_job"
        exit 1
        ;;

esac

# ------------------------------------------------------------
# Check active shift
# ------------------------------------------------------------

if [ "$ACTIVE_SHIFT" != "$REQUIRED_SHIFT" ]; then

    log "RESULT=SKIPPED REQUIRED_SHIFT=$REQUIRED_SHIFT"

    exit 0
fi

# ------------------------------------------------------------
# Execute inside the EXISTING auto-hr container
# ------------------------------------------------------------

case "$ACTION" in

    signin)
        COMMAND="python /app/signin.py"
        ;;

    signout)
        COMMAND="python /app/signout.py"
        ;;

    *)
        log "RESULT=FAILED REASON=unknown_action"
        exit 1
        ;;

esac

log "RESULT=START COMMAND=$COMMAND"

if docker exec auto-hr $COMMAND >> "$LOG_FILE" 2>&1; then

    log "RESULT=SUCCESS"

else

    EXIT_CODE=$?

    log "RESULT=FAILED EXIT_CODE=$EXIT_CODE"

    exit "$EXIT_CODE"

fi