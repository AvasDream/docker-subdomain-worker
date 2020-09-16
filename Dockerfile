FROM kalilinux/kali-rolling:latest
RUN apt update
# Install essentials
RUN apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget curl git
# Install go 
RUN wget https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.13.4.linux-amd64.tar.gz
ENV PATH="${PATH}:/usr/local/go/bin"
RUN go version
# Install Python
RUN curl -O https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
RUN tar -xf Python-3.8.0.tar.xz  
RUN cd Python-3.8.0 &&\
    ./configure --enable-optimizations &&\
    make &&\
    make altinstall
# Python dependencies telegram
RUN apt install python3-pip -y
RUN pip3 install python-telegram-bot --upgrade
# Install amass
RUN apt-get install amass -y
# Install subfinder
RUN GO111MODULE=auto go get -u -v github.com/projectdiscovery/subfinder/cmd/subfinder
# Setup Bash script
COPY main.sh /root/main.sh
RUN chmod +x /root/main.sh
COPY message.py /code/message.py
COPY telegram.token /code/telegram.token


# Create output folder inside the container
RUN mkdir /data
ENTRYPOINT [ "../root/main.sh" ]