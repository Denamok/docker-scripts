#! /bin/bash
#set -x
set +x
for machine in $(docker-machine ls -q)
do
  docker-machine stop $machine
done
