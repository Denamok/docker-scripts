
ls
print_trace() {
    echo "$(date +%y-%m-%dT%H:%M:%S)> $1"
}

machine_already_exists(){
 machine_name=$1
 for machine in $(docker-machine ls -q)
 do
    if [ "$machine_name" == "$machine" ]
    then
        return 0
    fi
 done
 return 1
}

container_already_exists(){
 machine_name=$1
 container_name=$2
 current_machine_name=$(echo $DOCKER_MACHINE_NAME)
 eval $(docker-machine env $machine_name)
 for container_id in $(docker ps -q)
 do
    container=$(docker inspect --format='{{.Name}}' $container_id)
    if [ "/$container_name" == "$container" ]
    then
         eval $(docker-machine env $current_machine_name)
        return 0
    fi
 done
 eval $(docker-machine env $current_machine_name)
 return 1
}

ssh_key_already_exists(){
 ip=$1
 ssh -q -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no root@$1 'ls' || return 1
 return 0
}
