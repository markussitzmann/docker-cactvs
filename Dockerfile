ARG build_tag
FROM debian:buster-slim as cactvs
ARG cactvs_package
LABEL maintainer="markus.sitzmann@gmail.com "

RUN apt-get --allow-releaseinfo-change update && apt-get -y --no-install-recommends install \
    ca-certificates \
    curl gosu sudo unzip tar bzip2 git gnupg2 \
    libidn11 \
    libfontconfig \
    joe

#RUN useradd -ms /bin/bash app
#USER app

RUN mkdir -p /opt/download
WORKDIR /opt/download

RUN curl -L -o cactvs.tar.gz https://xemistry.com/academic/$cactvs_package \
 && tar xzvf cactvs.tar.gz \
 && ./installme /opt/cactvs


FROM debian:buster-slim
ARG conda_py
ARG conda_package
ARG cactvs_version

LABEL maintainer="markus.sitzmann@gmail.com "

RUN apt-get --allow-releaseinfo-change update && apt-get -y --no-install-recommends install \
    ca-certificates \
    curl wget gosu sudo unzip tar bzip2 git gnupg2 \
    libidn11 \
    libfontconfig \
    joe

ENV PATH /opt/conda/bin:$PATH

ENV TK_LIBRARY /opt/cactvs/lib/$cactvs_version/tk8.6
ENV TCL_LIBRARY /opt/cactvs/lib/$cactvs_version/tcl8.6
ENV TCLX_LIBRARY /opt/cactvs/lib/$cactvs_version/tclx8.4
ENV BLT_LIBRARY /opt/cactvs/lib/$cactvs_version/blt3.0
ENV TIX_LIBRARY /opt/cactvs/lib/$cactvs_version/tix8.4
#OS="Linux5.8"
ENV CACTVS_DATA_DIRECTORY /opt/cactvs/lib/$cactvs_version
ENV PATH /opt/cactvs/lib/$cactvs_version/lib:$CACTVS_DATA_DIRECTORY:$PATH
ENV LD_LIBRARY_PATH /opt/cactvs/lib/$cactvs_version/lib:/opt/cactvs/lib/$cactvs_version/lib/ssl:$LD_LIBRARY_PATH



RUN mkdir -p /opt/python

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/$conda_package && \
    /bin/bash /$conda_package -b -p /opt/conda && \
    rm $conda_package

COPY requirements.txt /opt/python
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN CONDA_PY=$conda_py conda install --freeze-installed anaconda-client --yes && \
    CONDA_PY=$conda_py conda config --add channels conda-forge && \
    CONDA_PY=$conda_py conda create --verbose --yes -n cactvs

COPY --from=cactvs /opt/cactvs /opt/cactvs
COPY --from=cactvs /opt/cactvs/lib/$cactvs_version/lib/python3.8/lib-dynload  /opt/conda/lib/python3.8/lib-dynload


RUN /bin/bash -c "source activate cactvs" && \
    CONDA_PY=$conda_py conda install --freeze-installed --yes --file /opt/python/requirements.txt && \
    conda clean -afy && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete


ENTRYPOINT ["/docker-entrypoint.sh"]
