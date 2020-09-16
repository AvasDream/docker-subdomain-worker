## Worker for cloud deployment

Build:

`docker build . -t subs`

Run:

`docker run -it -v "$(pwd):/data" --rm subs yahoo.com `


## ToDo
- Wordlist: Jhaddix all.txt fails because of the special chars.