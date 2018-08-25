#!/usr/bin/env bash

CHEF_VERSION='12.17.33-1'
CHEF_PACKAGE="chef-server-core_${CHEF_VERSION}_amd64.deb"
PASSWORD='kindlychangethis'
DLF='/home/vagrant/dl/'

apt-get update -y -qq > /dev/null
apt-get upgrade -y -qq > /dev/null
apt-get -y -q install linux-headers-$(uname -r) build-essential > /dev/null

if [ ! -d /home/vagrant/dl ]; then
  mkdir /home/vagrant/dl
fi

if [ ! -f ${DLF}${CHEF_PACKAGE} ]; then
  wget -P ${DLF} https://packages.chef.io/stable/ubuntu/16.04/${CHEF_PACKAGE} > /dev/null
fi

if [ ! $(which chef-server-ctl) ]; then

  dpkg -i ${DLF}${CHEF_PACKAGE}

  chown -R vagrant:vagrant /home/vagrant
  mkdir /home/vagrant/certs
fi

chef-server-ctl reconfigure

echo "Waiting for services..."
until (curl -D - http://localhost:8000/_status) | grep "200 OK"; do sleep 15s; done
while (curl http://localhost:8000/_status) | grep "fail"; do sleep 15s; done

echo "Create example user and org"
chef-server-ctl user-create chefadmin Chef Admin admin@exemplum.local ${PASSWORD} --filename /home/vagrant/chefadmin.pem
chef-server-ctl org-create exemplum "Exemplum Furniture, Inc." --association_user chefadmin --filename /home/vagrant/exemplum-validator.pem


# configure hosts file for our internal network defined by Vagrantfile
#cat >> /etc/hosts <<EOL
# vagrant environment nodes
#10.0.15.10  chef-server
#10.0.15.15  lb
#10.0.15.22  web1
#10.0.15.23  web2
#EOL

echo "Chef Console is ready: http://chef-server with login: testlabdev password: ${PASSWORD}"


