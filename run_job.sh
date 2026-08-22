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

# ------------------------------------------------------------
# Validate arguments
# ------------------------------------------------------------

if [ -z "$JOB_NAME" ]; then
    log "RESULT=FAILED REASON=missing_job_name"
    exit 1
fi

if [ -z "$ACTION" ]; then
    log "JOB=$JOB_NAME RESULT=FAILED REASON=missing_action"
    exit 1
fi

# ------------------------------------------------------------
# Determine which shift this job belongs to
#
# monitor-support is NOT an HR shift job.
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

    monitor-support)
        REQUIRED_SHIFT=""
        ;;

    *)
        log "JOB=$JOB_NAME ACTION=$ACTION RESULT=FAILED REASON=unknown_job"
        exit 1
        ;;

esac

# ------------------------------------------------------------
# monitor-support runs independently of HR shift
# ------------------------------------------------------------

if [ "$JOB_NAME" = "monitor-support" ]; then

    log "JOB=$JOB_NAME ACTION=$ACTION RESULT=START INDEPENDENT_JOB=true"

else

    # --------------------------------------------------------
    # HR jobs require an active shift
    # --------------------------------------------------------

    if [ ! -f "$STATE_FILE" ]; then

        log "JOB=$JOB_NAME ACTION=$ACTION RESULT=SKIPPED REASON=no_active_shift"

        exit 0
    fi

    ACTIVE_SHIFT="$(cat "$STATE_FILE")"

    log "JOB=$JOB_NAME ACTION=$ACTION ACTIVE_SHIFT=$ACTIVE_SHIFT REQUIRED_SHIFT=$REQUIRED_SHIFT"

    # --------------------------------------------------------
    # Check active shift
    # --------------------------------------------------------

    if [ "$ACTIVE_SHIFT" != "$REQUIRED_SHIFT" ]; then

        log "JOB=$JOB_NAME ACTION=$ACTION RESULT=SKIPPED REQUIRED_SHIFT=$REQUIRED_SHIFT ACTIVE_SHIFT=$ACTIVE_SHIFT"

        exit 0
    fi

fi

# ------------------------------------------------------------
# Determine target container and command
# ------------------------------------------------------------

case "$ACTION" in

    signin)

        TARGET_CONTAINER="auto-hr"

        COMMAND="python /app/signin.py"

        ;;

    signout)

        TARGET_CONTAINER="auto-hr"

        COMMAND="python /app/signout.py"

        ;;

    monitor)

        TARGET_CONTAINER="monitor_support"

        COMMAND="python /root/ocr_extraction/monitor_support/main.py"

        ;;

    *)

        log "JOB=$JOB_NAME ACTION=$ACTION RESULT=FAILED REASON=unknown_action"

        exit 1

        ;;

esac

# ------------------------------------------------------------
# Execute command inside the existing container
# ------------------------------------------------------------

log "JOB=$JOB_NAME ACTION=$ACTION RESULT=START TARGET_CONTAINER=$TARGET_CONTAINER COMMAND=$COMMAND"

if docker exec "$TARGET_CONTAINER" sh -c "$COMMAND" >> "$LOG_FILE" 2>&1; then

    log "JOB=$JOB_NAME ACTION=$ACTION RESULT=SUCCESS TARGET_CONTAINER=$TARGET_CONTAINER"

else

    EXIT_CODE=$?

    log "JOB=$JOB_NAME ACTION=$ACTION RESULT=FAILED TARGET_CONTAINER=$TARGET_CONTAINER EXIT_CODE=$EXIT_CODE"

    exit "$EXIT_CODE"

fi