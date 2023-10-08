# mysql-repl-study/Makefile

PRIMARY_DOCKER_VOLUME_NAME := mysql-repl-study-primary-storage
PRIMARY_CONTAINER_NAME := $(shell docker compose ps | grep mysql-primary | cut -d" " -f1)

REPLICA_DOCKER_VOLUME_NAME := mysql-repl-study-replica-storage

.PHONY: all run stop destroy import import_world import_sakila-db clean stats prepare-repl stop-slave create-replica-from-primary

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
	docker volume rm $(REPLICA_DOCKER_VOLUME_NAME)

## ================================================================
# サンプルデータのインポート
## ================================================================

import: sample-sql/ import_world import_sakila-db

import_world:
	cat ./sample-sql/world-db/world.sql | docker exec -i "$(PRIMARY_CONTAINER_NAME)" sh -c 'MYSQL_PWD=$${MYSQL_ROOT_PASSWORD} mysql -uroot'

import_sakila-db:
	tar zxOf ./sample-sql/sakila-db.tar.gz sakila-db/sakila-schema.sql | docker exec -i "$(PRIMARY_CONTAINER_NAME)" sh -c 'MYSQL_PWD=$${MYSQL_ROOT_PASSWORD} mysql -uroot'
	tar zxOf ./sample-sql/sakila-db.tar.gz sakila-db/sakila-data.sql | docker exec -i "$(PRIMARY_CONTAINER_NAME)" sh -c 'MYSQL_PWD=$${MYSQL_ROOT_PASSWORD} mysql -uroot'

sample-sql/:
	mkdir sample-sql
	cd sample-sql && curl -O https://downloads.mysql.com/docs/world-db.zip && unzip world-db.zip
	cd sample-sql && curl -O https://downloads.mysql.com/docs/sakila-db.tar.gz
	cd sample-sql && curl -O https://downloads.mysql.com/docs/menagerie-db.tar.gz

clean:
	$(RM) -r sample-sql

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

create-replica-from-primary:
	docker compose down
	docker volume rm $(REPLICA_DOCKER_VOLUME_NAME)
	./tools/create-replica-volume-from-primary.sh $(REPLICA_DOCKER_VOLUME_NAME) $(PRIMARY_DOCKER_VOLUME_NAME)
