#!/bin/bash -e

export LIBVIRT_DEFAULT_URI="qemu:///system"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" &> /dev/null && pwd )"
VAGRANT=$(basename $(readlink -f $SCRIPT_DIR))

vm_count=$(yq e -e .harvester_cluster_nodes $SCRIPT_DIR/settings.yml)
vm_name_prefix="harvester-node-"

# collect all vm names in the Vagrant env
nodes=()
for (( i=0; i<$vm_count; i++)); do
  nodes+=("${vm_name_prefix}${i}")
done

wait_domains_off()
{
  while [ true ]; do
    all_done="true"

    for node in ${nodes[@]}; do
      node_state=$(virsh dominfo --domain ${VAGRANT}_$node | grep '^State:' | awk '{print $2,$3}')

      if [ "$node_state" != "shut off" ]; then
        echo "waiting for $node, state is still $node_state."
        all_done="false"
        break
      fi
    done

    if [ "$all_done" = "true" ]; then
      echo All nodes are installed and off.
      break
    fi

    sleep 10
  done
}

wait_domains_off
