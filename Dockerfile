#This dockerfile base on Ubuntu image
#Author: mygithublab@126.com
#NRPE plugin integration

FROM ubuntu:16.04

MAINTAINER Mygithub (mygithublab@126.com)

###############
#Install tools#
###############
RUN apt-get update && apt-get install -y \
    openssh-server \
    git \
    vim \
    cron \
    ntp \
    ntpdate \
    tzdata \
#Prerequisties xinetd for NRPE
    xinetd \
#Prerequisties software for Nagios plugin
    autoconf \
    gcc \
    libc6 \
    libmcrypt-dev \
    make \
    libssl-dev \
    wget \
    bc \
    gawk \
    dc \
    build-essential \
    snmp \
    libnet-snmp-perl \
    gettext \
#Prerequisies software for ping function
    inetutils-ping \
    net-tools \
 && apt-get clean 

########################################
#Download nagios plug-in to /tmp folder#
########################################
RUN cd /tmp \
 && wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz \
 && tar zxvf nagios-plugins.tar.gz \
 && cd /tmp/nagios-plugins-release-2.2.1/ \
 && ./tools/setup \
 && ./configure \
 && make \
 && make install \
#create nagios account 
 && useradd nagios \
# && groupadd nagios \
 && usermod -a -G nagios nagios \
 && chown nagios.nagios /usr/local/nagios \
 && chown -R nagios.nagios /usr/local/nagios/libexec \
#Download NRPE to /tmp folder
 && cd /tmp \
 && wget --no-check-certificate https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz \
 && tar xzvf nrpe-3.2.1.tar.gz \
 && cd nrpe-3.2.1 \
 && ./configure \
 && make all \
 && make install \
 && make install-config \
 && make install-inetd \
 && sed -i '$a nrpe \t 5666\/tcp' /etc/services \
 && sed -i '5 s/yes/no/g' /etc/xinetd.d/nrpe \
 && sed -i '13 s/^/#/' /etc/xinetd.d/nrpe \
#Check NRPE fouction
 && netstat -at | egrep "nrpe|5666" \
 && /usr/local/nagios/libexec/check_nrpe -H 127.0.0.1 \

#Clean /tmp folder
 && rm -rf /tmp/*

###################################
#Put scripts and file to container#
###################################
ADD run.sh /run.sh
ADD authorized_keys /root/.ssh/authorized_keys
RUN mkdir /share \
 && chmod 755 /run.sh \
 && chmod 700 /root/.ssh \
 && chmod 600 /root/.ssh/authorized_keys \
#Copy ngios and graph to /bk folder 
 && mkdir -p /bk/nagios \
 && cp -R -p /usr/local/nagios/etc /bk/nagios \
#Define schedule task and ntp timezone
 && sed -i 's/Etc\/UTC/Asia\/Shanghai/g' /etc/timezone \ 
 && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && sed -i '$a server 0.ubuntu.pool.ntp.org' /etc/ntp.conf \
 && sed -i '$a server 1.ubuntu.pool.ntp.org' /etc/ntp.conf \
 && sed -i '$a server 2.ubuntu.pool.ntp.org' /etc/ntp.conf \
 && sed -i '$a server 3.ubuntu.pool.ntp.org' /etc/ntp.conf 

EXPOSE 80 22

VOLUME "/share" 

CMD ["/run.sh"]
