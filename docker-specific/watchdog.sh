#!/bin/sh
set -eu

ZNUNY_HOME="/opt/znuny"
cd "$ZNUNY_HOME"

echo 'Checking modules...'
$ZNUNY_HOME/bin/znuny.CheckModules.pl --all

echo 'Starting Watchdog.'

CHECK_INTERVAL=30   # seconds
MAX_FAILS=10        # 10 × 30s = 5 minutes

FAILS=0
DAEMON="/opt/znuny-dev/bin/znuny.Daemon.pl"

term_handler() {
    echo "Received termination signal, stopping Znuny"
    perl "$DAEMON" stop || true
    exit 0
}

trap term_handler INT TERM

echo "Znuny supervisor started"
perl "$DAEMON" start || true

while true; do
    if perl "$DAEMON" status | grep -q "Daemon running"; then
        FAILS=0
    else
        FAILS=$((FAILS + 1))
        echo "Znuny not running ($FAILS/$MAX_FAILS)"
    fi

    if [ "$FAILS" -ge "$MAX_FAILS" ]; then
        echo "Znuny down for 5 minutes — exiting container"
        exit 1
    fi

    sleep "$CHECK_INTERVAL"
done
