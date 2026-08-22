#!/bin/bash

# ============================================================
# Auto HR Scheduler - Combined Log Viewer
# ============================================================

SCHEDULER_CONTAINER="auto-hr-scheduler"
MONITOR_CONTAINER="monitor_support"

echo
echo "============================================================"
echo "          AUTO HR SCHEDULER - STATUS & LOGS"
echo "============================================================"
echo

# ------------------------------------------------------------
# 1. CURRENT SHIFT
# ------------------------------------------------------------

echo "-------------------- CURRENT SHIFT -------------------------"

SHIFT=$(docker exec "$SCHEDULER_CONTAINER" \
    sh -c 'cat /scheduler/state/active_shift 2>/dev/null || echo "UNKNOWN"')

echo "Active Shift : $SHIFT"

echo
echo "------------------------------------------------------------"
echo

# ------------------------------------------------------------
# 2. CONTAINER STATUS
# ------------------------------------------------------------

echo "-------------------- CONTAINER STATUS ----------------------"

docker ps \
    --filter "name=$SCHEDULER_CONTAINER" \
    --filter "name=$MONITOR_CONTAINER" \
    --format "Container: {{.Names}} | Status: {{.Status}}"

echo
echo "------------------------------------------------------------"
echo

# ------------------------------------------------------------
# 3. OFELIA SCHEDULER ACTIVITY
# ------------------------------------------------------------

echo "-------------------- OFELIA SCHEDULER ----------------------"

docker logs "$SCHEDULER_CONTAINER" 2>&1 |
    grep -E 'Job ".*" (Started|Finished)|Starting scheduler' |
    tail -30

echo
echo "------------------------------------------------------------"
echo

# ------------------------------------------------------------
# 4. HR SIGN-IN LOG
# ------------------------------------------------------------

echo "-------------------- HR SIGN-IN LOG ------------------------"

if docker exec "$SCHEDULER_CONTAINER" \
    test -f /var/log/auto-hr/signin.log; then

    docker exec "$SCHEDULER_CONTAINER" \
        tail -30 /var/log/auto-hr/signin.log

else

    echo "No signin.log found."

fi

echo
echo "------------------------------------------------------------"
echo

# ------------------------------------------------------------
# 5. HR SIGN-OUT LOG
# ------------------------------------------------------------

echo "-------------------- HR SIGN-OUT LOG -----------------------"

if docker exec "$SCHEDULER_CONTAINER" \
    test -f /var/log/auto-hr/signout.log; then

    docker exec "$SCHEDULER_CONTAINER" \
        tail -30 /var/log/auto-hr/signout.log

else

    echo "No signout.log found."

fi

echo
echo "------------------------------------------------------------"
echo

# ------------------------------------------------------------
# 6. MONITOR SUPPORT LOG
# ------------------------------------------------------------

echo "-------------------- MONITOR SUPPORT -----------------------"

if docker exec "$SCHEDULER_CONTAINER" \
    test -f /var/log/auto-hr/monitor.log; then

    docker exec "$SCHEDULER_CONTAINER" \
        tail -30 /var/log/auto-hr/monitor.log

else

    echo "No monitor.log found."

fi

echo
echo "------------------------------------------------------------"
echo

# ------------------------------------------------------------
# 7. MONITOR SUPPORT CONTAINER
# ------------------------------------------------------------

echo "---------------- MONITOR SUPPORT CONTAINER -----------------"

docker ps \
    --filter "name=$MONITOR_CONTAINER" \
    --format "Container: {{.Names}} | Status: {{.Status}}"

echo
echo "------------------------------------------------------------"
echo

# ------------------------------------------------------------
# 8. SUMMARY
# ------------------------------------------------------------

echo "------------------------- SUMMARY --------------------------"

echo "Current Shift       : $SHIFT"

echo "Scheduler Container : $(docker inspect -f '{{.State.Status}}' "$SCHEDULER_CONTAINER" 2>/dev/null || echo "NOT FOUND")"

echo "Monitor Container   : $(docker inspect -f '{{.State.Status}}' "$MONITOR_CONTAINER" 2>/dev/null || echo "NOT FOUND")"

echo
echo "============================================================"
echo "                    END OF LOG REPORT"
echo "============================================================"
echo