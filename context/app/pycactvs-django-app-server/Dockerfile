ARG build_tag
FROM cactvs-django-app-server:$build_tag
ARG conda_py

LABEL maintainer="markus.sitzmann@gmail.com "

ENV PATH /opt/conda/bin:$PATH

COPY nginx /home/nginx
COPY requirements.txt /

RUN /bin/bash -c "source activate cactvs" && \
    CONDA_PY=$conda_py pip install -r /requirements.txt

#RUN apt-get update && apt-get -y --no-install-recommends install \
#    nginx \
#    supervisor \
#    && rm -rf /var/lib/apt/lists/* \
#    && apt-get autoremove -y \
#    && apt-get clean

#RUN chown -R www-data.www-data /home/nginx && \
#    echo "daemon off;" >> /etc/nginx/nginx.conf && \
#    rm /etc/nginx/sites-enabled/default && \
#    ln -s /home/nginx/nginx.conf /etc/nginx/sites-enabled/ && \
#    ln -s /home/nginx/supervisord.conf /etc/supervisor/conf.d/

#EXPOSE 80
#CMD ["/home/nginx/run.sh"]