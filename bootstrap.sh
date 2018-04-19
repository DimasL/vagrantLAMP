#!/usr/bin/env bash

# size of swapfile in megabytes
swapsize=1024

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
	echo 'swapfile not found. Adding swapfile.'
	fallocate -l ${swapsize}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo '/swapfile none swap defaults 0 0' | sudo tee /etc/fstab
else
	echo 'swapfile found. No changes made.'
fi

# Initialize ENV variables
export DEBIAN_FRONTEND=noninteractive
export PHP_POST_MAX_SIZE=1000M
export PHP_UPLOAD_MAX_FILESIZE=1000M

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

# cleaning system from other installs
apt-get purge apache* samba* nginx* mysql* rabbitmq* php* -y
apt-get autoremove --purge -y

# Preparing server
sudo apt-get update &&
sudo apt-get -f install &&
sudo apt-get -y install nfs-common portmap &&
sudo apt-get install -y git curl nano software-properties-common python-software-properties  debconf-utils expect zip
sudo add-apt-repository ppa:ondrej/php
sudo apt update

sudo add-apt-repository universe
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

# Install PHP7.2
sudo apt -y install php7.2 php7.2-curl php7.2-gd php7.2-json php7.2-cgi php7.2-mbstring php7.2-xsl php7.2-dev libapache2-mod-php7.2 php7.2-fpm

# Install mcrypt
sudo apt-get -y install gcc make autoconf libc-dev pkg-config libmcrypt-dev
sudo pecl install mcrypt-1.0.1
echo 'extension=mcrypt.so' | sudo tee --append /etc/php/7.2/apache2/php.ini > /dev/null

#Install Apache2
sudo apt -y install apache2

#Install MySql
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
sudo apt -y install mysql-server php7.2-mysql
sudo mysql_secure_installation

# Restart Services
sudo systemctl restart apache2.service
sudo systemctl restart mysql.service

sudo apt-get -f install &&
sudo apt-get update &&

# Install other requirements
sudo apt-cache search php7* &&

# Install XDebug
wget http://xdebug.org/files/xdebug-2.6.0.tgz
tar -xzf xdebug-2.6.0.tgz
cd xdebug-2.6.0/
phpize
./configure --enable-xdebug
make
sudo cp modules/xdebug.so /usr/lib/php/20170718

#FOR FPM
echo 'zend_extension="/usr/lib/php/20170718/xdebug.so"' | sudo tee --append /etc/php/7.2/apache2/php.ini > /dev/null
sudo ln -s /etc/php/7.2/mods-available/xdebug.ini /etc/php/7.2/fpm/conf.d/20-xdebug.ini
echo 'xdebug.remote_enable=1
xdebug.default_enable=1
xdebug.cli_color=1
xdebug.remote_port=9000
xdebug.remote_host=10.0.2.2
xdebug.idekey=AAP_XDEBUG_KEY
xdebug.remote_connect_back=1
xdebug.remote_mode=req
xdebug.profiler_enable=1
xdebug.profiler_enable_trigger=1
' | sudo tee  --append /etc/php/7.2/fpm/conf.d/20-xdebug.ini > /dev/null

echo 'xdebug.remote_enable=1
xdebug.default_enable=1
xdebug.cli_color=1
xdebug.remote_port=9000
xdebug.remote_host=10.0.2.2
xdebug.idekey=AAP_XDEBUG_KEY
xdebug.remote_connect_back=1
xdebug.remote_mode=req
xdebug.profiler_enable=1
xdebug.profiler_enable_trigger=1
' | sudo tee  --append /etc/php/7.2/apache2/php.ini > /dev/null


#FOR CLI
sudo ln -s /etc/php/7.2/mods-available/xdebug.ini /etc/php/7.2/cli/conf.d/20-xdebug.ini

sudo service php7.2-fpm restart
sudo rm -rf xdebug-2.4.0rc2.tgz/ xdebug-2.4.0RC2/ package.xml

# Install phpunit
sudo wget https://phar.phpunit.de/phpunit.phar
sudo chmod +x phpunit.phar
sudo mv phpunit.phar /usr/local/bin/phpunit

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install the Symfony Installer
curl -LsS http://symfony.com/installer -o /usr/local/bin/symfony
sudo chmod a+x /usr/local/bin/symfony

sudo mkdir -p /var/www/logs
sudo mkdir -p /var/www/html
sudo chmod -R 0777 /var/www/logs /var/www/html

sudo curl -LsS http://codeception.com/codecept.phar -o /usr/local/bin/codecept
sudo chmod a+x /usr/local/bin/codecept

echo "<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/site/public
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        <Directory /var/www/html/site/public>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride All
            Order allow,deny
            allow from all
        </Directory>
</VirtualHost>" | sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null
sudo a2enmod rewrite

#Vsyakaya dich
sudo apt-get -y install imagemagick
sudo apt-get -y install php-imagick

service mysql restart
service php7.2-fpm restart
service apache2 restart

phpunit --version

mysql -uroot -ppassword
CREATE DATABASE databasename;
CREATE USER 'user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON databasename.* To 'user'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
exit;