#!/bin/bash

NC='\033[0m' # No Color

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

BG_BLACK='\033[0;40m'
BG_RED='\033[0;41m'
BG_GREEN='\033[0;42m'
BG_YELLOW='\033[0;43m'
BG_BLUE='\033[0;44m'
BG_MAGENTA='\033[0;45m'
BG_CYAN='\033[0;46m'
BG_WHITE='\033[0;47m'

# ###############################################################################################
echo -n "Checking dependencies..."

dialog_test=$(command -v dialog)

if [ ! $dialog_test ]; then
    echo
    echo "dialog is not installed."
    exit
fi
echo " Done."

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
TITLE="PickleBook Tool"
MENU="Choose one of the following operations:"

OPTIONS=(1 "STOP"
    2 "(RE)START"
    3 "UPGRADE"
    4 "PRUNE (safe)"
    9 "Quit")

CHOICE=$(dialog --clear \
    --title "$TITLE" \
    --menu "$MENU" \
    $HEIGHT $WIDTH $CHOICE_HEIGHT \
    "${OPTIONS[@]}" \
    2>&1 >/dev/tty)

case $CHOICE in
1)
    operation="STOP"
    ;;
2)
    operation="RESTART"
    ;;
3)
    operation="UPGRADE"
    ;;
4)
    operation="PRUNE"
    ;;
9 | *)
    clear
    exit
    ;;
esac


if [ $operation = "PRUNE" ]; then
    clear
    echo "Pruning unused images..."
    docker image prune -af
    exit
fi

if [ "$operation" != "UPGRADE" ]; then

    MENU="Which components?"

    OPTIONS=(1 "ALL"
        2 "STORAGE"
        3 "WORKERS"
        4 "APP"
        5 "DMZ"
        6 "METRICS"
        7 "MAILPIT"
        9 "Quit")

    CHOICE=$(dialog --clear \
        --title "$TITLE" \
        --menu "$MENU" \
        $HEIGHT $WIDTH $CHOICE_HEIGHT \
        "${OPTIONS[@]}" \
        2>&1 >/dev/tty)

    case $CHOICE in
    1)
        component="ALL"
        ;;
    2)
        component="storage"
        ;;
    3)
        component="workers"
        ;;
    4)
        component="app"
        ;;
    5)
        component="dmz"
        ;;
    6)
        component="metrics"
        ;;
    7)
        component="mailpit"
        ;;
    9 | *)
        clear
        exit
        ;;
    esac
fi

clear

read -p "Are you sure you want to perform $operation on $component? (YES to proceed) : " choice
if [ "${choice,,}" != "yes" ]; then
    echo "Cancelled."
    exit
fi

if [ $operation = "STOP" ]; then
    if [ $component = "ALL" ]; then

        $(docker compose -f docker-compose-master-metrics.yml down)
        $(docker compose -f docker-compose-master-dmz.yml down)
        $(docker compose -f docker-compose-master-workers.yml down)
        $(docker compose -f docker-compose-master-app.yml down)
        $(docker compose -f docker-compose-master-storage.yml down)
        $(docker compose -f docker-compose-master-mailpit.yml down)

    else

        $(docker compose -f docker-compose-master-$component.yml down)
    fi
    echo "Complete."
    exit
fi

if [ $operation = "UPGRADE" ]; then

    rm -rf picklebook-bootstrap

    git clone https://github.com/picklebook/picklebook-bootstrap.git --depth=1 -q

    hash1=`md5sum picklebook-bootstrap/pbtool.sh | cut -d" " -f1`
    hash2=`md5sum pbtool.sh | cut -d" " -f1`
    
    cp picklebook-bootstrap/docker-compose-master-* .
    cp picklebook-bootstrap/*.yaml .
    cp picklebook-bootstrap/*.sh .
    chmod +x *.sh

    if [ $hash1 != $hash2 ]; then
        cp picklebook-bootstrap/pbtool.sh .
        echo "PBTools has been updated, please run again."
        exit
    fi

    $(docker compose -f docker-compose-master-storage.yml pull)
    $(docker compose -f docker-compose-master-workers.yml pull)
    $(docker compose -f docker-compose-master-app.yml pull)
    $(docker compose -f docker-compose-master-dmz.yml pull)
    $(docker compose -f docker-compose-master-metrics.yml pull)
    $(docker compose -f docker-compose-master-mailpit.yml pull)

    $(docker compose -f docker-compose-master-storage.yml up -d --remove-orphans)
    $(docker compose -f docker-compose-master-workers.yml up -d --remove-orphans)
    $(docker compose -f docker-compose-master-app.yml up -d --remove-orphans)
    $(docker compose -f docker-compose-master-dmz.yml up -d --remove-orphans)
    $(docker compose -f docker-compose-master-metrics.yml up -d --remove-orphans)
    $(docker compose -f docker-compose-master-mailpit.yml up -d --remove-orphans)

    echo "Pruning unused images..."
    docker image prune -af
    echo "Complete."
    exit
fi

if [ $operation = "RESTART" ]; then
    if [ $component = "ALL" ]; then

        $(docker compose -f docker-compose-master-storage.yml down)
        $(docker compose -f docker-compose-master-storage.yml up -d --remove-orphans)

        $(docker compose -f docker-compose-master-workers.yml down)
        $(docker compose -f docker-compose-master-workers.yml up -d --remove-orphans)

        $(docker compose -f docker-compose-master-app.yml down)
        $(docker compose -f docker-compose-master-app.yml up -d --remove-orphans)

        $(docker compose -f docker-compose-master-dmz.yml down)
        $(docker compose -f docker-compose-master-dmz.yml up -d --remove-orphans)

        $(docker compose -f docker-compose-master-metrics.yml down)
        $(docker compose -f docker-compose-master-metrics.yml up -d --remove-orphans)

        $(docker compose -f docker-compose-master-mailpit.yml down)
        $(docker compose -f docker-compose-master-mailpit.yml up -d --remove-orphans)

    else
        $(docker compose -f docker-compose-master-$component.yml down)
        $(docker compose -f docker-compose-master-$component.yml up -d --remove-orphans)
    fi
    echo "Complete."
    exit
fi
