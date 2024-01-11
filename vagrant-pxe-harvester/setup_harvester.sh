#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

configure_keypair() {
    if [ -e $ROOTDIR/ci-key ]; then
        return
    fi

    ssh-keygen -b 2048 -t rsa -f $ROOTDIR/ci-key -q -N ""

    PUB_KEY=$(cat $ROOTDIR/ci-key.pub) \
        yq e -i ".harvester_config.ssh_authorized_keys += [ strenv(PUB_KEY) ]" $ROOTDIR/settings.yml
}

configure_keypair
pushd $ROOTDIR
ansible-playbook ansible/setup_harvester.yml --extra-vars "@settings.yml"
ANSIBLE_PLAYBOOK_RESULT=$?
popd
exit $ANSIBLE_PLAYBOOK_RESULT
