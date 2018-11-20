#!/bin/bash

docker build -t github-ubuntu-image .

#docker rm -f github-ubuntu-container

docker run -itd --name github-ubuntu-container -p 10012:80 -p 10013:22 \
 -v $WORKSPACE/etc:/usr/local/nagios/etc \
 -v /ubuntu:/share \
 --restart=always github-ubuntu-image
