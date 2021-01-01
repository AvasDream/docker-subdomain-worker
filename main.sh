#!/bin/bash

function display-help {
    echo "Usage:"
    echo "docker run -it --rm -v \"\$(pwd):/data\" subs hackerone.com \$telegram_chat_id \$telegram_secret"
    echo "Note: Arguments must be supplied in the exact same order as above."
    exit 1
}
if [ ! $# -eq 3 ]
then 
    display-help
fi

DOMAIN="$1"
CHAT_ID="$2"
echo "$CHAT_ID" > /code/chat.id
SECRET_TOKEN="$3"
echo "$SECRET_TOKEN" > /code/telegram.token
DATE=$(date +%d.%m.%y-%H:%M)
BASE_DIR="/root/$DOMAIN-$DATE"
TOOLS_DIR='/root/tools'
MESSAGE=""
echo "[+] Enumerate $DOMAIN"

function amass-exec {
    amass enum --passive -d "$DOMAIN" -o "$BASE_DIR/amass-$DOMAIN.txt" &> /dev/null
    echo "[+] Amass for $DOMAIN finished"
}

function subfinder-exec {
    subfinder -d $DOMAIN -nC -o "$BASE_DIR/subfinder-$DOMAIN.txt" -silent -t 64 -timeout 10 -all &> /dev/null
    echo "[+] Subfinder for $DOMAIN finished"
}

function aiodns-exec {
    aiodnsbrute -r /root/dns_resolver.txt -w $1 -t 64 -o json -f "$BASE_DIR/aiodns-$DOMAIN.json" $DOMAIN &> /dev/null
    python3 /code/aioparse.py "$BASE_DIR/aiodns-$DOMAIN.json" $2 &> /dev/null
    echo "[+] Aiodns for wordlist $1 finished"
}

function crtsh-exec {
    curl -s https://crt.sh/?q=%25.$DOMAIN | grep "$DOMAIN" | grep "<TD>" | cut -d">" -f2 | cut -d"<" -f1 | sort -u | sed s/*.//g > "$BASE_DIR/crtsh-$DOMAIN.txt"
    echo "[+] Crtsh for $DOMAIN finished"
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
    echo "[+] Merging results for $DOMAIN finished"
}

function altdns-exec {
    echo $DOMAIN >> "$BASE_DIR/subdomains.txt"
    python3 /altdns/altdns/__main__.py -i "$BASE_DIR/subdomains.txt" -o "$BASE_DIR/altdns-list-$DOMAIN.txt" -w "/code/altdns.txt" &> /dev/null
    echo "[+] Created permutated wordlist for $DOMAIN"
}

function cut-out-domain {
    cat "$BASE_DIR/subdomains.txt" | sed "s/.$DOMAIN//" >> "$BASE_DIR/alternated_subdomains.lst"
    cat "$BASE_DIR/altdns-list-$DOMAIN.txt" | sed "s/.$DOMAIN//" >> "$BASE_DIR/alternated_subdomains.lst"
    echo "[+] Created List for Aiodns"
}

function clean-files {
    rm -rf "$BASE_DIR/tmp.txt"
    rm -rf "$BASE_DIR/count.txt"
    rm -rf "$BASE_DIR/aiodns-$DOMAIN.txt"
    rm -rf "$BASE_DIR/subfinder-$DOMAIN.txt"
    rm -rf "$BASE_DIR/amass-$DOMAIN.txt"
    rm -rf "$BASE_DIR/crtsh-$DOMAIN.txt"
    rm -rf "$BASE_DIR/altdns-list-$DOMAIN.txt"
    rm -rf "$BASE_DIR/massdns-$DOMAIN.txt"
    rm -rf "$BASE_DIR/merged_subdomains.txt"
    rm -rf "$BASE_DIR/resolved-$DOMAIN.json"
    echo "[+] Deleted files"
}



function main {
    amass-exec
    subfinder-exec
    aiodns-exec "/root/sublist.txt" "$BASE_DIR/aiodns-$DOMAIN.txt"
    crtsh-exec
    merge-exec
    altdns-exec
    cut-out-domain
    aiodns-exec "$BASE_DIR/alternated_subdomains.lst" "$BASE_DIR/resolved-$DOMAIN.txt"
}

mkdir "$BASE_DIR"
{ time main ; } 2> time.txt
T=$(cat time.txt | grep real | cut -d " " -f2)
NL=$'\n'
msg="Enum for $DOMAIN finished:$NL$ Subdomain list (input for altdns): $(cat $BASE_DIR/subdomains.txt | wc -l)$NL Altdns list: $(cat $BASE_DIR/altdns-list-$DOMAIN.txt | wc -l)$NL Subdomains resolved: $(cat $BASE_DIR/resolved-$DOMAIN.txt | wc -l)$NL $T " 
python3 /code/message.py "$msg" &> /dev/null
#clean-files
cp -r $BASE_DIR /data
echo "[+] finished in $T"


