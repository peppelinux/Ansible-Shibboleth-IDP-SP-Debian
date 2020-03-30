````
# sp3.testunical.it
CNT=shibsp3
lxc-create  -t download -n $CNT -- -d debian -r buster -a amd64

echo '
lxc.aa_profile = unconfined

# lxc Network configuration example
# lxc.network.type = veth
# lxc.network.flags = up
# lxc.network.link = lxc-br0
# lxc.network.hwaddr = 00:FF:A1:01:03:09
lxc.network.name = eth0
lxc.network.ipv4 = 10.0.3.95/24 10.0.3.255
lxc.network.ipv4.gateway = 10.0.3.1
' >> /var/lib/lxc/$CNT/config

lxc-start $CNT
lxc-attach $CNT

apt update
apt install -y git python3-pip rsyslog
pip3 install ansible

cd /opt
git clone https://github.com/peppelinux/Ansible-Shibboleth-IDP-SP-Debian.git
cd Ansible-Shibboleth-IDP-SP-Debian

cp playbook.yml playbook.production.yml
# edit playbook.production.yml as your needs

# create https certs and copy to /etc/ssl/certs/{{ domain }}/{{ sp_fqdn }}
# make it readable by apache
CERT_DIR=/etc/ssl/certs/testunical.it
mkdir -p $CERT_DIR 
bash make_ca.production.sh
cp certs/* $CERT_DIR
chgrp -R apache $CERT_DIR

ansible-playbook -i "localhost," -c local playbook.production.yml -v --tag uninstall,sp,httpd_sp
````
