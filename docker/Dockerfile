FROM mysql:5.7.17

RUN apt-get update
RUN apt-get install -y wget

ARG entrykit_version=0.4.0

RUN wget https://github.com/progrium/entrykit/releases/download/v${entrykit_version}/entrykit_${entrykit_version}_linux_x86_64.tgz
RUN tar -xvzf entrykit_${entrykit_version}_linux_x86_64.tgz
RUN rm entrykit_${entrykit_version}_linux_x86_64.tgz
RUN mv entrykit /usr/local/bin/
RUN entrykit --symlink

COPY add-server-id.sh prepare-repl.sh /usr/local/bin/
COPY mysqld.cnf /etc/mysql/mysql.conf.d/
COPY mysql.cnf /etc/mysql/conf.d/
COPY prepare-repl.sh /docker-entrypoint-initdb.d

ENTRYPOINT ["prehook", "add-server-id.sh", "--", "docker-entrypoint.sh"]
CMD ["mysqld"]