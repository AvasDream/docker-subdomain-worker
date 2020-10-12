#!/bin/bash
DOMAIN=$1
BASE_DIR="/root/$DOMAIN"
TOOLS_DIR='/root/tools'
MESSAGE=""
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
    subfinder -d $DOMAIN -nC -o "$BASE_DIR/subfinder-$DOMAIN.txt" -silent -t 64 -timeout 10 -all 
    num_domains=$(cat "$BASE_DIR/subfinder-$DOMAIN.txt" | wc -l)
    notify "subfinder - $DOMAIN - $num_domains"
}

function aiodns-exec {
    aiodnsbrute -r /root/dns_resolver.txt -w /root/sublist.txt -t 64 -o json -f "$BASE_DIR/aiodns-$DOMAIN.json" $DOMAIN 
    python3 /code/aioparse.py "$BASE_DIR/aiodns-$DOMAIN.json" "$BASE_DIR/aiodns-$DOMAIN.txt" 
    rm -rf "$BASE_DIR/aiodns-$DOMAIN.json"
    num_domains=$(cat "$BASE_DIR/aiodns-$DOMAIN.txt" | wc -l)
    notify "aiodns - $DOMAIN - $num_domains"
}

function merge-exec {
    cat "$BASE_DIR/aiodns-$DOMAIN.txt" > "$BASE_DIR/tmp.txt"
    cat "$BASE_DIR/subfinder-$DOMAIN.txt" >> "$BASE_DIR/tmp.txt"
    cat "$BASE_DIR/amass-$DOMAIN.txt" >> "$BASE_DIR/tmp.txt"
    l1=$(cat "$BASE_DIR/tmp.txt" | wc -l)
    cat "$BASE_DIR/tmp.txt" | sort -u > "$BASE_DIR/final.txt"
    l2=$(cat "$BASE_DIR/final.txt" | wc -l)
    notify "All: $l1 - Unique: $l2"
    echo "All: $l1 - Unique: $l2" > "$BASE_DIR/count.txt"
}

function parse-live {
    cat "$BASE_DIR/httpx-$DOMAIN.txt" | cut -d " " -f1
}
function main {
    amass-exec
    subfinder-exec
    aiodns-exec
    merge-exec
    httpx-exec
    parse-live
}

mkdir "$BASE_DIR"
{ time main ; } 2> time.txt
t=$(cat time.txt | grep real | cut -d " " -f2)
cp -r $BASE_DIR /data &>> "$BASE_DIR/debug.txt"
DEBUG_CONTENT=$(cat "$BASE_DIR/debug.txt")
notify "Enum for $DOMAIN in $t"


