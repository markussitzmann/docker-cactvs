ARG build_tag
FROM docker-cactvs-base:$build_tag as cactvs
FROM debian:bullseye
ARG cactvs_version

LABEL maintainer="markus.sitzmann@gmail.com "

RUN apt-get --allow-releaseinfo-change update && apt-get -y --no-install-recommends install \
    ca-certificates \
    curl wget gosu sudo unzip tar bzip2 git gnupg2 \
    libidn11 \
    libfontconfig \
    joe

#ENV PATH /opt/conda/bin:$PATH
ENV PATH /home/app:/opt/conda/bin:$PATH


ENV TK_LIBRARY /opt/cactvs/lib/$cactvs_version/tk8.6
ENV TCL_LIBRARY /opt/cactvs/lib/$cactvs_version/tcl8.6
ENV TCLX_LIBRARY /opt/cactvs/lib/$cactvs_version/tclx8.4
ENV BLT_LIBRARY /opt/cactvs/lib/$cactvs_version/blt3.0
ENV TIX_LIBRARY /opt/cactvs/lib/$cactvs_version/tix8.4
ENV OS="Linux6.4"
ENV CACTVS_DATA_DIRECTORY /opt/cactvs/lib/$cactvs_version
#ENV CACTVS_DATA_DIRECTORY="/opt/cactvs/lib/cactvs3.4.8.19:/home/app/cactvsenv/prop"
ENV PATH /opt/cactvs/lib/$cactvs_version/lib:$CACTVS_DATA_DIRECTORY:$PATH
ENV LD_LIBRARY_PATH /opt/cactvs/lib/$cactvs_version/lib:/opt/cactvs/lib/$cactvs_version/lib/ssl:$LD_LIBRARY_PATH

COPY requirements.txt /opt/python
COPY --from=cactvs /opt/cactvs /opt/cactvs

