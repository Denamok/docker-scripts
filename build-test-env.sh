#! /bin/bash
#set -x
set +x

# Load tools
source config.sh
source common-lib.sh

# Custom parameters
memory=""
if [ "$driver" == "virtualbox" ] && [ ! -z "${virtualbox_memory}" ]
then
  memory="--virtualbox-memory ${virtualbox_memory}"
fi

# Script

# Discovery Service Consul 
print_trace "Deploy Discovery Service Consul..."
if ! $(machine_already_exists $consul_hostname)
then
  if [ "$driver" != "generic" ]
  then
    docker-machine create -d=${driver} ${memory} $consul_hostname
  else
    docker-machine create -d=${driver} --generic-ssh-user ${ssh_user} --generic-ip-address ${consul_ip} $consul_hostname
  fi
else
  print_trace "Discovery Service Consul machine already deployed."
fi

# Run Consul image
print_trace "Run Consul image..."
eval $(docker-machine env $consul_hostname)
if ! container_already_exists $consul_hostname $consul_container_name
then
  docker run --name $consul_container_name -d -p 8500:8500 -h consul progrium/consul -server -bootstrap
else
  print_trace "Run Consul image already deployed."
fi

# Swarm master
print_trace "Deploy Swarm master $swarm_master_hostname..."
if ! $(machine_already_exists $swarm_master_hostname)
then
  if [ "$driver" != "generic" ]
  then
    docker-machine create -d ${driver} ${memory} --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-store=consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-advertise=eth0:2376" $swarm_master_hostname
  else
    docker-machine create -d ${driver} --generic-ssh-user ${ssh_user} --generic-ip-address ${swarm_master_ip} --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-store=consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-advertise=eth0:2376" $swarm_master_hostname
  fi
else
  print_trace "Swarm master $swarm_master_hostname already deployed."
fi

# Swarm agents
print_trace "Deploy Swarm agents..."
n=$(expr $nb_swarm_agents + 1)
for i in $(seq 2 $n)
do
  print_trace "Deploy Swarm agent ${swarm_agent_hostname}${i}..."
  if ! $(machine_already_exists ${swarm_agent_hostname}${i})
  then
    if [ "$driver" != "generic" ]
    then
      docker-machine create -d ${driver} ${memory} --swarm --swarm-discovery="consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-store=consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-advertise=eth0:2376" ${swarm_agent_hostname}${i}
    else
      docker-machine create -d ${driver} --generic-ssh-user ${ssh_user} --generic-ip-address ${swarm_agent_ip[$i]} --swarm --swarm-discovery="consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-store=consul://$(docker-machine ip $consul_hostname):8500" --engine-opt="cluster-advertise=eth0:2376" ${swarm_agent_hostname}${i}
    fi
  else
    print_trace "Swarm agent ${swarm_agent_hostname}${i} already deployed."
  fi
done

# Register Consul container in cluster
print_trace "Register Consul container in cluster..."
if ! container_already_exists $consul_hostname $consul_swarm_agent_container_name
then
  docker run -d --name $consul_swarm_agent_container_name --restart=always -e "SWARM_HOST=:2375" swarm join --advertise "$(docker-machine ip $consul_hostname):2376" consul://$(docker-machine ip $consul_hostname):8500
else
  print_trace "Consul container already registered in cluster."
fi


# Deploy Registrator
# Attention au paramètre --swarm
eval $(docker-machine env --swarm $swarm_master_hostname)
print_trace "Deploy Registrator for Swarm master $swarm_master_hostname..."
if ! container_already_exists $swarm_master_hostname ${registrator_master_container_name}
then
  docker run -d --name ${registrator_master_container_name} -e constraint:node==$swarm_master_hostname --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://$(docker-machine ip $consul_hostname):8500
else
  print_trace "Registrator already deployed for Swarm master $swarm_master_hostname."
fi

print_trace "Deploy Registrator for Swarm agents..."
n=$(expr $nb_swarm_agents + 1)
for i in $(seq 2 $n)
do
  print_trace "Deploy Registrator for Swarm agent ${swarm_agent_hostname}${i}..."
  # Bug fix : constraint:node not taken into account ?
  eval $(docker-machine env ${swarm_agent_hostname}${i})
  if ! container_already_exists ${swarm_agent_hostname}${i} ${registrator_agent_container_name}
  then
    docker run -d --name ${registrator_agent_container_name} -e constraint:node==${swarm_agent_hostname}${i} --net=host --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://$(docker-machine ip $consul_hostname):8500
  else
    print_trace "Registrator already deployed for Swarm agent ${swarm_agent_hostname}${i}."
  fi

done

# Display result
print_trace "List of IPs in cluster :"
docker run swarm list consul://$(docker-machine ip $consul_hostname):8500

print_trace "List of machiness in cluster :"
docker-machine ls
