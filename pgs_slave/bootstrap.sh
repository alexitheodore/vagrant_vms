#!/usr/bin/env bash
#for Ubuntu trusty

#fix host resolution in hosts file
sudo sed -i '/127.0.0.1/c\127.0.0.1     localhost ubuntu-xenial' /etc/hosts
sudo sed -i '/127.0.1.1/c\#127.0.1.1    ubuntu-xenial ubuntu-xenial' /etc/hosts

sudo timedatectl set-timezone America/New_York

# INSTALL PGS:
	# download
	sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" | \
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
	sudo apt-key add -
	sudo apt-get update
	sudo apt-get install -y postgresql-9.6 postgresql-contrib-9.6 libpq-dev && \	

	sudo service postgresql stop
		sleep 5
	sudo mkdir /home/postgres
	sudo chown postgres:postgres /home/postgres
	sudo service postgresql start

	# main settings
	pg_pass=qwerasdfxcv
	master_ip=10.10.0.10
	slave_ip=10.10.0.20

	dir_postgresql=/var/lib/postgresql
	dir_postgresql_template=/vm_share
	dir_postgresql_data=$dir_postgresql/9.6/main
	synchronous_standby_names=pg_slave_1


	# setup pgpass file
	sudo su -c "echo \"$slave_ip:*:*:postgres:$pg_pass\" >> $dir_postgresql/.pgpass" postgres
	sudo su -c "chmod 600 $dir_postgresql/.pgpass" postgres
	sudo -u postgres psql --command="ALTER USER postgres WITH PASSWORD '$pg_pass';"
	sudo su -c "echo \"$master_ip:*:*:replica:$pg_pass\" >> $dir_postgresql/.pgpass" postgres
	sudo su -c "chmod 600 $dir_postgresql/.pgpass" postgres

	sudo service postgresql stop

	# firewall setup
	sudo ufw allow ssh
	sudo ufw allow postgresql
	echo 'y' | sudo ufw enable

	# Replication: Slave setup
		# using the template file, fill in the details and create the working copy
	sudo echo "$(eval "echo \"$(cat $dir_postgresql_template/postgresql.conf.template)\"")" > $dir_postgresql_template/postgresql.conf.filled
	sudo cp $dir_postgresql_template/postgresql.conf.filled $dir_postgresql_data/postgresql.conf
	sudo chown --reference=$dir_postgresql_data/postgresql.auto.conf $dir_postgresql_data/postgresql.conf
	sudo chmod --reference=$dir_postgresql_data/postgresql.auto.conf $dir_postgresql_data/postgresql.conf

	# sync data to master
	sudo rm -r $dir_postgresql/9.6/main # this assumes that any current data is trashable
	sudo -u postgres pg_basebackup -h $master_ip -U replica -D $dir_postgresql/9.6/main -P --xlog

	# sudo cp /vm_share/recovery_slave.conf $dir_postgresql/9.6/main/recovery.conf

		# using the template file, fill in the details and create the working copy
	sudo echo "$(eval "echo \"$(cat $dir_postgresql_template/recovery.conf.template)\"")" > $dir_postgresql_template/recovery.conf.filled
	sudo cp $dir_postgresql_template/recovery.conf.filled $dir_postgresql_data/recovery.conf
	sudo chmod 600 $dir_postgresql_data/recovery.conf
	sudo chown postgres:postgres $dir_postgresql_data/recovery.conf

	sudo service postgresql start