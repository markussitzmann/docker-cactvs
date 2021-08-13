FROM debian:buster-slim
ARG cactvs_package
LABEL maintainer="markus.sitzmann@gmail.com "

RUN apt-get --allow-releaseinfo-change update && apt-get -y --no-install-recommends install \
    ca-certificates \
    curl gosu sudo unzip tar bzip2 git gnupg2 \
    libidn11 \
    libfontconfig \
    joe

RUN mkdir -p /opt/download
WORKDIR /opt/download

RUN curl -L -o cactvs.tar.gz https://xemistry.com/academic/$cactvs_package \
 && tar xzvf cactvs.tar.gz \
 && ./installme /opt/cactvs

