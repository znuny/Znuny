#!/bin/sh
# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

CURRENTUSER=`whoami`
CRON_USER="$2"

# check if a common user try to use -u
if test -n "$CRON_USER"; then
    if test $CURRENTUSER != root; then
        echo "Run this script just as OTRS user! Or use 'Cron.sh {start|stop|restart} OTRS_USER' as root!"
        exit 5
    fi
fi

# check if the cron user is specified
if test -z "$CRON_USER"; then
    if test $CURRENTUSER = root; then
        echo "Run this script just as OTRS user! Or use 'Cron.sh {start|stop|restart} OTRS_USER' as root!"
        exit 5
    fi
fi

# find otrs root
cd "`dirname $0`/../"
OTRS_HOME="`pwd`"

#OTRS_ROOT=/opt/znuny
if test -e $OTRS_HOME/var/cron; then
    OTRS_ROOT=$OTRS_HOME
else
    echo "No cronjobs in $OTRS_HOME/var/cron found!";
    echo " * Check the \$HOME (/etc/passwd) of the OTRS user. It must be the root dir of your OTRS system (e. g. /opt/znuny). ";
    exit 5;
fi

CRON_DIR=$OTRS_ROOT/var/cron
CRON_TMP_FILE=$OTRS_ROOT/var/tmp/otrs-cron-tmp.$$

#
# main part
#
case "$1" in
    # ------------------------------------------------------
    # start
    # ------------------------------------------------------
    start)
        # add -u to cron user if user exists
        if test -n "$CRON_USER"; then
            CRON_USER=" -u $CRON_USER"
        fi

        if mkdir -p $CRON_DIR; cd $CRON_DIR && ls -d * | grep -Ev "(\.(dist|rpm|rpmnew|bak|backup|custom_backup|save|swp)|~)$" | xargs cat > $CRON_TMP_FILE && crontab $CRON_USER $CRON_TMP_FILE; then

            rm -rf $CRON_TMP_FILE
            echo "(using $OTRS_ROOT) done";
            exit 0;
        else
            echo "failed";
            exit 1;
        fi
    ;;
    # ------------------------------------------------------
    # stop
    # ------------------------------------------------------
    stop)
        # add -u to cron user if user exists
        if test -n "$CRON_USER"; then
            CRON_USER=" -u $CRON_USER"
        fi

        if crontab $CRON_USER -r ; then
            echo "done";
            exit 0;
        else
            echo "failed";
            exit 1;
        fi
    ;;
    # ------------------------------------------------------
    # restart
    # ------------------------------------------------------
    restart)
        $0 stop "$CRON_USER"
        $0 start "$CRON_USER"
    ;;
    # ------------------------------------------------------
    # Usage
    # ------------------------------------------------------
    *)
    cat - <<HELP

Manage OTRS cron jobs.

Usage:
 Cron.sh [action]

Arguments:
 [action]                      - 'start', 'stop' or 'restart' - activate or deactivate OTRS cron jobs.
HELP

    exit 1
esac
