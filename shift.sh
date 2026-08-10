#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STATE_DIR="$PROJECT_DIR/scheduler/state"
STATE_FILE="$STATE_DIR/active_shift"

mkdir -p "$STATE_DIR"

set_shift() {

    local SHIFT="$1"

    case "$SHIFT" in

        5am)
            DESCRIPTION="5 AM - 2 PM"
            ;;

        1pm)
            DESCRIPTION="1 PM shift"
            ;;

        6pm)
            DESCRIPTION="6 PM - 4 AM"
            ;;

        off)
            DESCRIPTION="OFF"
            ;;

        *)
            echo
            echo "Invalid shift: $SHIFT"
            echo
            echo "Usage:"
            echo "  $0 5am"
            echo "  $0 1pm"
            echo "  $0 6pm"
            echo "  $0 off"
            echo "  $0 status"
            exit 1
            ;;
    esac

    # Atomic state update.
    echo "$SHIFT" > "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"

    echo
    echo "=============================================="
    echo "             AUTO HR SHIFT"
    echo "=============================================="
    echo "Active shift : $DESCRIPTION"
    echo "State        : $SHIFT"
    echo "Time         : $(TZ=Asia/Kolkata date '+%Y-%m-%d %H:%M:%S %Z %z')"
    echo "=============================================="
    echo
}

status() {

    echo
    echo "=============================================="
    echo "             AUTO HR STATUS"
    echo "=============================================="

    if [ ! -f "$STATE_FILE" ]; then
        echo "Status       : OFF"
        echo "Active shift : off"
    else

        ACTIVE_SHIFT="$(cat "$STATE_FILE")"

        case "$ACTIVE_SHIFT" in

            5am)
                DESCRIPTION="5 AM - 2 PM"
                ;;

            1pm)
                DESCRIPTION="1 PM shift"
                ;;

            6pm)
                DESCRIPTION="6 PM - 4 AM"
                ;;

            off)
                DESCRIPTION="OFF"
                ;;

            *)
                DESCRIPTION="UNKNOWN"
                ;;
        esac

        if [ "$ACTIVE_SHIFT" = "off" ]; then
            STATUS="OFF"
        else
            STATUS="ON"
        fi

        echo "Status       : $STATUS"
        echo "Active shift : $DESCRIPTION"
        echo "State        : $ACTIVE_SHIFT"
    fi

    echo "Time         : $(TZ=Asia/Kolkata date '+%Y-%m-%d %H:%M:%S %Z %z')"
    echo "=============================================="
    echo
}

case "${1:-}" in

    5am)
        set_shift 5am
        ;;

    1pm)
        set_shift 1pm
        ;;

    6pm)
        set_shift 6pm
        ;;

    off)
        set_shift off
        ;;

    status)
        status
        ;;

    *)
        echo
        echo "Usage:"
        echo
        echo "  $0 5am"
        echo "  $0 1pm"
        echo "  $0 6pm"
        echo "  $0 off"
        echo "  $0 status"
        echo
        exit 1
        ;;
esac