#!/usr/bin/env bash
#for Ubuntu trusty

#fix host resolution in hosts file due 16.04 build work around stuff. 
sudo sed -i '/127.0.0.1/c\127.0.0.1     localhost ubuntu-xenial' /etc/hosts
sudo sed -i '/127.0.1.1/c\#127.0.1.1    ubuntu-xenial ubuntu-xenial' /etc/hosts

sudo timedatectl set-timezone America/New_York

# INSTALL PGS:
	# I believe this is required to be able to properly apt-get postgres
	sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" | \
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
	sudo apt-key add -

	# download
	sudo apt-get update
	sudo apt-get install -y postgresql-9.6 postgresql-contrib-9.6 libpq-dev && \
	

	sudo service postgresql stop
		sleep 5
	sudo mkdir /home/postgres
	sudo chown postgres:postgres /home/postgres
	sudo service postgresql start

	# setup pgpass file(s)
	pg_pass=qwerasdfxcv

	sudo su -c "echo \"*:*:*:postgres:$pg_pass\" >> /var/lib/postgresql/.pgpass" postgres
	sudo su -c 'chmod 600 /var/lib/postgresql/.pgpass' postgres
	sudo -u postgres psql --command="ALTER USER postgres WITH PASSWORD '$pg_pass';"

	sudo service postgresql stop

	# firewall setup
	sudo ufw allow ssh
	sudo ufw allow postgresql
	echo 'y' | sudo ufw enable

	# Replication: Master setup

	sudo cp /vm_share/postgresql_master.conf /etc/postgresql/9.6/main/postgresql.conf
	sudo cp /vm_share/pg_hba_master.conf /etc/postgresql/9.6/main/pg_hba.conf

	sudo mkdir -p /var/lib/postgresql/9.6/main/archive/
	sudo chmod 700 /var/lib/postgresql/9.6/main/archive/
	sudo chown -R postgres:postgres /var/lib/postgresql/9.6/main/archive/

	sudo service postgresql start

	sudo -u postgres psql --command="CREATE USER replica REPLICATION LOGIN ENCRYPTED PASSWORD '$pg_pass';"

	
