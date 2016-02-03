#! /bin/bash

for machine in $(docker-machine ls -q)
do
  docker-machine rm -f $machine
done
