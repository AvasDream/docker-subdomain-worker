## Worker for cloud deployment

Build:

`docker build . -t subs`

Run:

`docker run -it -v "$(pwd):/data" --rm subs yahoo.com `


## ToDo
- Wordlist: Jhaddix all.txt fails because of the special chars.


## KISS

The check if a domain is live should be in another container.

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