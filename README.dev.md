## Worker for cloud deployment

Build:

`docker build . -t subs`

Run:

`docker run -it -v "$(pwd):/data" --rm subs yahoo.com `

## Helper

Count all uniq domains
` for i in $(ls -d */);do cd $i;cat count.txt | cut -d " " -f5;cd ..;done > sum.txt; cat sum.txt | paste -sd+ | bc`

Get duplicates in two lists
`sort available-amass.txt available-subfinder.txt | awk 'dup[$0]++ == 1'`

## ToDo
- ~~Wordlist: Jhaddix all.txt fails because of the special chars.~~
- ~~Telegram optional ~~
- Argument Parsing improvment
- ~~Add altdns and dns permutations: https://github.com/hpy/permDNS ~~
- ~~OneForAll Integration?~~ https://github.com/shmilylty/OneForAll/blob/master/docs/en-us/README.md
    - slow.
- Wayback subdomains
- ~~Other project Analytics: ~~
    - Comparison tools:
        - Subdomain overlap and total count


## Note

`curl -s https://www.alexa.com/topsites | grep "<a href=\"/siteinfo"  | cut -d "\"" -f2 | cut -d "/" -f3`

## KISS

HTTPX check is less necessary than the massdns check if a domain is resolvable. Move to other container. 
Check which ports are open. TBD with Portscan.

```
# Install httpx
RUN git clone https://github.com/projectdiscovery/httpx.git &&\ 
    cd httpx/cmd/httpx &&\ 
    go build &&\ 
    mv httpx /usr/local/bin/
---
function httpx-exec {
    httpx -silent -no-color  -threads 64 -l "$BASE_DIR/final.txt" -title -content-length -web-server -status-code -ports 80,81,443,4000,4433,5000,5432,5800,5801,8008,8080,8443,8888 -o "$BASE_DIR/httpx-$DOMAIN.txt"
    num_domains=$(cat "$BASE_DIR/httpx-$DOMAIN.txt" | wc -l)
    notify "online - $DOMAIN - $num_domains"
}

function massdns-exec {
    massdns -r /root/dns_resolver.txt  -o S -t A -w "$BASE_DIR/massdns-$DOMAIN.txt" "$BASE_DIR/merged_subdomains.txt" &> /dev/null
    echo "[+] Massdns for $DOMAIN finished"
}

function format-massdns {
    cat "$BASE_DIR/massdns-$DOMAIN.txt" | cut -d " " -f1 | sed 's/.$//' >> "$BASE_DIR/resolved_subdomains.txt"
    echo "[+] Format resolved domains"
}


function analyse-results {
    # Make every line lowercase for comparison
    cat "$BASE_DIR/aiodns-$DOMAIN.txt" | tr '[:upper:]' '[:lower:]' > "$BASE_DIR/aiodns-results.txt"
    cat "$BASE_DIR/subfinder-$DOMAIN.txt" | tr '[:upper:]' '[:lower:]' > "$BASE_DIR/subfinder-results.txt"
    cat "$BASE_DIR/amass-$DOMAIN.txt" | tr '[:upper:]' '[:lower:]' > "$BASE_DIR/amass-results.txt"
    cat "$BASE_DIR/crtsh-$DOMAIN.txt" | tr '[:upper:]' '[:lower:]' > "$BASE_DIR/crtsh-results.txt"
    # Create and count duplicates
    amass_aiodns_dups=$(sort $BASE_DIR/amass-results.txt $BASE_DIR/aiodns-results.txt | awk 'dup[$0]++ == 1' | wc -l)
    amass_subfinder_dups=$(sort $BASE_DIR/amass-results.txt $BASE_DIR/subfinder-results.txt | awk 'dup[$0]++ == 1' | wc -l)
    amass_crtsh_dups=$(sort $BASE_DIR/amass-results.txt $BASE_DIR/crtsh-results.txt | awk 'dup[$0]++ == 1' | wc -l)
    subfinder_aiodns_dups=$(sort $BASE_DIR/subfinder-results.txt $BASE_DIR/aiodns-results.txt | awk 'dup[$0]++ == 1' | wc -l)
    subfinder_crtsh_dups=$(sort $BASE_DIR/subfinder-results.txt $BASE_DIR/crtsh-results.txt | awk 'dup[$0]++ == 1' | wc -l)
    aiodns_crtsh_dups=$(sort $BASE_DIR/aiodns-results.txt $BASE_DIR/crtsh-results.txt | awk 'dup[$0]++ == 1' | wc -l)
    # Get length of input lists
    aiodns_length=$(cat $BASE_DIR/aiodns-results.txt | wc -l)
    subfinder_length=$(cat $BASE_DIR/subfinder-results.txt | wc -l)
    amass_length=$(cat $BASE_DIR/amass-results.txt | wc -l)
    crtsh_length=$(cat $BASE_DIR/crtsh-results.txt | wc -l)
    # Output comparison to file
    printf '%s\n%s\n%s\n%s\n%s\n%s\n' "Amass ($amass_length)/ Subfinder ($subfinder_length) / Duplicates: $amass_subfinder_dups" "Amass ($amass_length)/ Aiodns ($aiodns_length) / Duplicates: $amass_aiodns_dups" "Amass ($amass_length)/ Crtsh ($crtsh_length) / Duplicates: $amass_crtsh_dups" "Subfinder ($subfinder_length)/ Aiodns ($aiodns_length) / Duplicates: $subfinder_aiodns_dups" "Subfinder ($subfinder_length)/ Crtsh ($crtsh_length) / Duplicates: $subfinder_crtsh_dups" "Aiodns ($aiodns_length)/ Crtsh ($crtsh_length) / Duplicates: $aiodns_crtsh_dups">> $BASE_DIR/analytics.txt
}

msg="Enum for $DOMAIN finished:$NL$(cat $BASE_DIR/count.txt)$NL Subfinder: $(cat $BASE_DIR/subfinder-$DOMAIN.txt | wc -l)$NL Amass: $(cat $BASE_DIR/amass-$DOMAIN.txt | wc -l)$NL Aiodns: $(cat $BASE_DIR/aiodns-$DOMAIN.txt | wc -l)$NL Crtsh: $(cat $BASE_DIR/crtsh-$DOMAIN.txt | wc -l)$NL Subdomain list (input for altdns): $(cat $BASE_DIR/subdomains.txt | wc -l)$NL Altdns list: $(cat $BASE_DIR/altdns-list-$DOMAIN.txt | wc -l)$NL Subdomains resolved: $(cat $BASE_DIR/shuffledns-$DOMAIN.txt | wc -l)$NL Analytics $NL $(cat $BASE_DIR/analytics.txt) $NL $T " 



function merge-altdns {
    cat "$BASE_DIR/subdomains.txt" >> "$BASE_DIR/merged_subdomains.txt"
    cat "$BASE_DIR/altdns-list-$DOMAIN.txt" >> "$BASE_DIR/merged_subdomains.txt"
    echo "[+] Merged recon list with altdns"
}

function resolve-list {
    aiodnsbrute -r /root/dns_resolver.txt -w "$BASE_DIR/alternated_subdomains.lst" -t 64 -o json -f "$BASE_DIR/resolved-$DOMAIN.json" $DOMAIN &> /dev/null
    python3 /code/aioparse.py "$BASE_DIR/resolved-$DOMAIN.json" "$BASE_DIR/resolved-$DOMAIN.txt" &> /dev/null
    echo "[+] Resolving altdns domain list finished"
}
```