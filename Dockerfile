FROM golang:latest
RUN apt update
RUN GO111MODULE=auto go get -u -v github.com/projectdiscovery/subfinder/cmd/subfinder
RUN GO111MODULE=auto go get -v github.com/OWASP/Amass/v3/...
RUN go get -u github.com/tomnomnom/httprobe

# Setup Python
RUN apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget curl
RUN curl -O https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
RUN tar -xf Python-3.8.0.tar.xz  
RUN cd Python-3.8.0 &&\
    ./configure --enable-optimizations &&\
    make &&\
    make altinstall

RUN apt install python3-pip -y
RUN pip3 install python-telegram-bot --upgrade
# Setup Bash script
COPY main.sh /root/main.sh
RUN chmod +x /root/main.sh
COPY message.py /code/message.py
COPY telegram.token /code/telegram.token
ENTRYPOINT [ "../root/main.sh" ]