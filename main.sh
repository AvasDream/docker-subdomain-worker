#!/bin/bash
DOMAIN=$1
BASE_DIR="/root/$DOMAIN"
TOOLS_DIR='/root/tools'
echo $DOMAIN
function notify {
    python3 /code/message.py "$1" 
}

function amass-exec {
    amass enum --passive -d "$DOMAIN" -o "$BASE_DIR/amass-$DOMAIN.txt"
    num_domains=$(cat "$BASE_DIR/amass-$DOMAIN.txt" | wc -l)
    notify "amass - $DOMAIN - $num_domains"
}

function subfinder-exec {
    subfinder -d $DOMAIN -nC -o "$BASE_DIR/subfinder-$DOMAIN.txt" -silent -t 64 -timeout 10 -all &>> "$BASE_DIR/debug.txt"
}

function httpx-exec {
    httpx -silent -threads 64 -no-color -l "$BASE_DIR/amass-$DOMAIN.txt" -title -content-length -web-server -status-code -ports 80,81,443,4000,4001,4002,4433,8008,8080,8443,8888  -o "$BASE_DIR/httpx-$DOMAIN.txt"
}

function main {
    #amass-exec
    subfinder-exec
}

mkdir "$BASE_DIR"
{ time main ; } 2> time.txt
t=$(cat time.txt | grep real | cut -d " " -f2)
cp -r $BASE_DIR /data >> "$BASE_DIR/debug.txt"
ls -lah >> "$BASE_DIR/debug.txt"
DEBUG_CONTENT=$(cat "$BASE_DIR/debug.txt")
notify "Debug: $DEBUG_CONTENT"
notify "Enum for $DOMAIN - $t"


