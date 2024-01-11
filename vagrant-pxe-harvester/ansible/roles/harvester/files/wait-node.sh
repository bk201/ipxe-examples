#!/bin/bash -eu

node_name=$1
expected_roles=$2

KUBECTL="kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml"

wait_node_ready() {
  local node=$1

  echo "Waiting for node $node to be ready..."
  retries=0
  while [ $retries -lt 180 ]; do

    ready="true"
    if ! $KUBECTL get node $node &>/dev/null; then
      echo "Can't find node $node"
      ready="false"
    else
      node_line=$($KUBECTL get node $node --no-headers=true)
      status=$(echo "$node_line" | awk '{print $2}')
      roles=$(echo "$node_line" | awk '{print $3}')

      if [ "$expected_roles" != "skip" -a "$expected_roles" != "$roles" ]; then
        echo "Expect node $node role to be $expected_roles, but get $roles."
        ready="false"
      elif [ "$status" != "Ready" ]; then
        echo "Expect node $node to be Ready, but get $status."
        ready="false"
      fi
    fi

    if [ "$ready" = "true" ]; then
      echo "Node $node is ready and has the roles: $expected_roles."
      return
    fi

    sleep 10
    retries=$((retries+1))
  done

  echo "Timeout!"
  $KUBECTL get nodes
  exit 1
}

wait_node_ready $node_name
