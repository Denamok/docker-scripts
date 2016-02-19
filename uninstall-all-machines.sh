#! /bin/bash
#set -x
set +x

# Load tools
source config.sh
source common-lib.sh

if [ "$driver" != "generic" ]
then
   print_trace "Driver is not generic : nothing to uninstall."
   exit 0
fi

# Consul
print_trace "Uninstall docker on Consul..."
ssh root@${consul_ip} << EOF
  apt-get purge -y docker-engine
  apt-get autoremove -y --purge docker-engine
  rm -rf /etc/systemd/system/docker.service
  rm -rf /var/lib/docker
EOF

# Master
print_trace "Uninstall docker on Master..."
ssh root@${swarm_master_ip} << EOF
  apt-get purge -y docker-engine
  apt-get autoremove -y --purge docker-engine
  rm -rf /etc/systemd/system/docker.service
  rm -rf /var/lib/docker
EOF

# Agents
n=$(expr $nb_swarm_agents + 1)
for i in $(seq 2 $n)
do
 print_trace "Uninstall docker on Agent $i..."
 ssh root@${swarm_agent_ip[$i]} << EOF
  apt-get purge -y docker-engine
  apt-get autoremove -y --purge docker-engine
  rm -rf /etc/systemd/system/docker.service
  rm -rf /var/lib/docker
EOF
done
