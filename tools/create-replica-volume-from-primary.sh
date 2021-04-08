#!/bin/sh -eu

NEW_VOL_NAME=$1
SRC_VOL_NAME=$2

if [ $(docker volume ls | grep -c "${NEW_VOL_NAME}") -gt 0 ]; then
  echo "${NEW_VOL_NAME} volume exists!"
  exit 1
fi

if [ ! 1 -eq $(docker volume ls | grep -c "${SRC_VOL_NAME}") ]; then
  echo "${SRC_VOL_NAME} volume not exists!"
  exit 1
fi

docker volume create --name "${NEW_VOL_NAME}"
docker run --rm -v "${SRC_VOL_NAME}:/from" -v "${NEW_VOL_NAME}:/to" alpine sh -c "tar cf - . -C /from | tar xf - -C /to/"
docker run --rm -v "${NEW_VOL_NAME}:/to" alpine rm /to/auto.cnf