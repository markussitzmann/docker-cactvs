ARG cactvs_version
FROM docker-cactvs-conda:$cactvs_version
ARG conda_py

LABEL maintainer="markus.sitzmann@gmail.com"

#ENV PATH /opt/conda/bin:$PATH

RUN mkdir -p /opt/django /home/nginx

##COPY . /opt/django
##COPY ./.env /opt/django/env
##COPY app-context/nginx /home/nginx
#
##COPY docker-entrypoint.sh /
COPY requirements.txt /opt/django

RUN /bin/bash -c "source activate cactvs" && \
    CONDA_PY=$conda_py conda install --freeze-installed --yes --file /opt/django/requirements.txt && \
    conda clean -afy && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete

RUN apt-get update && apt-get -y --no-install-recommends install \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean
