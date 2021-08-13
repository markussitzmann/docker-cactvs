ARG build_tag
FROM docker-cactvs:$build_tag

LABEL maintainer="markus.sitzmann@gmail.com "

WORKDIR /home/app

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/opt/cactvs/bin/cspy"]