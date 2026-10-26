# Auto HR Scheduler

Docker-based scheduler for the Auto HR `signin.py` and `signout.py` jobs using Ofelia.

The scheduler runs independently from the existing `auto-hr` container.

## Architecture

```text
Host
 │
 ├── shift.sh
 │
 └── auto-hr-scheduler
        │
        └── Ofelia
              │
              └── docker exec
                     │
                     ▼
                 auto-hr
                     │
                     ├── signin.py
                     └── signout.py
```

### Important

The `auto-hr` container is the application/worker container.

The `auto-hr-scheduler` container is responsible only for scheduling.

Changing shifts does **not** restart, recreate, rebuild, or modify the `auto-hr` container.

All scheduler times are configured in **Asia/Kolkata (IST)**.

---

# Directory Structure

```text
auto-hr-scheduler/
│
├── docker-compose.yml
├── shift.sh
├── run_job.sh
│
├── scheduler/
│   ├── ofelia.ini
│   └── state/
│       └── active_shift
│
└── logs/
    └── scheduler/
```

---

# Prerequisites

Make sure Docker and Docker Compose are available:

```bash
docker --version
docker compose version
```

Make sure the existing Auto HR container is running:

```bash
docker ps --filter name=auto-hr
```

Expected:

```text
auto-hr
```

Do not stop or recreate the existing `auto-hr` container.

---

# Start the Scheduler

Go to the scheduler project directory:

```bash
cd /home/hr306/mygitrepos/auto-hr-scheduler
```

Create required directories:

```bash
mkdir -p scheduler/state
mkdir -p logs/scheduler
```

Make the scripts executable:

```bash
chmod +x shift.sh
chmod +x run_job.sh
```

Start the scheduler:

```bash
docker compose up -d
```

If the scheduler image or configuration has changed and you need to rebuild:

```bash
docker compose up -d --build
```

Check running containers:

```bash
docker ps
```

You should see both:

```text
auto-hr
auto-hr-scheduler
```

---

# Check Scheduler Logs

View scheduler logs:

```bash
docker logs auto-hr-scheduler
```

Follow scheduler logs:

```bash
docker logs -f auto-hr-scheduler
```

View the last 100 lines:

```bash
docker logs --tail 100 auto-hr-scheduler
```

A healthy main scheduler should show:

```text
Starting scheduler with 13 jobs
```

## Tracker Reminder Job

The tracker reminder is an independent Ofelia `job-exec` entry in
`scheduler/ofelia.ini`. Its settings are:

```ini
schedule = 0 0 18 * * 1-5
container = tracker-reminder
command = python /app/tracker_reminder.py
```

Ofelia runs the command inside the existing `tracker-reminder` container at
18:00 IST Monday through Friday. Restart the scheduler after changing the
configuration:

```bash
docker restart auto-hr-scheduler
```

The `tracker-reminder` container must be running when the schedule fires.

---

# Check Time

The scheduler runs using IST.

Check scheduler time:

```bash
docker exec auto-hr-scheduler date '+%Y-%m-%d %H:%M:%S %Z %z'
```

Check Auto HR time:

```bash
docker exec auto-hr date '+%Y-%m-%d %H:%M:%S %Z %z'
```

Expected timezone:

```text
IST +0530
```

The host machine may use a different timezone. This does not affect the Ofelia schedule because the scheduler container uses:

```text
Asia/Kolkata
```

---

# Shift Control

`shift.sh` controls which shift is currently active.

## Enable 5 AM Shift

```bash
./shift.sh 5am
```

Schedule:

```text
05:00 IST  Sign In
05:10 IST  Sign In

10:05 IST  Sign In

14:00 IST  Sign Out
14:10 IST  Sign Out
```

The duplicate sign-ins are intentional because the HR portal resets at 09:00.

---

## Enable 1 PM Shift

```bash
./shift.sh 1pm
```

Schedule:

```text
12:55 IST  Sign In
13:05 IST  Sign In

22:15 IST  Sign Out
22:25 IST  Sign Out
```

---

## Enable 6 PM - 4 AM Shift

```bash
./shift.sh 6pm
```

Schedule:

```text
18:00 IST  Sign In
04:00 IST  Sign Out
```

The 04:00 sign-out occurs on the following calendar day.

---

# Disable Auto HR Scheduling

To disable all scheduled Auto HR executions:

```bash
./shift.sh off
```

This does not stop the containers.

It only changes the active shift to:

```text
off
```

Ofelia continues running, but all Auto HR jobs are skipped.

---

# Check Current Shift

```bash
./shift.sh status
```

Example:

```text
==============================================
             AUTO HR STATUS
==============================================
Status       : ON
Active shift : 5 AM - 2 PM
State        : 5am
Time         : 2026-08-10 21:00:00 IST +0530
==============================================
```

Possible states:

```text
5am
1pm
6pm
off
```

---

# Check Active Shift Directly

The current state is stored in:

```text
scheduler/state/active_shift
```

Check it:

```bash
cat scheduler/state/active_shift
```

Check the state from inside the scheduler container:

```bash
docker exec auto-hr-scheduler cat /scheduler/state/active_shift
```

Both should return the same value.

---

# Scheduler Jobs

Ofelia contains 13 jobs: 11 HR jobs, the independent monitor-support job, and
the independent tracker reminder job described above.

## 5 AM Shift

```text
05:00  Sign In
05:10  Sign In
10:05  Sign In
14:00  Sign Out
14:10  Sign Out
```

## 1 PM Shift

```text
12:55  Sign In
13:05  Sign In
22:15  Sign Out
22:25  Sign Out
```

## 6 PM - 4 AM Shift

```text
18:00  Sign In
04:00  Sign Out
```

All times are IST.

`monitor-support` runs every 45 minutes inside the existing `monitor_support`
container, using a direct `job-exec` entry in `scheduler/ofelia.ini`. It does
not depend on the active HR shift.

---

# How Shift Selection Works

All 13 jobs remain registered with the main Ofelia scheduler.

For example, if:

```text
active_shift = 5am
```

then:

```text
5 AM jobs     → EXECUTE
1 PM jobs     → SKIP
6 PM jobs     → SKIP
```

If:

```text
active_shift = 1pm
```

then:

```text
5 AM jobs     → SKIP
1 PM jobs     → EXECUTE
6 PM jobs     → SKIP
```

If:

```text
active_shift = 6pm
```

then:

```text
5 AM jobs     → SKIP
1 PM jobs     → SKIP
6 PM jobs     → EXECUTE
```

If:

```text
active_shift = off
```

then:

```text
ALL jobs      → SKIP
```

---

# Logging

Scheduler logs:

```bash
docker logs auto-hr-scheduler
```

Execution logs are stored under:

```text
logs/scheduler/
```

Check the log directory:

```bash
ls -lah logs/scheduler
```

Follow scheduler output:

```bash
docker logs -f auto-hr-scheduler
```

---

# Test Auto HR Execution Manually

The scheduler normally executes:

```bash
python /app/signin.py
```

or:

```bash
python /app/signout.py
```

inside the existing `auto-hr` container.

To manually test sign-in:

```bash
docker exec -it auto-hr python /app/signin.py
```

To manually test sign-out:

```bash
docker exec -it auto-hr python /app/signout.py
```

These commands execute the scripts inside the already-running container.

---

# Verify the Auto HR Container

Check:

```bash
docker ps --filter name=auto-hr
```

Inspect its start time:

```bash
docker inspect -f '{{.State.StartedAt}}' auto-hr
```

The scheduler should never restart this container.

---

# Scheduler Restart

If only the scheduler needs to be restarted:

```bash
docker restart auto-hr-scheduler
```

This does **not** restart `auto-hr`.

---

# Scheduler Rebuild

If the scheduler Dockerfile or scheduler image needs to be rebuilt:

```bash
docker compose build --no-cache
```

Then:

```bash
docker compose up -d
```

This operation is for the scheduler only.

The Compose project should not contain the `auto-hr` service.

---

# Stop the Scheduler

To stop only the scheduler:

```bash
docker compose stop
```

To remove only the scheduler container:

```bash
docker compose down
```

This does not remove the separately running `auto-hr` container.

Afterward, start the scheduler again:

```bash
docker compose up -d
```

---

# Quick Operational Commands

### Check current shift

```bash
./shift.sh status
```

### Enable 5 AM

```bash
./shift.sh 5am
```

### Enable 1 PM

```bash
./shift.sh 1pm
```

### Enable 6 PM - 4 AM

```bash
./shift.sh 6pm
```

### Disable scheduling

```bash
./shift.sh off
```

### Check scheduler

```bash
docker ps --filter name=auto-hr-scheduler
```

### Check scheduler logs

```bash
docker logs --tail 100 auto-hr-scheduler
```

### Follow scheduler logs

```bash
docker logs -f auto-hr-scheduler
```

### Check scheduler time

```bash
docker exec auto-hr-scheduler date '+%Y-%m-%d %H:%M:%S %Z %z'
```

### Check active shift inside scheduler

```bash
docker exec auto-hr-scheduler cat /scheduler/state/active_shift
```

### Manually test sign-in

```bash
docker exec -it auto-hr python /app/signin.py
```

### Manually test sign-out

```bash
docker exec -it auto-hr python /app/signout.py
```

---

# Important Safety Rule

Do not use the following commands from this scheduler project if the Compose file is ever changed to include the `auto-hr` service:

```bash
docker compose down
docker compose up -d --build
docker compose restart
```

The scheduler is intentionally isolated from the existing `auto-hr` container.

The intended architecture is:

```text
auto-hr
    │
    └── Long-running worker
        └── NEVER restarted by scheduler

auto-hr-scheduler
    │
    └── Ofelia
        └── Owns all schedules

shift.sh
    │
    └── Selects active shift
```

The normal daily operation is therefore only:

```bash
./shift.sh 5am
```

or:

```bash
./shift.sh 1pm
```

or:

```bash
./shift.sh 6pm
```

or:

```bash
./shift.sh off
```

and:

```bash
./shift.sh status
```


docker exec auto-hr-scheduler cat /scheduler/state/active_shift
docker exec auto-hr-scheduler sh -c 'echo "Active shift: $(cat /scheduler/state/active_shift)"'
cat scheduler/state/active_shift

activate a shift:
./shift.sh 1pm

verify status: 
./shift.sh status


get logs 

docker exec auto-hr-scheduler ls -lah /var/log/auto-hr/
docker exec auto-hr-scheduler cat /var/log/auto-hr/shift-1pm.log
docker exec auto-hr-scheduler cat /var/log/auto-hr/signin.log
docker exec auto-hr-scheduler cat /var/log/auto-hr/signout.log

docker exec auto-hr-scheduler grep -E '1pm|ACTIVE_SHIFT' /var/log/auto-hr/signin.log /var/log/auto-hr/signout.log

docker exec auto-hr-scheduler cat /scheduler/state/active_shift

docker exec auto-hr-scheduler cat /var/log/auto-hr/monitor.log

docker exec auto-hr-scheduler cat /var/log/auto-hr/monitor.log
