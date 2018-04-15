#!/usr/bin/env bash

slave_ip=10.10.0.20
source /vm_share/postgresql_slave.conf
echo "$(eval "echo \"$(cat /vm_share/postgresql_slave.conf)\"")" > /vm_share/postgresql_slave_filled.conf
