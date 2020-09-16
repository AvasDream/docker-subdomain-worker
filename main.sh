#!/bin/bash
DOMAIN=$1
BASE_DIR="/root/$DOMAIN"
TOOLS_DIR='/root/tools'

function notify {
    python3 /code/message.py "$1"
}

function amass-exec {
    #amass enum --passive -d "$DOMAIN" -o "$baseDir/amass-$DOMAIN.txt" 
    amass --version
}

function httpx-exec {
    httpx -silent -threads 64 -no-color -l "$baseDir/amass-$DOMAIN.txt" -title -content-length -web-server -status-code -ports 80,81,443,4000,4001,4002,4433,8008,8080,8443,8888  -o "$baseDir/httpx-$DOMAIN.txt"
}

function main {
    amass-exec
}
start_time=`date +%s`
mkdir "$BASEDIR"
main 
end=`date +%s`
runtime=$((end-start))
notify "Finished $DOMAIN - $runtime"


