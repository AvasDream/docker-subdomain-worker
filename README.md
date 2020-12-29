## Worker for cloud deployment

Build:

`docker build . -t subs`

Run:

`docker run -it -v "$(pwd):/data" --rm subs yahoo.com `

## Helper

Count all uniq domains
` for i in $(ls -d */);do cd $i;cat count.txt | cut -d " " -f5;cd ..;done > sum.txt; cat sum.txt | paste -sd+ | bc`

## ToDo
- ~~Wordlist: Jhaddix all.txt fails because of the special chars.~~
- Telegram optional 
- Argument Parsing improvment
- Add altdns and dns permutations: https://github.com/hpy/permDNS 
- OneForAll Integration? https://github.com/shmilylty/OneForAll/blob/master/docs/en-us/README.md
- Wayback subdomains
- Analytics: 
    - Comparison tools:
        - Subdomain overlap and total count
## KISS

~~The check if a domain is live should be in another container.~~
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
```

## Changelog:

### 336a5f5a0ab1491990a36872ec805930da3bfacd 
- Notify on global and not container level