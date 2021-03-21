# mysql-repl-study/Makefile

PRIMARY_DOCKER_VOLUME_NAME := mysql-repl-study-primary-storage

.PHONY: all run stop destroy stats prepare-repl stop-slave

## ================================================================
# コンテナ関連の操作
## ================================================================
all: stop run

run:
	docker compose up -d --build

stop:
	docker compose stop

destroy:
	docker compose down
	docker volume rm $(PRIMARY_DOCKER_VOLUME_NAME)

## ================================================================
# レプリケーション関連の操作
## ================================================================
stats:
	docker compose exec  mysql-primary sh -c 'MYSQL_PWD=$${MYSQL_ROOT_PASSWORD} mysql -uroot -e "SHOW MASTER STATUS\G"' | grep -e File -e Position
	docker compose exec  mysql-replica sh -c 'MYSQL_PWD=$${MYSQL_ROOT_PASSWORD} mysql -uroot -e "SHOW SLAVE STATUS\G"' | grep -e Slave_IO_Running -e Slave_SQL_Running -e Seconds_Behind_Master -e Master_Log_File -e Master_Log_Pos -e _Error

prepare-repl: stop-slave
	docker compose exec mysql-primary prepare-repl.sh
	docker compose exec mysql-replica prepare-repl.sh

stop-slave:
	docker compose exec  mysql-replica sh -c 'MYSQL_PWD=$${MYSQL_ROOT_PASSWORD} mysqladmin stop-slave'