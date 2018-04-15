#!/usr/bin/env bash

echo "starting install script"

vagrant_success_log=/var/setup/vagrant_stty.log
source /var/setup/variables.conf


echo "... apt-get update"
sudo apt-get -qq update

# Infrastructure
	sudo mkdir -p $site_dir
	sudo mkdir -p $site_dir/logs
	sudo mkdir -p $site_dir/public

# NGINX
	echo 'Setting up NGINX'

	sudo apt-get -qq -y install nginx

	sudo rm /etc/nginx/sites-available/default
	sudo rm /etc/nginx/sites-enabled/default
	sudo cp /var/setup/nginx.conf /etc/nginx/nginx.conf
		sudo cp /var/setup/default_nginx.conf /etc/nginx/sites-enabled/$site_uri.conf
		sudo sed -i "s,{site_dir},${site_dir},g" /etc/nginx/sites-enabled/$site_uri.conf
		sudo sed -i "s,{site_uri},${site_uri},g" /etc/nginx/sites-enabled/$site_uri.conf

	echo "... starting NGINX"
	sudo service nginx start

echo 'All done!'
tput bel
