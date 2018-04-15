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
	sudo cp /var/setup/fastcgi_params.conf /etc/nginx/fastcgi_params
	sudo cp /var/setup/nginx.conf /etc/nginx/nginx.conf
		sudo cp /var/setup/wp_nginx.conf /etc/nginx/sites-enabled/$site_uri.conf
		sudo sed -i "s,{site_dir},${site_dir},g" /etc/nginx/sites-enabled/$site_uri.conf
		sudo sed -i "s,{site_uri},${site_uri},g" /etc/nginx/sites-enabled/$site_uri.conf

	echo "... starting NGINX"
	sudo service nginx start

# PHP
	echo 'Setting up PHP'

	sudo apt-get -y install software-properties-common python-software-properties #not sure why this is needed
	sudo add-apt-repository ppa:ondrej/php -y
	echo "... apt-get update"
	sudo apt-get -qq update

	echo "... installing PHP"
	sudo apt-get install php7.1-fpm php7.1-common php7.1-mysqlnd php7.1-xmlrpc php7.1-curl php7.1-gd php7.1-imagick php7.1-cli php-pear php7.1-dev php7.1-imap php7.1-mcrypt -y 
	sudo service php7.1-fpm restart

#  MySQL
	echo 'Setting up MySQL'

	sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
	sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.sax.uk.as61049.net/mariadb/repo/10.1/ubuntu xenial main' -y
	echo "... apt-get update"
	sudo apt-get -qq update

	echo "... installing MySQL"
		# this stuff is required to get through the mariadb-server install noninteractively
		export DEBIAN_FRONTEND=noninteractive
		sudo debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password password $wp_sql_user_pass"
		sudo debconf-set-selections <<< "mariadb-server-5.5 mysql-server/root_password_again password $wp_sql_user_pass"
	sudo apt-get install mariadb-server -y

	sudo mysql_secure_installation <<-EOF
	$wp_sql_user_pass
	n
	y
	y
	y
	y
	EOF
	# EOF is used above to automate filling in the prompts

# WordPress
echo 'Setting up WordPress'

	echo '... setting up WP accounts'
	# www_wp is the WP server account while files_wp is the file system account
	sudo adduser www_wp --gecos "" --disabled-password
	echo "www_wp:$www_wp_password" | sudo chpasswd
	sudo chown -R www_wp:www-data $site_dir/
	sudo gpasswd -a www-data www_wp #this magically refreshes the permissions so that the above can take affect

	echo "... initializing MySQL for WP"
	mysql -u root -p --password=$wp_sql_user_pass -Bse "$(eval "echo \"$(cat /var/setup/mysql_setup.sql)\"")"

	echo "... downloading WP"
	sudo apt-get -y install curl
	curl -Os https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	sudo chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp

	echo "... initializing WP"
	sudo -u www_wp -i wp core download --path=$site_dir/public
	sudo -u www_wp -i wp core config --dbname=$site_url_safe --dbuser=wp_user --dbpass=$wp_sql_user_pass --path=$site_dir/public
	sudo -u www_wp -i wp core install --path=$site_dir/public --url=http://$site_uri --title=Default --admin_user=wp_admin --admin_email=wp_admin@$site_uri --admin_password=$wp_admin_password

	echo '... setting all permissions' # (must be done after WP is installed)	
	sudo chmod -R 664 $site_dir/ # files
	sudo find $site_dir/. -type d -exec chmod 775 {} \; # directories

	# Permit WP to work directly with file system rather than requiring FTP accounts:
	sudo sed -i '66i define('FS_METHOD', 'direct');' /www/local.wp1.me/public/wp-config.php

	echo "... restarting NGINX"
	sudo service nginx restart

# Redis & NGINX caching
echo 'Setting up Redis'
	sudo apt-get -y install redis-server
	sudo apt-get -y install php-redis
	
	# install and activate the WP redis plugin - note: the object caching will inevitably need to be manually turned on
	sudo -u www-data wp plugin install https://downloads.wordpress.org/plugin/redis-cache.1.3.5.zip --activate --path=$site_dir/public

	# setup NGINX caching in WP
	sudo -u www-data wp plugin install https://downloads.wordpress.org/plugin/nginx-cache.1.0.3.zip --activate --path=$site_dir/public

	sudo service redis-server restart
	sudo service php7.1-fpm restart

echo 'All done!'

