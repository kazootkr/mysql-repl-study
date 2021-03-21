#!/bin/sh -eu

if [ "true" =  "${MYSQL_PRIMARY}" ]; then
    echo "this container is primary"

    # レプリケーション用ユーザーと権限の作成
    (
        IP=`hostname -i`
        IFS='.'
        set -- $IP
        SOURCE_IP="$1.$2.%.%"

        MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysql -uroot -e "CREATE USER IF NOT EXISTS '${MYSQL_REPL_USER}'@'${SOURCE_IP}' IDENTIFIED BY '${MYSQL_REPL_PASSWORD}';"
        MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysql -uroot -e "GRANT REPLICATION SLAVE ON *.* TO'${MYSQL_REPL_USER}'@'${SOURCE_IP}';"
    )

    return 0
fi

echo "prepare as slave"

if [ -z "${MYSQL_PRIMARY_HOST}" ]; then
    echo "mysql_primary_host is not specified" 1>&2
    return 1
fi

while :
do
    if MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysql -h "${MYSQL_PRIMARY_HOST}" -uroot -e "quit" > /dev/null 2>&1; then
        echo "MySQL primary is ready!"
        break
    else
        echo "MySQL primary is not ready"
    fi
    sleep 3
done

# binlogのポジション取得
MASTER_STATUS_FILE=/tmp/masterstatus
MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysql -h"${MYSQL_PRIMARY_HOST}" -uroot -e "SHOW MASTER STATUS\G" > ${MASTER_STATUS_FILE}
BINLOG_FILE=$(cat ${MASTER_STATUS_FILE} | grep File | xargs | cut -d' ' -f2)
BINLOG_POSITION=$(cat ${MASTER_STATUS_FILE} | grep Position | xargs | cut -d' ' -f2)
echo "BINLOG_FILE=${BINLOG_FILE}"
echo "BINLOG_POSITION=${BINLOG_POSITION}"

# レプリケーションの開始
MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysql -uroot -e "CHANGE MASTER TO MASTER_HOST='${MYSQL_PRIMARY_HOST}',MASTER_USER='${MYSQL_REPL_USER}',MASTER_PASSWORD='${MYSQL_REPL_PASSWORD}',MASTER_LOG_FILE='${BINLOG_FILE}',MASTER_LOG_POS=${BINLOG_POSITION};"

MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysql -uroot -e "START SLAVE;"

echo "slave started"