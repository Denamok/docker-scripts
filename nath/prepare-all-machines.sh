et -x
set +x

# Load tools
source config.sh
source common-lib.sh

if [ "$driver" != "generic" ]
then
   print_trace "Driver is not generic : nothing to prepare."
   exit 0
fi

# Add key to virtual machines
if [ ! -f ~/.ssh/id_rsa ]
then
  ssh-keygen -t rsa
fi

print_trace "Deploy SSH key..."

# Consul
if ! ssh_key_already_exists ${consul_ip}
then
  print_trace "Deploy SSH keys on ${consul_hostname}.."
  ssh-copy-id -i ~/.ssh/id_rsa.pub root@${consul_ip}
else 
  print_trace "SSH key on ${consul_hostname} already deployed."
fi

# Master
if ! ssh_key_already_exists ${swarm_master_ip}
then
  print_trace "Deploy SSH keys on ${swarm_master_hostname}.."
  ssh-copy-id -i ~/.ssh/id_rsa.pub root@${swarm_master_ip}
else 
  print_trace "SSH key on ${swarm_master_hostname} already deployed."
fi

# Agents
n=$(expr $nb_swarm_agents + 1)
for i in $(seq 2 $n)
do
  if ! ssh_key_already_exists ${swarm_agent_ip[$i]}
  then
    print_trace "Deploy SSH keys on ${swarm_agent_hostname}${i}.."
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@${swarm_agent_ip[$i]}
  else 
    print_trace "SSH key on ${swarm_agent_hostname}${i} already deployed."
  fi
done
