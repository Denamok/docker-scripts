#! /bin/bash
#set -x
set +x

# Load configuration
source config.sh

if [ "$driver" != "generic" ]
then
   print_trace "Driver is generic : this operation is not supported."
   exit 0
fi

for machine in $(docker-machine ls -q)
do
  docker-machine stop $machine
done
