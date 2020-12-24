#!/bin/bash

function display-help {
    echo "$(history | tail -1)"
    echo "Usage:"
    echo "-d|--domain \"hackerone.com\", required, domain to enumerate."
    echo "-n|--notify, optional, enable telegram notification."
    echo "-c|--chat_id \"1337531337\", required if notifacations are enables, telegram chat id."
    echo "-s|--secret_token \"XXXXXXXXXXXXXXX\", required if notifacations are enables, telegram api token."
    echo "--help, display this help message."
    echo "Example 1: docker run -it --rm -v \"\$(pwd):/data\" subs --domain hackerone.com"
    echo "Example 2: docker run -it --rm -v \"\$(pwd):/data\" subs --domain hackerone.com --notify --chat_id XXXX --secret_token XXXX"
    echo "Note: Arguments must be supplied in the exakt same order as above. This is due to lazy."
    exit 1
}
trap 'display-help' ERR
#Argument Parsing
while [[ $# > 0 ]]
do
    case "$1" in
        -d|--domain)
                DOMAIN="$2"
                shift
                ;;
        -c|--chat_id)
                CHAT_ID="$2"
                shift
                ;;
        -s|--secret_token)
                SECRET_TOKEN="$2"
                shift
                ;;
        -n|--notify)
                NOTIFICATION=true
                shift
                ;;
        --help)
                display-help
                exit 1
                ;;
    esac
    shift
done

DATE=$(date +%d.%m.%y-%H:%M)
BASE_DIR="/root/$DOMAIN-$DATE"
TOOLS_DIR='/root/tools'
MESSAGE=""
echo "[+] Enumerate $DOMAIN"

function amass-exec {
    amass enum --passive -d "$DOMAIN" -o "$BASE_DIR/amass-$DOMAIN.txt" &> /dev/null
}

function subfinder-exec {
    subfinder -d $DOMAIN -nC -o "$BASE_DIR/subfinder-$DOMAIN.txt" -silent -t 64 -timeout 10 -all &> /dev/null
}

function aiodns-exec {
    aiodnsbrute -r /root/dns_resolver.txt -w /root/sublist.txt -t 64 -o json -f "$BASE_DIR/aiodns-$DOMAIN.json" $DOMAIN &> /dev/null
    python3 /code/aioparse.py "$BASE_DIR/aiodns-$DOMAIN.json" "$BASE_DIR/aiodns-$DOMAIN.txt" &> /dev/null
    rm -rf "$BASE_DIR/aiodns-$DOMAIN.json"
}

function crtsh-exec {
    curl -s https://crt.sh/?q=%25.$DOMAIN | grep "$DOMAIN" | grep "<TD>" | cut -d">" -f2 | cut -d"<" -f1 | sort -u | sed s/*.//g > "$BASE_DIR/crtsh-$DOMAIN.txt"
}

function merge-exec {
    cat "$BASE_DIR/aiodns-$DOMAIN.txt" > "$BASE_DIR/tmp.txt"
    cat "$BASE_DIR/subfinder-$DOMAIN.txt" >> "$BASE_DIR/tmp.txt"
    cat "$BASE_DIR/amass-$DOMAIN.txt" >> "$BASE_DIR/tmp.txt"
    cat "$BASE_DIR/crtsh-$DOMAIN.txt" >> "$BASE_DIR/tmp.txt"
    l1=$(cat "$BASE_DIR/tmp.txt" | wc -l)
    cat "$BASE_DIR/tmp.txt" | tr '[:upper:]' '[:lower:]' | sort -u > "$BASE_DIR/subdomains.txt"
    l2=$(cat "$BASE_DIR/subdomains.txt" | wc -l)
    echo "All: $l1 - Unique: $l2" > "$BASE_DIR/count.txt"
}

function clean-files {
    rm -rf "$BASE_DIR/tmp.txt"
    rm -rf "$BASE_DIR/aiodns-$DOMAIN.txt"
    rm -rf "$BASE_DIR/subfinder-$DOMAIN.txt"
    rm -rf "$BASE_DIR/amass-$DOMAIN.txt"
    rm -rf "$BASE_DIR/crtsh-$DOMAIN.txt"
}

function main {
    amass-exec
    subfinder-exec
    aiodns-exec
    crtsh-exec
    merge-exec
    clean-files
}

mkdir "$BASE_DIR"
{ time main ; } 2> time.txt
t=$(cat time.txt | grep real | cut -d " " -f2)
cp -r $BASE_DIR /data


