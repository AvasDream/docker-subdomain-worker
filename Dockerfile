FROM kalilinux/kali-rolling:latest
RUN apt update
# Install essentials
RUN apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget curl git
# Install go 
RUN apt install -y golang
RUN go version
# Install Python 3.8.0
RUN curl -O https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
RUN tar -xf Python-3.8.0.tar.xz  
RUN cd Python-3.8.0 &&\
    ./configure --enable-optimizations &&\
    make &&\
    make altinstall
# Python pip3
RUN apt install python3-pip -y
RUN pip3 install requests
# Install amass
RUN apt-get install amass -y
# Install subfinder
RUN git clone https://github.com/projectdiscovery/subfinder.git &&\
    cd subfinder/v2/cmd/subfinder &&\
    go build . &&\
    mv subfinder /usr/local/bin/ 
# Install Aiodnsbrute
RUN pip3 install aiodnsbrute
# Create Resolvers file
RUN echo 8.8.8.8 > /root/dns_resolver.txt
# Download Subdomain List
RUN wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt -O /root/sublist.txt
# Install altDNS
RUN git clone https://github.com/infosec-au/altdns.git &&\
    cd altdns &&\
    pip install -r requirements.txt
COPY altdns.txt /code/altdns.txt
#Install massdns
RUN apt-get install libldns-dev -y
RUN git clone https://github.com/blechschmidt/massdns.git &&\
    cd massdns &&\
    make &&\
    mv /massdns/bin/massdns /usr/bin/massdns
#Install shuffledns
RUN GO111MODULE=on go get -v github.com/projectdiscovery/shuffledns/cmd/shuffledns
ENV PATH="/root/go/bin:${PATH}"
# Setup Bash script
COPY main.sh /root/main.sh
RUN chmod +x /root/main.sh
COPY aioparse.py /code/aioparse.py
COPY message.py /code/message.py
# Create output folder inside the container
RUN mkdir /data
ENTRYPOINT [ "../root/main.sh" ]
