#! /bin/bash
set -x
#set +x

# Load tools
source config.sh
source common-lib.sh

for machine in $(docker-machine ls -q)
do
  docker-machine rm -f $machine
done

# Consul
print_trace "Stop docker on Consul..."
ssh root@${consul_ip} << EOF
docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)
EOF

# Master
print_trace "Stop docker on Master..."
ssh root@${swarm_master_ip} << EOF
docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)
EOF

# Agents
n=$(expr $nb_swarm_agents + 1)
for i in $(seq 2 $n)
do
 print_trace "Stop docker on Agent $i..."
ssh root@${swarm_agent_ip[$i]} << EOF
docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)
EOF
done

#for i in $(docker ps -a | cut -d " " -f 1); do docker rm -f $i ; done

