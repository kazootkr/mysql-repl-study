#!/bin/sh -eu
OCTETS=$(hostname -i | tr -s '.' ' ')

THIRD_OCTET=$(echo ${OCTETS} | cut -d' ' -f3)
FOURTH_OCTET=$(echo ${OCTETS} | cut -d' ' -f4)

MYSQL_SERVER_ID=$(expr "${THIRD_OCTET}" \* 256 + "${FOURTH_OCTET}")
echo "server-id=${MYSQL_SERVER_ID}" >> /etc/mysql/mysql.conf.d/mysqld.cnf


if [ "false" = "${MYSQL_PRIMARY}" ]; then
    echo "read-only=ON" >> /etc/mysql/mysql.conf.d/mysqld.cnf
fi