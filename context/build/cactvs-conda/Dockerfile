ARG build_tag
FROM docker-cactvs-base:$build_tag as cactvs
FROM debian:bullseye
ARG conda_py
ARG conda_package
ARG cactvs_version

LABEL maintainer="markus.sitzmann@gmail.com "

RUN apt-get --allow-releaseinfo-change update && apt-get -y --no-install-recommends install \
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
ENV OS="Linux5.8"
ENV CACTVS_DATA_DIRECTORY /opt/cactvs/lib/$cactvs_version
ENV PATH /opt/cactvs/lib/$cactvs_version/lib:$CACTVS_DATA_DIRECTORY:$PATH
ENV LD_LIBRARY_PATH /opt/cactvs/lib/$cactvs_version/lib:/opt/cactvs/lib/$cactvs_version/lib/ssl:$LD_LIBRARY_PATH

RUN mkdir -p /opt/python

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet --no-check-certificate https://repo.continuum.io/miniconda/$conda_package && \
    /bin/bash /$conda_package -b -p /opt/conda && \
    rm $conda_package



COPY requirements.txt /opt/python

#RUN CONDA_PY=$conda_py conda install anaconda-client --yes && \
#    CONDA_PY=$conda_py CONDA_NO_PLUGINS=true conda install --solver=classic libffi==3.3 && \
#    CONDA_PY=$conda_py conda config --add channels conda-forge && \
#    CONDA_PY=$conda_py conda create --verbose --yes -n cactvs

#RUN conda install libffi==3.3

RUN python -m pip install -U cffi

#RUN export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libffi.so.7

RUN CONDA_PY=$conda_py conda create --verbose --yes -n cactvs



RUN /bin/bash -c "source activate cactvs" && \
  CONDA_PY=$conda_py conda install --yes --file /opt/python/requirements.txt

#COPY /opt/cactvs/lib/$cactvs_version/lib/python3.10/lib-dynload/_ctypes.cpython-310-x86_64-linux-gnu.so /

#COPY --from=cactvs /opt/cactvs /opt/cactvs
#COPY --from=cactvs /opt/cactvs/lib/$cactvs_version/lib/python3.10/lib-dynload /opt/conda/lib/python3.10/lib-dynload
#COPY --from=cactvs /opt/cactvs/lib/$cactvs_version/lib/libgdbm.so.4 \
#    /opt/cactvs/lib/$cactvs_version/lib/libgdbm.so \
#    /opt/cactvs/lib/$cactvs_version/lib/libgdbm.so.4.0.0 \
#    /opt/cactvs/lib/$cactvs_version/lib/libCgdbm.so \
#    /opt/conda/lib/
#
#
COPY ficuslib.tcl /opt/cactvs/lib/$cactvs_version/propdata/ficuslib.tcl

#COPY /_ctypes.cpython-310-x86_64-linux-gnu.so /opt/cactvs/lib/$cactvs_version/lib/python3.10/lib-dynload/

RUN /bin/bash -c "source activate cactvs" && \
    CONDA_PY=$conda_py conda install --yes --file /opt/python/requirements.txt && \
    conda clean -afy && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete


COPY --from=cactvs /opt/cactvs /opt/cactvs
COPY --from=cactvs /opt/cactvs/lib/$cactvs_version/lib/python3.10/lib-dynload /opt/conda/lib/python3.10/lib-dynload
COPY --from=cactvs /opt/cactvs/lib/$cactvs_version/lib/libgdbm.so.4 \
    /opt/cactvs/lib/$cactvs_version/lib/libgdbm.so \
    /opt/cactvs/lib/$cactvs_version/lib/libgdbm.so.4.0.0 \
    /opt/cactvs/lib/$cactvs_version/lib/libCgdbm.so \
    /opt/conda/lib/

