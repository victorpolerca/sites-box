#!/bin/bash

# Print text when running vagrant up.
echo "Starting VM..."

# Keep packages up to date.
# sudo apt-get update
# sudo apt-get upgrade -y

# Add extras not included w/scotchbox.
sudo apt-get install subversion openjdk-7-jre-headless dnsmasq php5-xdebug pkg-config cmake php-codesniffer phpunit libssh2-1-dev libssh2-php -y
sudo service apache2 restart

# Install PHP Compatibility standard for codesniffer if not already present.
if [ ! -d '/usr/share/php/PHP/CodeSniffer/Standards/PHPCompatibility-5.6' ]; then
  cd /usr/share/php/PHP/CodeSniffer/Standards/
  sudo mkdir PHPCompatibility-5.6
  sudo curl -Lo PHPCompatibility.zip https://github.com/wimg/PHPCompatibility/archive/5.6.zip
  sudo unzip PHPCompatibility.zip
  sudo rm PHPCompatibility.zip
  cd ~
fi

# Install Codeception if it isn't already here.
if ! type codecept > /dev/null; then
  sudo wget http://codeception.com/codecept.phar -O /usr/local/bin/codecept
  sudo chmod +x /usr/local/bin/codecept
fi

# Install RVM if it isn't already here.
# @see https://rvm.io/rvm/install
# if ! type rvm > /dev/null; then
#   gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
#   \curl -sSL https://get.rvm.io | bash -s stable --ruby
#   source /home/vagrant/.rvm/scripts/rvm
# fi

# Gems - update, install some not included w/scotchbox, RVM.
gem update
gem install compass net-sftp net-ssh
gem clean

# Add Composer to PATH.
export PATH="~/.composer/vendor/bin:$PATH"

# Setup dnsmasq for VM.
echo -e "address=/$3/$2" | sudo tee /etc/dnsmasq.d/$3
sudo /etc/init.d/dnsmasq restart

# Setup the files for level vhost (nothing to be shown there ATM).
# @TODO Get the ScotchBox index.php to serve from there.
sudo mkdir -p /var/www/public
sudo touch /var/www/public/index.html

# Convert the first arg var passed in (a comma-separated list of
# the domains provided to hostmanager) to an array of domains.
DOMAINS_STR=($1)
DOMAINS_ARR=(${DOMAINS_STR//,/ })

## Loop through all sites
for ((i=0; i < ${#DOMAINS_ARR[@]}; i++)); do

    ## Current Domain
    DOMAIN=${DOMAINS_ARR[$i]}

    echo "Creating directories for $DOMAIN..."
    mkdir -p /var/www/vhosts/$DOMAIN/public
    mkdir -p /var/www/vhosts/$DOMAIN/logs

    echo "Creating vhost config for $DOMAIN..."

    cat << VIRTUALHOSTCONF > /etc/apache2/sites-available/$DOMAIN.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  ServerName $DOMAIN
  ServerAlias *.$DOMAIN
  DocumentRoot /var/www/vhosts/$DOMAIN/public
  DirectoryIndex index.html index.php
  ErrorLog /var/www/vhosts/$DOMAIN/logs/error.log
  CustomLog /var/www/vhosts/$DOMAIN/logs/access.log combined
</VirtualHost>
VIRTUALHOSTCONF

    echo "Enabling $DOMAIN..."
    sudo a2ensite $DOMAIN.conf

done

echo "Added and enabled vhosts. Restarting Apache..."
sudo service apache2 restart
